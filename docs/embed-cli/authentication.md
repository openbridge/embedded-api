# Authentication

## The two tokens

Openbridge uses two tokens and it matters which is which.

| Token | Lifetime | Where it comes from | What it is for |
|---|---|---|---|
| Refresh token | Long-lived | Created once in the Openbridge UI | Exchanged for access tokens |
| Access token | Short-lived JWT | Returned by the Authentication API | Sent as `Authorization: Bearer` on every call |

`obcmd` handles the exchange. You supply the refresh token through the
environment; the CLI obtains access tokens as needed and caches them in
`~/.config/obcmd/token.json`.

The refresh token is **only** read from `OBCMD_REFRESH_TOKEN`. There is no flag
for it and it is never written to disk. Command-line arguments appear in `ps`
output for every user on the machine, in shell history, and in CI logs; a
long-lived bearer credential does not belong in any of those.

## Why caching matters

The Authentication API is rate-limited like every other Openbridge API — 1,000
requests per 5 minutes, per IP, shared across all APIs. Exchanging the refresh
token on every invocation would spend that budget on authentication instead of
work. `obcmd` reuses a cached access token until 60 seconds before it expires.

You do not need to manage this, but it explains why the first command after
`auth login` is slower than the rest.

## Commands

```bash
export OBCMD_REFRESH_TOKEN=<token>
obcmd auth login       # verify the token and cache an access token
obcmd auth status      # what is configured, when it expires
obcmd auth token get   # print a currently-valid access token
obcmd auth logout      # delete the cached access token
```

`auth logout` clears the cached access token. The refresh token lives in your
environment, so `unset OBCMD_REFRESH_TOKEN` to fully sign out.

## The cache belongs to one credential

`token.json` records a fingerprint — a truncated SHA-256, not the secret — of
the refresh token that filled it. A cached access token is reused only when that
fingerprint matches the refresh token configured now.

Without that binding, changing `OBCMD_REFRESH_TOKEN` kept using the previous
account's access token until it expired, with no network call to reveal it. On a
CI runner where jobs share a home directory, that is one job acting as another's
principal. Caches written before the binding existed carry no fingerprint and
are discarded rather than trusted.

`auth token get` exists so you can drive `curl` or another client with the same
credentials:

```bash
TOKEN=$(obcmd auth token get --json | jq -r .token)
curl -H "Authorization: Bearer $TOKEN" https://account.api.openbridge.io/account
```

## Configuration precedence

Highest wins:

1. Command-line flag
2. Environment variable
3. `~/.config/obcmd/config.json`
4. Built-in default

| Variable | Effect |
|---|---|
| `OBCMD_REFRESH_TOKEN` | Refresh token. **Required.** The only way to supply it |
| `OBCMD_ACCOUNT_ID` | Default `--account_id` |
| `OBCMD_USER_ID` | Default `--user_id` |
| `OBCMD_TIMEOUT_MS` | Per-request timeout, default 30000 |
| `OBCMD_MAX_RETRIES` | Retry budget, default 5 |
| `OBCMD_DEBUG` | `1` prints stack traces to stderr |

## File permissions

`config.json` and `token.json` are written with mode `0600` inside a `0700`
directory. Neither contains the refresh token — `config.json` holds only your
default account and user IDs, and `token.json` holds a short-lived access token.

The cached access token is still a bearer credential until it expires. Treat
`~/.config/obcmd/` as sensitive, and run `obcmd auth logout` on a shared
machine.

## When credentials go bad

| Symptom | Meaning | Fix |
|---|---|---|
| Exit `4`, `not_authenticated` | `OBCMD_REFRESH_TOKEN` is not set | `export OBCMD_REFRESH_TOKEN=<token>` |
| Exit `4`, `http_401` | Refresh token revoked or expired | Create a new token in the UI, log in again |
| Exit `4`, `http_403` | Token is valid but lacks access to that account | Check `obcmd account get` matches the ID you passed |

Third-party identities expire separately from your Openbridge credentials. Poll
for revoked ones:

```bash
obcmd remote-identity-shared list --invalid_identity 1
```

Openbridge checks identities on active subscriptions every 24 hours, but if you
resell Openbridge, detection and customer notification are your responsibility —
Openbridge has no channel to your customers.
