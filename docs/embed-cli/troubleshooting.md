# Troubleshooting

Look up the `error` code from the JSON on stderr.

## Authentication

| `error` | Exit | Cause | Fix |
|---|---|---|---|
| `not_authenticated` | 4 | No refresh token configured | `obcmd auth login   # reads OBCMD_REFRESH_TOKEN` |
| `auth_no_token` | 1 | Auth API accepted the call but returned no token | The refresh token was revoked; create a new one in the UI |
| `http_401` | 4 | Access token rejected | `obcmd auth logout` then log in again |
| `http_403` | 4 | Valid token, wrong account | Confirm `obcmd account get` matches the `--account_id` you passed |

Healthcheck requests are validated against the account in your token. Requesting
another account's healthchecks returns 403 and always will.

## Usage

| `error` | Exit | Fix |
|---|---|---|
| `missing_required_flags` | 2 | The message names them; `--help --json` lists all |
| `unknown_flags` | 2 | Typo, or the flag belongs to a different command |
| `unknown_resource` / `unknown_verb` | 2 | `obcmd describe --json` lists everything |
| `invalid_identifier` | 2 | You passed a URL or a path where a bare ID belongs |
| `invalid_integer` / `invalid_date` / `invalid_enum` | 2 | Wrong format; the message states the expected one |
| `invalid_filter` | 2 | `--filter` must be `key=value` |
| `invalid_payload_json` | 2 | `--payload` is not valid JSON |
| `confirmation_required` | 2 | Destructive command; add `--yes`, or preview with `--dry-run` |
| `credential_in_argv` | 2 | `--refresh-token` was removed; `export OBCMD_REFRESH_TOKEN=<token>` instead |
| `invalid_boolean` | 2 | `--yes` takes no value, or exactly `true`/`false`. `--yes=no` is rejected rather than read as consent |

`obcmd` never prompts. A missing value is an error you can correct, not a
blocking question — a prompt an automated caller cannot see would hang the whole
task instead of failing usefully.

## API and network

| `error` | Exit | Meaning |
|---|---|---|
| `http_400` | 2 | The API rejected the body. `failing_input` shows what was sent |
| `http_404` | 3 | No such record, or it is not visible to your account |
| `http_409` | 5 | Already exists. Read current state before retrying |
| `http_429` | 1 | Rate limited. Already retried; `retry_after_seconds` says how long to wait |
| `request_timeout` | 1 | Raise it: `OBCMD_TIMEOUT_MS=60000` |
| `network_error` | 1 | Connectivity. `retryable` is true |
| `retries_exhausted` | 1 | Budget spent. Raise with `OBCMD_MAX_RETRIES=10` |
| `outcome_unknown` | 1 | A write did not complete and was not retried. It may already have been applied — read current state before resending |
| `unsafe_pagination_link` | 1 | The API returned a `next` link outside its own origin. It was not followed. Page manually with `--page` |
| `pagination_cycle` | 1 | `--all` was returned a `next` link pointing at a page already fetched. Refused rather than looping forever |

## Specific situations

**A subscription stopped producing data.** Almost always a revoked third-party
credential:

```bash
obcmd remote-identity-shared list --invalid_identity 1
obcmd healthcheck list --account_id <id> --status ERROR --order_by=-modified_at
```

The affected user must re-authorize through the Openbridge UI.

**`subscription create` returns 400 about the product.** Creation against an
inactive product is rejected, as is reactivating a subscription whose product
has since gone inactive. Check with `obcmd product get --product_id <id>`.

**Remote identity conflict.** The identity may be supplied as
`--remote_identity`, as `remote_identity_id`, or inside `--product_parameters`.
Supplying more than one is allowed only if they agree. Use `--remote_identity`
alone.

**`subscription-parameter get` returns 404 for a list of IDs.** The bulk endpoint
is all-or-nothing. One missing or inaccessible ID fails the whole request; the
error detail lists every unresolved ID.

**Rules queries return nothing.** The Rules API environment segment is `prod`,
not `production`. `obcmd` defaults correctly; if you overrode
`--rules_environment`, that is why.

**A `--filter` seems to be ignored.** Unknown *flags* are rejected, but
`--filter` values are passed to the API verbatim. A filter the API does not
recognize is silently dropped server-side. Check the spelling of the lookup
suffix.

## Debugging

```bash
OBCMD_DEBUG=1 obcmd <command>            # stack traces to stderr
obcmd <command> --dry-run --json         # exact URL and body, nothing sent
obcmd auth status                        # what credentials are in play
obcmd config get                         # resolved configuration
```

`--dry-run` is the fastest way to see what a command would actually do. It needs
no credentials and never contacts the API.
