# Monitoring Pipelines

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Sweep the account for failures](#step-1--sweep-the-account-for-failures)
- [Step 2 — Check one subscription's health](#step-2--check-one-subscriptions-health)
- [Step 3 — List its jobs](#step-3--list-its-jobs)
- [Step 4 — Read one job](#step-4--read-one-job)
- [Step 5 — Follow the processing transactions](#step-5--follow-the-processing-transactions)
- [Step 6 — Confirm data actually landed](#step-6--confirm-data-actually-landed)
- [Step 7 — Rule out a revoked credential](#step-7--rule-out-a-revoked-credential)
- [Transaction status values](#transaction-status-values)
- [Jobs authorize by subscription, and say 403 when they mean 400](#jobs-authorize-by-subscription-and-say-403-when-they-mean-400)
- [Transactions are a merged current state, not an attempt history](#transactions-are-a-merged-current-state-not-an-attempt-history)
- [What the CLI cannot do here](#what-the-cli-cannot-do-here)
- [See also](#see-also)

---

## Overview

Three endpoints answer "is this pipeline working?", at three different
altitudes:

| Command | Altitude | Answers |
|---|---|---|
| `healthcheck list` | Account | Which subscriptions are reporting errors |
| `job list` / `job get` | Subscription | What runs exist and what state they are in |
| `transaction list` | Run | What each stage of processing did, and why it failed |

---

## When to use this

- A pipeline stopped producing data
- Data arrived late or incomplete
- A backfill was triggered and you want to watch it
- Daily sweep for errors across an account

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- Your account ID: `obcmd account get --fields id`

---

## Step 1 — Sweep the account for failures

```bash
obcmd healthcheck list --account_id 12345 --status ERROR --order_by=-modified_at
```

Narrow by time with a Django-style lookup:

```bash
obcmd healthcheck list --account_id 12345 --status ERROR \
  --filter modified_at__gte=2026-01-01
```

| Flag | Effect |
|---|---|
| `--account_id` | Required; must match the account in your token |
| `--status` | e.g. `OK`, `ERROR` |
| `--subscription_id` | One pipeline |
| `--product_id`, `--job_id` | Narrow further |
| `--order_by` | Comma-separated; prefix `-` for descending, attached with `=` |

A leading `-` needs the `=` form: `--order_by=-modified_at`. Without it the
shell hands the value to the parser as a flag.

Requesting another account returns `403`.

---

## Step 2 — Check one subscription's health

```bash
obcmd healthcheck list --account_id 12345 --subscription_id 116223 --order_by=-modified_at
```

---

## Step 3 — List its jobs

```bash
obcmd job list --subscription_ids 116223
obcmd job list --subscription_ids 116223 --order_by=-modified_at
obcmd job list --subscription_ids 116223,116224 --all
```

`--subscription_ids` is **required**. Two traps:

- The singular spelling `subscription_id` is read as no filter at all by the
  API. The CLI only sends the plural.
- `--ids` is accepted and ignored by the API — naming one job of six returned
  all six. Use `--id` to narrow to a single job.

```bash
obcmd job list --subscription_ids 116223 --id 98765      # filters correctly
```

Failed runs only:

```bash
obcmd job list --subscription_ids 116223 --all | jq -c 'select(.status != "processed")'
```

---

## Step 4 — Read one job

```bash
obcmd job get --job_id 98765 --subscription_ids 116223
```

Both flags are required, even though the path already names the job — see
[below](#jobs-authorize-by-subscription-and-say-403-when-they-mean-400).

---

## Step 5 — Follow the processing transactions

```bash
obcmd transaction list --subscription_id 116223
obcmd transaction list --subscription_id 116223 --status ERROR
obcmd transaction list --subscription_id 116223 --job_id 98765
obcmd transaction list --subscription_id 116223 --attribution_date 2026-01-15
obcmd transaction list --subscription_id 116223 --sender zeroadmin --status PROCESSED
```

`--subscription_id` is required on every call, including cursor pages and tree
queries; without it the Service API returns `403`.

Expand a transaction's children into merged root-to-descendant records:

```bash
obcmd transaction list --subscription_id 116223 --tree --tree_depth 2
```

Pagination here is **cursor-based**, not page-based:

```bash
# Stream every page
obcmd transaction list --subscription_id 116223 --all

# Or walk it manually; the cursor token is reported on stderr
obcmd transaction list --subscription_id 116223 --limit 200
obcmd transaction list --subscription_id 116223 --limit 200 --cursor "<token>"
```

Keep every other filter unchanged across cursor pages. A short page, or even an
empty one, can still have a next page.

Transactions are retained for **three days**.

Prefer `--timestamp_from` / `--timestamp_to` (Unix seconds) over
`--modified_at_from` / `--modified_at_to`, which compare the stored text
lexicographically and only match if you reproduce the stored format exactly.

---

## Step 6 — Confirm data actually landed

```bash
obcmd transaction list --subscription_id 116223 \
  --sender zeroadmin --status PROCESSED \
  --attribution_date 2026-01-15
```

Only `PROCESSED` from `zeroadmin` confirms a destination load. A `PROCESSED`
from another sender means that component finished its part, not that the
warehouse has the rows.

Note that `--attribution_date` is the **data date requested upstream**, not the
processing time, and it is exact-match: a date-only value does not match a
stored value carrying a time.

---

## Step 7 — Rule out a revoked credential

```bash
obcmd remote-identity-shared list --invalid_identity 1
obcmd subscription get --subscription_id 116223 --fields remote_identity_id,status
```

A pipeline on an invalid identity stops producing data, and the healthcheck
error will not always say so plainly. Re-authorize rather than recreate; see
[Authorizing a third-party identity](authorizing-an-identity.md).

---

## Transaction status values

`--status` accepts one of: `UNPROCESSED`, `PROCESSING`, `IN_PROGRESS`, `RETRY`,
`ERROR`, `PROCESSED`, `SUCCESS`, `NO_DATA`, `IGNORED`.

Senders are `scheduler`, `supervisor`, `ftpsync` and `zeroadmin`. Read
`--status` alongside `--sender`: the same status from a different component
means something different, and **only `PROCESSED` from `zeroadmin` confirms a
destination load**.

```bash
obcmd transaction list --subscription_id 116223 --status ERROR --sender scheduler
obcmd transaction list --subscription_id 116223 --status NO_DATA
```

---

## Jobs authorize by subscription, and say 403 when they mean 400

Both job commands require `--subscription_ids`. Omit it and the API answers
**`403 "Forbidden GET jobs: No subscription IDs provided"`** — a missing
argument reported as a permission error.

```bash
obcmd job get --job_id 98765                          # 403
obcmd job get --job_id 98765 --subscription_ids 116223  # the record
```

The backend gates on the subscription, not on the record addressed, so you have
to know which subscription a job belongs to before you can read that job.

The practical consequence: do not treat a `403` from this backend as "no
access". Check the arguments first.

---

## Transactions are a merged current state, not an attempt history

Retries reuse the same transaction ID and updates are merged. A record is the
current state of that unit of work, so `--status ERROR` finds **what is failing
now**, not everything that ever failed.

Filters are exact-match and AND-combined — there is no substring or multi-value
form. `--error_message` matches the full message only; `--job_id` will not match
the many records that store an empty `job_id`.

---

## What the CLI cannot do here

- Change a job's schedule — `job` is list/get only
- Process a healthcheck request — `healthcheck list` is read-only
- Retrieve transactions older than three days

---

## See also

- [Managing subscriptions](managing-subscriptions.md) — pausing a broken pipeline
- [Requesting historical data](history-backfill.md) — re-running failed dates
- [Inspecting identities](inspecting-identities.md)
- [Troubleshooting](../troubleshooting.md)
