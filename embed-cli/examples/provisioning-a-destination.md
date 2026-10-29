# Provisioning a Destination

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Browse the destination catalog](#step-1--browse-the-destination-catalog)
- [Step 2 — Authorize the warehouse credentials](#step-2--authorize-the-warehouse-credentials)
- [Step 3 — Preview the create](#step-3--preview-the-create)
- [Step 4 — Create the destination](#step-4--create-the-destination)
- [Step 5 — Poll until it is ready](#step-5--poll-until-it-is-ready)
- [Step 6 — Find the storage group ID](#step-6--find-the-storage-group-id)
- [Step 7 — Point a pipeline at it](#step-7--point-a-pipeline-at-it)
- [`id` vs `storage_group_id`](#id-vs-storage_group_id)
- [What the CLI cannot do here](#what-the-cli-cannot-do-here)
- [See also](#see-also)

---

## Overview

A destination is where pipeline data lands: Redshift, BigQuery, Snowflake,
Databricks, Azure, S3 and the rest. Creating one is **asynchronous** — the
create call returns `202` with a `co_id`, and you poll that operation ID until
it succeeds or fails.

Subscriptions reference a destination by `storage_group_id`, which is not the
same number as the row's `id`.

---

## When to use this

- Standing up a new warehouse or data lake destination
- Resuming a poll on a create that was still running
- Finding the `storage_group_id` a subscription needs

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- A remote identity holding the warehouse credentials, for backends that need
  one; see [Authorizing a third-party identity](authorizing-an-identity.md)

---

## Step 1 — Browse the destination catalog

```bash
obcmd product list --is_storage_product 1 --fields id,name
```

Destination products are the same catalog as source products, filtered by
`--is_storage_product 1`.

---

## Step 2 — Authorize the warehouse credentials

Most backends authenticate through a remote identity. Find or create one first:

```bash
obcmd identity-type list --name_contains bigquery
obcmd remote-identity-shared list --remote_identity_type 12 --invalid_identity 0
```

The resulting `remote_identity_id` goes inside `--storage_parameters`.

---

## Step 3 — Preview the create

```bash
obcmd destination create \
  --name "My Redshift Destination" \
  --storage_parameters '{"storage":"redshift","remote_identity_id":9001}' \
  --dry-run
```

`--storage_parameters` is a JSON object describing the connection. Its shape is
backend-specific and passed through to the service API; the `storage` key names
the backend.

> Only the Redshift shape is documented here. Other backends — Snowflake,
> BigQuery, Databricks, Azure Blob and Data Lake, S3, Spectrum, Athena — are
> reachable through the same flag, but their parameter keys are defined by the
> service API rather than by the CLI. Get the exact object from the
> destination's API documentation, then pass it verbatim.

---

## Step 4 — Create the destination

```bash
obcmd destination create \
  --name "My Redshift Destination" \
  --storage_parameters '{"storage":"redshift","remote_identity_id":9001}'
```

The response is `202` with a `co_id`. Nothing is provisioned yet.

---

## Step 5 — Poll until it is ready

```bash
obcmd destination get --co_id 88123
```

| Status | Meaning | Next |
|---|---|---|
| `202` | Still processing | Poll again |
| `200` | Ready; returns the created subscription | Continue |
| `400` | Validation failed | Fix the parameters and create again |

Poll on an interval rather than in a tight loop, and read the record it
returns — a `202` is a successful HTTP response, so the exit code stays `0`
while provisioning is still in flight. Treat the response body, not the exit
code, as the signal:

```bash
obcmd destination get --co_id 88123 --json | jq '{id, status}'
```

---

## Step 6 — Find the storage group ID

```bash
obcmd storage list
obcmd storage list --fields id,name,storage_group_id
obcmd storage list --status active --all
```

`storage list` is read-only and defaults to `--status active`. It is the only
listing of existing destinations in the CLI.

---

## Step 7 — Point a pipeline at it

```bash
# A new pipeline
obcmd subscription create --account 12345 --user 67890 --product 50 \
  --status active --date_start 2026-01-01 \
  --remote_identity 9001 --storage_group 4001 \
  --product_parameters '{"stage_ids":"[1000]"}'

# An existing pipeline, repointed
obcmd subscription update --subscription_id 116223 --storage_group 4001 --dry-run

# Everything currently landing in the old destination
obcmd subscription list --storage_group 3990 --fields id,name,status
```

Repointing is one call per subscription. Loop over the IDs from the last
command; the CLI has no bulk form.

---

## `id` vs `storage_group_id`

Use the **`storage_group_id`** field from `storage list`, not the row `id`, for:

- `--storage_group` on `subscription create` and `subscription update`
- `--storage_group` on `subscription list`

Passing the row `id` is accepted as a number and silently matches nothing or the
wrong group. The two values differ, and nothing in the error path tells you
which one you used.

---

## What the CLI cannot do here

- Deactivate or delete a destination — destinations are read-only via
  `storage list`; retire or repoint the subscriptions instead
- Check plan entitlement before creating one
- Browse S3 buckets, prefixes or objects

---

## See also

- [Managing subscriptions](managing-subscriptions.md) — repointing in bulk
- [Browsing the product catalog](browsing-the-catalog.md)
- [Authorizing a third-party identity](authorizing-an-identity.md)
