# Authorizing a Third-Party Identity

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Find the identity type](#step-1--find-the-identity-type)
- [Step 2 — Register your own OAuth app, if the provider needs one](#step-2--register-your-own-oauth-app-if-the-provider-needs-one)
- [Step 3 — Create the state record](#step-3--create-the-state-record)
- [Step 4 — Send the browser through the authorize URL](#step-4--send-the-browser-through-the-authorize-url)
- [Step 5 — Confirm the identity exists](#step-5--confirm-the-identity-exists)
- [Re-authorizing a revoked identity](#re-authorizing-a-revoked-identity)
- [Managing OAuth app records](#managing-oauth-app-records)
- [Managing state records](#managing-state-records)
- [Non-OAuth flows](#non-oauth-flows)
- [What the CLI cannot do here](#what-the-cli-cannot-do-here)
- [See also](#see-also)

---

## Overview

Creating a remote identity requires a human at a browser: the third-party
platform shows its own consent screen, and no API can click it. The CLI handles
both ends of that flow — registering the OAuth app, minting the state record
that carries your context through the redirect, and reading the result back.

---

## When to use this

- Connecting a new Amazon, Google, Facebook, Shopify, Snowflake or BigQuery
  account to Openbridge
- Re-authorizing an identity whose credentials were revoked
- Using your own OAuth client rather than Openbridge's

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- Your user ID: `obcmd user get --fields id`
- A `return_url` your browser can reach after consent
- For Snowflake and Shopify: your own OAuth client ID and secret

---

## Step 1 — Find the identity type

```bash
obcmd identity-type list --name_contains snowflake
obcmd identity-type list --fields id,name,auth_service
```

The `id` is the `remote_identity_type_id` the rest of the flow needs. If you are
authorizing an identity for a specific product, read the requirement off the
product instead:

```bash
obcmd product get --product_id 50 --fields remote_identity_type_id
```

---

## Step 2 — Register your own OAuth app, if the provider needs one

Snowflake and Shopify require an OAuth app record of your own. Others do not.

```bash
obcmd oauth-app create --remote_identity_type 19 \
  --account 12345 --user 67890 \
  --client_id "$CLIENT_ID" --client_secret "$CLIENT_SECRET" \
  --extra_params '{"account_authorization_url":"https://acct.snowflakecomputing.com"}'
```

| Flag | Required | Notes |
|---|---|---|
| `--remote_identity_type` | yes | Type this app applies to |
| `--account`, `--user` | yes | From `account get` and `user get` |
| `--client_id` | yes | Provider's client ID |
| `--client_secret` | yes | Write-only; never returned |
| `--name` | no | Auto-generated from type and client_id |
| `--extra_params` | no | JSON-encoded provider extras: `account_authorization_url` for Snowflake, `shop_url` for Shopify |

`create` is upsert-shaped: an existing record with the same account and
`client_id` is updated and returns `200` rather than `201`.

Keep the secret out of argv where you can — read it from the environment, as
above, rather than pasting the literal value into a shell that records history.

---

## Step 3 — Create the state record

```bash
obcmd state create \
  --remote_identity_type_id 19 \
  --user_id 67890 \
  --region global \
  --return_url https://yourapp.example/oauth/complete \
  --oauth_id 42
```

| Flag | Required | Notes |
|---|---|---|
| `--remote_identity_type_id` | yes | From step 1 |
| `--user_id` | yes | Openbridge user ID |
| `--region` | yes | Typically `global`; defaults to it |
| `--return_url` | yes | Where the browser lands after consent |
| `--remote_identity_id` | no | Set to re-authorize an existing identity |
| `--oauth_id` | no | Required for Snowflake and Shopify |
| `--shop_url` | no | Shopify store URL |
| `--query_params` | no | Extra key/value pairs appended to `return_url` |

`account_id` and `oauth: true` are injected server-side from your token. The
response carries a `token` — that is the `state` parameter for the authorize
URL.

```bash
STATE=$(obcmd state create --remote_identity_type_id 19 --user_id 67890 \
  --return_url https://yourapp.example/oauth/complete --json | jq -r .token)
```

---

## Step 4 — Send the browser through the authorize URL

```
https://oauth.api.openbridge.io/oauth/initialize?state=<token>
```

Openbridge runs the provider's consent flow and redirects to your `return_url`
with `ri_id=<new identity id>` appended, plus anything you passed in
`--query_params`.

This step is a human's. The CLI cannot complete a consent screen, and there is
no device-code or headless variant.

---

## Step 5 — Confirm the identity exists

```bash
obcmd state get --token "$STATE"
obcmd remote-identity-shared list --remote_identity_type 19 --ordering=-id
obcmd remote-identity get --remote_identity_id 9001
```

Then resolve whatever platform-side IDs the subscription will need; see
[Resolving platform IDs](resolving-platform-ids.md).

---

## Re-authorizing a revoked identity

```bash
# 1. Which identities are revoked
obcmd remote-identity-shared list --invalid_identity 1

# 2. What breaks if this one stays broken
obcmd subscription list --remote_identity 9001 --fields id,name,status

# 3. Mint a state record pointed at the existing identity
obcmd state create --remote_identity_type_id 17 --user_id 67890 \
  --remote_identity_id 9001 \
  --return_url https://yourapp.example/oauth/complete
```

Passing `--remote_identity_id` re-authorizes in place, so existing
subscriptions keep working rather than needing to be repointed at a new
identity. Send the browser through the same authorize URL as step 4.

---

## Managing OAuth app records

```bash
obcmd oauth-app list
obcmd oauth-app list --remote_identity_type_id 19
obcmd oauth-app get --oauth_id 42                       # client_secret is never returned
obcmd oauth-app update --oauth_id 42 --client_secret "$NEW_SECRET"
obcmd oauth-app update --oauth_id 42 --name "Snowflake prod app"
obcmd oauth-app delete --oauth_id 42 --dry-run          # destructive; preview first
obcmd oauth-app delete --oauth_id 42 --yes
```

Deleting an app record does not revoke identities already created through it,
but new authorizations for that provider will fail until another record exists.

---

## Managing state records

```bash
obcmd state get --token "$STATE"
obcmd state update --token "$STATE" --state '{"step":"retry","attempt":2}'
obcmd state delete --token "$STATE" --yes
```

State records are short-lived flow context. `state update` replaces the stored
state object.

---

## Non-OAuth flows

```bash
obcmd generic-state create --state '{"flow":"manual-upload","customer":"acme"}'
```

`generic-state create` is unauthenticated: no account context is injected, and
no credential is acquired or sent. Use it to carry context through a flow that
is not an OAuth authorization.

---

## What the CLI cannot do here

- Invite a third party to authorize an identity on your behalf — console only
- The Amazon external re-auth landing page — a browser flow, not an API
- Complete a consent screen without a human

---

## See also

- [Inspecting identities](inspecting-identities.md)
- [Resolving platform IDs](resolving-platform-ids.md)
- [Creating a subscription](creating-a-subscription.md)
