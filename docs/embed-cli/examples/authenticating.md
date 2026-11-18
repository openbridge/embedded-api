# Authenticating and Setting Defaults

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Supply the refresh token](#step-1--supply-the-refresh-token)
- [Step 2 — Log in](#step-2--log-in)
- [Step 3 — Confirm what is configured](#step-3--confirm-what-is-configured)
- [Step 4 — Find your account and user IDs](#step-4--find-your-account-and-user-ids)
- [Step 5 — Store them as defaults](#step-5--store-them-as-defaults)
- [Step 6 — Drive another client with the same credentials](#step-6--drive-another-client-with-the-same-credentials)
- [Step 7 — Log out](#step-7--log-out)
- [Environment variables](#environment-variables)
- [When credentials go bad](#when-credentials-go-bad)
- [See also](#see-also)

---

## Overview

Openbridge uses two tokens. A long-lived **refresh token**, created once in the
Openbridge UI, is exchanged for short-lived **access tokens** that are sent as
`Authorization: Bearer` on every call. `obcmd` performs the exchange for you and
caches the access token in `~/.config/obcmd/token.json` until 60 seconds before
it expires.

Almost every call also needs an account ID and a user ID. Rather than passing
them on every invocation, store them once in `~/.config/obcmd/config.json`.

---

## When to use this

- First run on a new machine or a new CI runner
- After rotating a refresh token
- When a command exits `4` with `not_authenticated`, `http_401` or `http_403`
- When switching between accounts your token authorizes

---

## Prerequisites

- A refresh token from the Openbridge UI
- `obcmd` installed and on your `PATH`

---

## Step 1 — Supply the refresh token

The refresh token is read from `OBCMD_REFRESH_TOKEN` and nowhere else.

```bash
export OBCMD_REFRESH_TOKEN=<refresh_token>
```

There is no `--refresh-token` flag, and the value is never written to disk.
Command-line arguments appear in `ps` output for every user on the machine, in
shell history, and in CI logs; a long-lived bearer credential belongs in none of
those. Passing the removed flag is rejected with `credential_in_argv` rather
than ignored:

```bash
obcmd auth login --refresh-token abc123
# exit 2 — credential_in_argv; the value is not echoed back
```

---

## Step 2 — Log in

```bash
obcmd auth login
```

This verifies the refresh token and caches an access token. The first command
after login is slower than the rest because it performs the exchange.

---

## Step 3 — Confirm what is configured

```bash
obcmd auth status
obcmd config get
```

`config get` reports the stored defaults, the config file path, and whether a
refresh token is configured — never the token itself.

```json
{
  "account_id": 12345,
  "user_id": 67890,
  "timeout_ms": 30000,
  "max_retries": 5,
  "refresh_token_configured": true,
  "config_path": "/Users/you/.config/obcmd/config.json"
}
```

---

## Step 4 — Find your account and user IDs

```bash
obcmd account get --fields id
obcmd user get --fields id
```

| Command | Returns | Needed for |
|---|---|---|
| `account get` | The account record for the token | `--account` on `subscription create`, `--account_id` on `healthcheck list` |
| `user get` | The user record for the token | `--user` on `subscription create`, `--user_id` on `state create` |

Both are read-only and take no arguments — they describe the authenticated
token. There is no profile edit, email change or team listing in the CLI.

---

## Step 5 — Store them as defaults

```bash
obcmd config update --account_id 12345 --user_id 67890
```

Stored values are injected into commands that accept them, so you can stop
passing the flags. At least one of `--account_id` or `--user_id` is required;
`--dry-run` previews the change without writing the file.

```bash
obcmd config update --account_id 12345 --dry-run
```

Switching the stored account only works for accounts your refresh token already
authorizes. Requesting another account's records returns `403`. This is not the
console's organization switcher or proxy-masquerade.

---

## Step 6 — Drive another client with the same credentials

```bash
TOKEN=$(obcmd auth token get --json | jq -r .token)
curl -H "Authorization: Bearer $TOKEN" https://account.api.openbridge.io/account
```

`auth token get` prints a currently-valid access token, refreshing first if the
cached one is near expiry.

---

## Step 7 — Log out

```bash
obcmd auth logout        # deletes the cached access token
unset OBCMD_REFRESH_TOKEN
```

`auth logout` clears `~/.config/obcmd/token.json`. The refresh token lives in
your environment, so unsetting it is the second half of signing out. This is the
CLI's equivalent of the console's "clear local cache".

---

## Environment variables

Precedence, highest first: command-line flag, environment variable,
`~/.config/obcmd/config.json`, built-in default.

| Variable | Effect |
|---|---|
| `OBCMD_REFRESH_TOKEN` | Refresh token. **Required.** The only way to supply it |
| `OBCMD_ACCOUNT_ID` | Default `--account_id` |
| `OBCMD_USER_ID` | Default `--user_id` |
| `OBCMD_TIMEOUT_MS` | Per-request timeout, default 30000 |
| `OBCMD_MAX_RETRIES` | Retry budget, default 5 |
| `OBCMD_DEBUG` | `1` prints stack traces to stderr |

---

## When credentials go bad

| Symptom | Meaning | Fix |
|---|---|---|
| Exit `4`, `not_authenticated` | `OBCMD_REFRESH_TOKEN` is not set | `export OBCMD_REFRESH_TOKEN=<token>` |
| Exit `4`, `http_401` | Refresh token revoked or expired | Create a new token in the UI, then `obcmd auth login` |
| Exit `4`, `http_403` | Token is valid but lacks access to that account | Check `obcmd account get` matches the ID you passed |

Third-party identities expire separately from your Openbridge credentials:

```bash
obcmd remote-identity-shared list --invalid_identity 1
```

---

## See also

- [Authentication](../authentication.md) — token model and cache behaviour
- [Inspecting identities](inspecting-identities.md) — revoked third-party credentials
- [Discovering commands](discovering-commands.md) — exit-code branching
