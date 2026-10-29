# Discovering Commands and Scripting obcmd

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Dump the whole surface](#step-1--dump-the-whole-surface)
- [Step 2 — Narrow to one resource or command](#step-2--narrow-to-one-resource-or-command)
- [Step 3 — Preview a mutation before sending it](#step-3--preview-a-mutation-before-sending-it)
- [Step 4 — Branch on exit codes, not on prose](#step-4--branch-on-exit-codes-not-on-prose)
- [Step 5 — Trim the response](#step-5--trim-the-response)
- [Step 6 — Add filters the flags do not cover](#step-6--add-filters-the-flags-do-not-cover)
- [Step 7 — Stream every page](#step-7--stream-every-page)
- [Step 8 — Send a raw API body](#step-8--send-a-raw-api-body)
- [Global flags](#global-flags)
- [See also](#see-also)

---

## Overview

`obcmd` is built to be driven by scripts and agents as well as people. The
command surface describes itself, every mutating command can be previewed,
errors are machine-readable on stderr, and exit codes distinguish the cases a
caller needs to act on differently.

Grammar is fixed: `obcmd <resource> <verb> [flags]`.

---

## When to use this

- Writing a script or agent against `obcmd` and wanting the schema up front
- Checking whether a capability exists before guessing a flag name
- Testing a destructive change safely
- Deciding whether to retry, re-authenticate or stop after a failure

---

## Prerequisites

- `obcmd` installed; see [Authenticating](authenticating.md) for credentials.
  `describe` works without credentials.

---

## Step 1 — Dump the whole surface

```bash
obcmd describe --json > obcmd-tree.json
```

One call returns every resource, verb, flag, type, enum, path, HTTP method and
response shape. No round trips and no scraping of help text.

```bash
# Every command name
jq -r '.resources[].commands[] | "\(.resource) \(.verb)"' obcmd-tree.json

# Only mutating commands
jq -r '.resources[].commands[] | select(.mutating) | "\(.resource) \(.verb)"' obcmd-tree.json

# Which commands require confirmation
jq -r '.resources[].commands[] | select(.destructive_when) | .resource' obcmd-tree.json
```

---

## Step 2 — Narrow to one resource or command

```bash
obcmd                                   # root help, or JSON when piped
obcmd subscription                      # verbs available on a resource
obcmd subscription describe --json      # full schema for one resource
obcmd subscription create --help --json # machine-readable help for one command
```

`describe` is reserved: no resource can define it as a verb, so these forms
always report schema rather than calling an endpoint.

---

## Step 3 — Preview a mutation before sending it

Every mutating command accepts `--dry-run`. It resolves credentials, validates
flags, and prints the request it would send without sending it.

```bash
obcmd subscription update --subscription_id 116223 --status paused --dry-run
```

Destructive commands additionally require `--yes`:

```bash
obcmd subscription update --subscription_id 116223 --status invalid          # refused
obcmd subscription update --subscription_id 116223 --status invalid --yes    # proceeds
```

The guard follows the resolved status rather than the verb, so
`--status cancelled` and `--status invalid` both need `--yes` even on
`subscription update`. `describe --json` reports this as `destructive_when`, so
a caller can see it before invoking.

---

## Step 4 — Branch on exit codes, not on prose

| Code | Meaning | What to do |
|---|---|---|
| `0` | Success | — |
| `1` | Failure (API, network, internal) | Check `retryable` in the error body |
| `2` | Usage error | Fix the flags; the error names them |
| `3` | Not found | Create it, or check the ID |
| `4` | Permission denied / not authenticated | Re-authenticate; stop retrying |
| `5` | Conflict | Read current state first |

```bash
obcmd subscription get --subscription_id "$ID" --json > sub.json
case $? in
  0) echo "exists" ;;
  3) echo "missing; creating" ;;
  4) echo "re-authenticate"; exit 1 ;;
  5) echo "conflict; re-reading state" ;;
esac
```

Errors are JSON on stderr. Branch on `error`, which is a stable snake_case
code, not on `message`, which may change between versions.

```json
{
  "error": "missing_required_flags",
  "message": "Missing required flag: --subscription_id",
  "suggestions": ["obcmd subscription get --subscription_id <value>"],
  "failing_input": { "missing_flags": ["subscription_id"] },
  "retryable": false,
  "retry_after_seconds": null,
  "http_status": null
}
```

stdout carries data and nothing else, in every mode. `obcmd product list | jq`
receives either parseable JSON or nothing — never an error message it has to
distinguish from a result.

---

## Step 5 — Trim the response

```bash
obcmd subscription list --fields id,name,status
obcmd subscription get --subscription_id 116223 --fields '*'      # everything
obcmd product-card get --product_id 95 --fields 'id,stages.name'  # nested
```

`--fields` is a caller-side mask. It chooses columns for the human table and
narrows `--json`; it never changes what the API returned. Without it, `--json`
emits every field the API sent, in the types it sent them.

---

## Step 6 — Add filters the flags do not cover

`--filter` passes an API-native query parameter straight through, and is
repeatable.

```bash
obcmd healthcheck list --account_id 12345 \
  --filter modified_at__gte=2026-01-01 \
  --filter modified_at__lte=2026-02-01
```

Django-style lookups work where the API supports them: `__gte`, `__lte`,
`__contains`, `__icontains`, `__exact`.

---

## Step 7 — Stream every page

```bash
obcmd job list --subscription_ids 116223 --all | jq -c 'select(.status != "processed")'
```

`--all` follows every page and streams NDJSON — one object per line — so a large
result set never has to fit in memory. Progress goes to stderr; only records
reach stdout.

Two endpoints paginate by cursor rather than page: `transaction list` (use
`--cursor`, or `--all`) and `facebook-ad-account list` (use `--next`).

---

## Step 8 — Send a raw API body

When the convenience flags do not cover a field, supply the JSON:API body
yourself. `--payload` accepts inline JSON, `@file`, or `-` for stdin.

```bash
echo '{"data":{"type":"Subscription","attributes":{"status":"paused"}}}' \
  | obcmd subscription update --subscription_id 116223 --payload -
```

---

## Global flags

| Flag | Description |
|---|---|
| `--json` | Force JSON output regardless of TTY detection |
| `--output` | `json` or `text`; overrides `--json` |
| `--fields` | Comma-separated field mask; dot notation for nested keys; `*` for all |
| `--all` | Auto-paginate and stream every page as NDJSON. List commands only |
| `--dry-run` | Resolve and preview the request without sending it. Mutating commands only |
| `--yes` | Skip the confirmation guard on destructive commands |
| `--payload` | Raw API-shaped JSON body: inline, `@file`, or `-` |
| `--filter` | Additional API-native query filter as `key=value`. Repeatable |
| `--color` | Colorize human output; negate with `--no-color` |
| `--help` | Help for the command; combine with `--json` |
| `--version` | Print the obcmd version |

---

## See also

- [Output and exit codes](../output-and-exit-codes.md) — response shape, retries, rate limiting
- [Command Reference](../commands.md) — generated flag-by-flag reference
- `AGENT_GUIDE.md` — invariants for automated callers
