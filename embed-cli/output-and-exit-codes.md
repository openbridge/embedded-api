# Output and Exit Codes

## Two streams, strictly

- **stdout** carries data and nothing else.
- **stderr** carries errors, warnings and progress.

This holds in every mode, including `--json`. A consumer running
`obcmd product list | jq` receives either parseable JSON or nothing at all —
never an error message it has to distinguish from a result.

## Output mode

| Situation | Output |
|---|---|
| Piped or redirected | JSON |
| At a terminal | Human-readable table |
| `--json` | JSON, always |
| `--output text` | Table, even when piped |

Auto-detection means piping just works with no flags. The explicit flags exist
for when you want the other one.

```bash
obcmd product list                    # table
obcmd product list | jq '.[].name'    # JSON, no flag needed
obcmd product list --json             # JSON at a terminal
obcmd product list --output text | less   # table into a pager
```

## Response shape

Openbridge returns JSON:API. `obcmd` flattens it:

```jsonc
// API returns
{ "data": { "type": "Product", "id": "50",
            "attributes": { "name": "Amazon Attribution", "active": 1 },
            "relationships": { "remote_identity_type": { "data": { "id": "14" } } } } }

// obcmd emits
{ "id": "50", "name": "Amazon Attribution", "active": 1, "remote_identity_type_id": "14" }
```

Guarantees you can rely on:

- Optional fields are **present as `null`**, never omitted.
- Empty collections are `[]`, never `null`.
- Relationship IDs are lifted to `<name>_id`.
- A `list` verb always returns an array, even for one result. A `get` always
  returns an object. The shape follows the verb, not the result count.

## Field masks

Trim the response to what you need:

```bash
obcmd subscription list --fields id,name,status
obcmd subscription get --subscription_id <subscription_id> --fields '*'   # everything
obcmd product-card get --product_id 95 --fields 'id,stages.name'  # nested
```

Every read command accepts `--fields`. Dot notation reaches into nested objects.

## Pagination

List commands are page-based by default. `--all` follows every page and streams
NDJSON — one JSON object per line — so a large result set never has to fit in
memory:

```bash
obcmd job list --subscription_ids <subscription_ids> --all | jq -c 'select(.status=="failed")'
```

Progress goes to stderr; only records reach stdout.

> The Facebook integration endpoints are cursor-paginated rather than
> page-paginated. Pass the cursor explicitly with `--next`.

## Exit codes

| Code | Meaning | What to do |
|---|---|---|
| `0` | Success | — |
| `1` | Failure (API, network, internal) | Check `retryable` in the error body |
| `2` | Usage error | Fix the flags; the error names them |
| `3` | Not found | Create it, or check the ID |
| `4` | Permission denied / not authenticated | Re-authenticate; stop retrying |
| `5` | Conflict | Read current state first |

`1` does **not** mean "retryable". Retryability is an explicit field in the
error body, because a deterministic bug and a transient network blip both land
on `1` and retrying only helps one of them.

## What is retried, and what is not

Reads are replayed on `5xx` and on network failures. Writes are not: a `POST` or
`PATCH` whose response is lost may already have committed, and replaying it
would create the record twice. Those come back as `outcome_unknown` with
`retryable: false`, and the right response is to read current state rather than
resend.

A `429` is retried for every method, read or write, because the API is stating
it did not process the request.

## Error shape

Errors are JSON on stderr, always paired with a non-zero exit code:

```json
{
  "error": "missing_required_flags",
  "message": "Missing required flag: --subscription_id",
  "suggestions": [
    "obcmd subscription get --subscription_id <value>",
    "obcmd subscription get --help --json"
  ],
  "failing_input": { "missing_flags": ["subscription_id"] },
  "retryable": false,
  "retry_after_seconds": null,
  "http_status": null
}
```

| Field | Use |
|---|---|
| `error` | Stable snake_case code. Branch on this, not on `message`. |
| `message` | Human-readable. May change between versions. |
| `suggestions` | Ordered, runnable next steps. |
| `failing_input` | Exactly what was rejected. |
| `retryable` | Whether retrying can possibly succeed. |
| `retry_after_seconds` | Populated on 429 and when the API says so. |
| `http_status` | Underlying status, or `null` for local errors. |

## Rate limiting

Openbridge allows 1,000 requests per 5 minutes per IP across all APIs. On `429`
the CLI waits the `Retry-After` value, then backs off exponentially to a
five-minute ceiling with 10–20% jitter, for up to `OBCMD_MAX_RETRIES` attempts.
Retries are announced on stderr. Other `4xx` responses are never retried —
retrying a `400` or `404` cannot resolve it.

## Streams and safety

String values from the API have ANSI escapes and control characters stripped
before emission. In a partial NDJSON stream that fails midway, valid lines have
already been written to stdout; the exit code is still non-zero and the error is
still on stderr. Trust the exit code and treat partial output as partial.
