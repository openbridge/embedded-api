# Creating a Subscription

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Account and user IDs](#step-1--account-and-user-ids)
- [Step 2 — Pick a source product](#step-2--pick-a-source-product)
- [Step 3 — Get the stage IDs](#step-3--get-the-stage-ids)
- [Step 4 — Pick a remote identity](#step-4--pick-a-remote-identity)
- [Step 5 — Resolve the platform-side parameters](#step-5--resolve-the-platform-side-parameters)
- [Step 6 — Pick a destination](#step-6--pick-a-destination)
- [Step 7 — Preview the create](#step-7--preview-the-create)
- [Step 8 — Create it](#step-8--create-it)
- [Step 9 — Wait for the job](#step-9--wait-for-the-job)
- [Subscription create fields](#subscription-create-fields)
- [Copy a working configuration rather than inventing one](#copy-a-working-configuration-rather-than-inventing-one)
- [Uniqueness failures](#uniqueness-failures)
- [Common rejections](#common-rejections)
- [See also](#see-also)

---

## Overview

A subscription is a pipeline. It connects three things:

| Part | Flag | Comes from |
|---|---|---|
| **Product** — what data | `--product` | `product list` |
| **Remote identity** — whose credentials | `--remote_identity` | `remote-identity-shared list` |
| **Destination** — where it lands | `--storage_group` | `storage list` |

Plus `--product_parameters`, a flat key/value object carrying platform-side
configuration: which advertising profile, which stages, which marketplace.

You need every ID before you can create one. There is no wizard and no
interactive prompt — the CLI will not resolve these for you.

---

## When to use this

- Standing up a new pipeline
- Scripting bulk pipeline creation from a list of accounts or profiles
- Recreating a pipeline that was retired

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- A valid remote identity for the product's identity type
- An existing destination; see [Provisioning a destination](provisioning-a-destination.md)

---

## Step 1 — Account and user IDs

```bash
obcmd account get --fields id
obcmd user get --fields id
obcmd config update --account_id 12345 --user_id 67890   # stop passing them
```

---

## Step 2 — Pick a source product

```bash
obcmd product list --is_storage_product 0 --name_contains "amazon attribution"
obcmd product get --product_id 50 --fields id,name,active,remote_identity_type_id
```

Creation is rejected for inactive products. `remote_identity_type_id` tells you
which kind of identity the product requires.

---

## Step 3 — Get the stage IDs

```bash
obcmd product-payload list --product_id 50 --fields name,stage_id
```

`stage_ids` is **required for source products that use pipeline stages**. Note
the type: it is a *string containing a JSON array*, not an array.

```jsonc
{"stage_ids":"[1000,1001,1002]"}   // correct
{"stage_ids":[1000,1001,1002]}     // rejected
```

---

## Step 4 — Pick a remote identity

```bash
obcmd remote-identity-shared list --remote_identity_type 14 --invalid_identity 0
```

Use `remote-identity-shared`, not `remote-identity` — it includes identities
shared with your account. If none exists, authorize one first; see
[Authorizing a third-party identity](authorizing-an-identity.md).

---

## Step 5 — Resolve the platform-side parameters

Most products need at least one identifier from the third-party platform:

```bash
obcmd amzadv-profile list --remote_identity_id 9001 --profile_types seller,vendor
obcmd sp-marketplace list --remote_identity_id 9001
obcmd googleads-customer list --remote_identity_id 9001
obcmd facebook-ad-account list --remote_identity_id 9001
```

The full set of lookups is in [Resolving platform IDs](resolving-platform-ids.md).

These values are **vendor-side**. An `account_id` or `profile_id` inside
`product_parameters` belongs to the remote platform and is unrelated to your
Openbridge account ID.

---

## Step 6 — Pick a destination

```bash
obcmd storage list --fields id,name,storage_group_id
```

Pass the `storage_group_id` value to `--storage_group`, not the row `id`.

---

## Step 7 — Preview the create

```bash
obcmd subscription create \
  --account 12345 --user 67890 --product 50 \
  --name "Amazon Attribution - Brand X" \
  --status active --date_start 2026-01-01T00:00:00Z \
  --remote_identity 9001 --storage_group 4001 \
  --product_parameters '{"stage_ids":"[1000,1001,1002]","profile_id":"3281014538916"}' \
  --dry-run
```

`--dry-run` resolves credentials, validates every flag and prints the exact
request body without sending it.

---

## Step 8 — Create it

Drop `--dry-run`:

```bash
obcmd subscription create \
  --account 12345 --user 67890 --product 50 \
  --name "Amazon Attribution - Brand X" \
  --status active --date_start 2026-01-01T00:00:00Z \
  --remote_identity 9001 --storage_group 4001 \
  --product_parameters '{"stage_ids":"[1000,1001,1002]","profile_id":"3281014538916"}'
```

Capture the ID:

```bash
SUB=$(obcmd subscription create ... --json | jq -r .id)
```

---

## Step 9 — Wait for the job

The backend creates the subscription's jobs **asynchronously**. Query
immediately and there are none; 6–9 seconds is typical.

```bash
sleep 15
obcmd job list --subscription_ids "$SUB" --fields id,status
```

Nothing that depends on a job — a history backfill, most notably — can run
against a subscription created in the same breath. Poll for the job first.

---

## Subscription create fields

| Flag | Required | Notes |
|---|---|---|
| `--account` | yes | From `account get` |
| `--user` | yes | From `user get` |
| `--product` | yes | From `product list`; must be active |
| `--status` | yes | `active`, `cancelled`, `paused` or `invalid` |
| `--date_start` | yes | ISO 8601; a plain `YYYY-MM-DD` is accepted. Never returned |
| `--name` | no | Human-readable label |
| `--date_end` | no | Defaults to `2099-12-31` |
| `--remote_identity` | no | Canonical location for the identity ID |
| `--storage_group` | no | The `storage_group_id` from `storage list` |
| `--product_parameters` | no | Flat key/value object; required for source products |

Set the identity via `--remote_identity`, not inside `--product_parameters`.
Supplying both is allowed only when they agree; conflicting values return `400`.

---

## Copy a working configuration rather than inventing one

Satisfying the required flags does not guarantee a valid subscription. Real ones
are source products that declare `required_meta_fields`, with
`remote_identity`, `storage_group` and `product_parameters` all set
consistently.

The reliable approach is to copy a known-good subscription's configuration:

```bash
# Find one on the same product
obcmd subscription list --product 50 --fields id,name,status

# Read its parameters
obcmd subscription-parameter list --subscription_id 116223
```

> `subscription-parameter list` returns one aggregate resource whose `id` is the
> subscription ID. Like every response, it arrives as an array — take the first
> element before spreading it into a new `product_parameters` object. Spreading
> the array itself yields `{"0":{...}}`, which the API rejects with
> `data_value: Not a valid string`.

```bash
PARAMS=$(obcmd subscription-parameter list --subscription_id 116223 --json \
  | jq -c '.[0] | {stage_ids, profile_id}')

obcmd subscription create --account 12345 --user 67890 --product 50 \
  --status active --date_start 2026-01-01 \
  --remote_identity 9001 --storage_group 4001 \
  --product_parameters "$PARAMS" --dry-run
```

Copy `product_parameters` wholesale. The keys are defined by the vendor, not by
Openbridge, and a missing one fails at create time with a message about the
vendor's field name.

---

## Uniqueness failures

Creating a subscription whose (product, identity, parameters) combination
matches an existing one fails:

```
CONSOLE_EXCEPTION_CREATE_SUBSCRIPTION_SPP_ALREADY_EXISTS
Uniqueness constraint failure: duplicate of subscription 107194
```

`cancelled` collides as well as `active`. Only `invalid` frees the combination:

```bash
obcmd subscription update --subscription_id 107194 --status invalid --yes
```

This is why `invalid` — not `cancelled` — is the retirement status, and why an
`invalid` subscription is the right one to copy a configuration from.

---

## Common rejections

| Error | Cause |
|---|---|
| `400` on an inactive product | Creation is rejected for products with `active: 0` |
| `data_value: Not a valid string` | `stage_ids` passed as an array, or an aggregate spread without taking `[0]` |
| `400` on conflicting identity | `remote_identity` set both as a flag and inside `product_parameters` with different values |
| `CONSOLE_EXCEPTION_..._ALREADY_EXISTS` | Duplicate combination; retire the original with `--status invalid` |
| Vendor field name in the message | A required `product_parameters` key is missing; copy from a working subscription |

---

## See also

- [Managing subscriptions](managing-subscriptions.md) — pausing, repointing, retiring
- [Resolving platform IDs](resolving-platform-ids.md)
- [Requesting historical data](history-backfill.md) — backfilling after create
- [Recipes](../recipes.md)
