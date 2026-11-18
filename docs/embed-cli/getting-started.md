# Getting Started

## Requirements

- Node.js 20 or newer
- An Openbridge account with a refresh token

## Install

```bash
npm install -g @openbridge-inc/obcmd
obcmd --version
```

To run from a checkout instead:

```bash
npm install
npm run build
node dist/index.js --version
```

## Get a refresh token

Refresh tokens are created in the Openbridge UI and cannot be created through
the API.

1. Sign in to Openbridge.
2. Go to **Account → API Management**.
3. Click **Create Refresh Token**, give it a name, and click **Create**.
4. Copy the token immediately. It is shown once and cannot be retrieved again.

## Authenticate

The refresh token is read from the environment. It is never accepted as a
command-line flag, because arguments are visible to every user on the machine
through `ps` and are captured by shell history and CI logs.

```bash
export OBCMD_REFRESH_TOKEN="ory_at_..."
obcmd auth login
```

`auth login` verifies the token and caches a short-lived access token in
`~/.config/obcmd/token.json` (mode `0600`). The refresh token itself is never
written to disk.

Check state at any time:

```bash
obcmd auth status
```

Keep the export out of your shell history — put it in a profile file that is not
world-readable, or use a secret manager:

```bash
export OBCMD_REFRESH_TOKEN="$(op read op://vault/openbridge/refresh_token)"
```

## Your first commands

Find your account and user IDs, which most other calls need:

```bash
obcmd account get
obcmd user get
```

Save them so you can stop passing them:

```bash
obcmd config update --account_id <account_id> --user_id <user_id>
```

Then look around:

```bash
obcmd product list --is_storage_product 0     # source products
obcmd storage list                            # destinations
obcmd remote-identity-shared list --invalid_identity 0
obcmd subscription list --status active
```

## Preview before you change anything

Every mutating command accepts `--dry-run`, which resolves and prints the exact
request without sending it. It needs no credentials, so it is safe to explore
with:

```bash
obcmd subscription create \
  --account <account_id> --user <user_id> --product 79 \
  --status active --date_start 2026-01-01T00:00:00Z \
  --storage_group <storage_group_id> --remote_identity <remote_identity_id> \
  --product_parameters '{"stage_ids":"[1000]"}' \
  --dry-run
```

## Next

- [Authentication](authentication.md) — token lifetimes, build modes
- [Recipes](recipes.md) — complete worked flows
- [Command reference](commands.md) — every flag
