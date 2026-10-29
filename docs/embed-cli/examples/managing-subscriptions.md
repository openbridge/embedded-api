# Managing Subscriptions

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Browse and search pipelines](#step-1--browse-and-search-pipelines)
- [Step 2 — Read one pipeline](#step-2--read-one-pipeline)
- [Step 3 — Export pipelines to a file](#step-3--export-pipelines-to-a-file)
- [Step 4 — Rename a pipeline](#step-4--rename-a-pipeline)
- [Step 5 — Pause and resume](#step-5--pause-and-resume)
- [Step 6 — Change product parameters](#step-6--change-product-parameters)
- [Step 7 — Repoint a pipeline](#step-7--repoint-a-pipeline)
- [Step 8 — Retire a pipeline](#step-8--retire-a-pipeline)
- [Status values](#status-values)
- [Reading stored parameters in bulk](#reading-stored-parameters-in-bulk)
- [Creating a single parameter row](#creating-a-single-parameter-row)
- [Filter spellings that silently do nothing](#filter-spellings-that-silently-do-nothing)
- [See also](#see-also)

---

## Overview

Everything after creation: finding pipelines, reading their configuration,
pausing them, repointing them, and retiring them. All of it is one call per
subscription — the CLI has no bulk-select, so loops live in your shell.

---

## When to use this

- Auditing what pipelines exist and what state they are in
- Pausing a pipeline while a credential or destination is being fixed
- Changing a pipeline's stages, profile or destination
- Retiring a pipeline, or freeing a uniqueness collision

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)

---

## Step 1 — Browse and search pipelines

```bash
obcmd subscription list
obcmd subscription list --status active --fields id,name,status
obcmd subscription list --product 50
obcmd subscription list --remote_identity 9001
obcmd subscription list --storage_group 4001
obcmd subscription list --status_not invalid --all
```

| Flag | Effect |
|---|---|
| `--id` | One subscription by ID |
| `--name` | Exact name match |
| `--status` | `active`, `cancelled`, `paused`, `invalid` |
| `--status_not` | Exclude a status, e.g. `invalid` |
| `--account`, `--user`, `--product` | Filter by owner or product |
| `--remote_identity` | Pipelines using one identity |
| `--storage_group` | Pipelines landing in one destination |
| `--page`, `--page_size` | Pagination; or `--all` for NDJSON |

There is **no sort flag** — `/v2/sub` exposes no ordering here. Sort on the
client:

```bash
obcmd subscription list --all --fields id,name,status | jq -s 'sort_by(.name)'
```

---

## Step 2 — Read one pipeline

```bash
obcmd subscription get --subscription_id 116223
obcmd subscription get --subscription_id 116223 --fields '*'
obcmd subscription-parameter list --subscription_id 116223
obcmd healthcheck list --account_id 12345 --subscription_id 116223
obcmd job list --subscription_ids 116223 --fields id,status
```

Those five calls are the CLI equivalent of the console's pipeline overview:
record, stored parameters, health, and jobs.

---

## Step 3 — Export pipelines to a file

```bash
obcmd subscription list --all > pipelines.ndjson          # every page, one object per line
obcmd subscription list --json > pipelines.json           # one page as a JSON array
obcmd subscription list --status active --all > active.ndjson
```

A field mask keeps the export narrow:

```bash
obcmd subscription list --all --fields id,name,status,product_id,storage_group_id > inventory.ndjson
```

"Export selected" is a filter or a `jq` expression — there is no selection state
to carry.

---

## Step 4 — Rename a pipeline

```bash
obcmd subscription update --subscription_id 116223 --name "Brand X - Attribution (prod)"
```

---

## Step 5 — Pause and resume

```bash
obcmd subscription update --subscription_id 116223 --status paused
obcmd subscription update --subscription_id 116223 --status active
```

Neither needs `--yes`: `paused` and `active` are not destructive transitions.

Bulk pause is a loop:

```bash
obcmd subscription list --product 50 --status active --fields id --all \
  | jq -r .id \
  | while read -r id; do
      obcmd subscription update --subscription_id "$id" --status paused
    done
```

Dry-run the loop first by appending `--dry-run` to the inner command.

---

## Step 6 — Change product parameters

`product_parameters` **merges** on update. Omitted keys keep their stored value,
and an empty object clears nothing.

```bash
obcmd subscription update --subscription_id 116223 \
  --product_parameters '{"stage_ids":"[1000,1001]"}'

# Confirm what is now stored
obcmd subscription-parameter list --subscription_id 116223
```

There is no "replace all parameters" operation and no null-to-delete. The legacy
`subscription_product_meta_attributes` attribute is rejected.

---

## Step 7 — Repoint a pipeline

```bash
# To a new destination
obcmd subscription update --subscription_id 116223 --storage_group 4002 --dry-run

# To a re-authorized identity
obcmd subscription update --subscription_id 116223 --remote_identity 9002
```

Everything currently landing in the old destination:

```bash
obcmd subscription list --storage_group 4001 --fields id,name --all \
  | jq -r .id \
  | while read -r id; do
      obcmd subscription update --subscription_id "$id" --storage_group 4002
    done
```

---

## Step 8 — Retire a pipeline

```bash
# Preview
obcmd subscription update --subscription_id 116223 --status invalid --dry-run

# Retire
obcmd subscription update --subscription_id 116223 --status invalid --yes

# Or the dedicated verb, which sets cancelled
obcmd subscription cancel --subscription_id 116223 --yes
```

There is no `subscription delete`, and there will not be one. A subscription ID
appears in history transactions, jobs and invoices; removing the row would
orphan all of it. The record staying in the table is the intended outcome.

`--status cancelled` and `--status invalid` both require `--yes`, on
`subscription update` as well as `subscription cancel`, because all three reach
the same end state. `describe --json` reports this as `destructive_when`.

---

## Status values

| Status | Meaning | Frees a uniqueness collision? |
|---|---|---|
| `active` | Running | — |
| `paused` | Temporarily stopped, configuration intact | No |
| `cancelled` | Cancelled | **No** |
| `invalid` | Retired; the terminal state | **Yes** |

`cancelled` and `invalid` are different states with different meanings. If you
need to create a replacement with the same (product, identity, parameters)
combination, the original must be `invalid` — a cancelled one still blocks the
create.

---

## Reading stored parameters in bulk

```bash
# One subscription
obcmd subscription-parameter list --subscription_id 116223

# Up to 100 at once
obcmd subscription-parameter get --subscription_ids 116223,116224,116225
```

`subscription-parameter get` is all-or-nothing: if any ID is missing or
inaccessible, the whole request returns `404`. It always returns an array, one
row per requested ID, including for a single ID.

---

## Creating a single parameter row

```bash
obcmd subscription-parameter create \
  --data_key profile_id --data_value "3281014538916" --subscription 116223
```

Rarely needed — prefer `--product_parameters` on create or update. A duplicate
key returns `409`.

---

## Filter spellings that silently do nothing

`subscription list` once sent hyphenated query parameters. The API accepts them,
filters nothing, and returns the full unfiltered page at exit `0` — a request
for one storage group came back with 200 records spanning 16 different groups.

```bash
obcmd subscription list --storage_group 4001     # correct; sends storage_group=
obcmd subscription list --remote_identity 9001   # correct; sends remote_identity=
```

The CLI only sends underscore spellings, and a test asserts no remapped
parameter contains a hyphen. If you are driving the API directly with `curl`,
use `storage_group`, `storage_group_id`, `remote_identity` or
`remote_identity_id` — never the hyphenated forms.

---

## See also

- [Creating a subscription](creating-a-subscription.md)
- [Monitoring pipelines](monitoring-pipelines.md)
- [Provisioning a destination](provisioning-a-destination.md)
