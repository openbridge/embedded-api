# Requesting Historical Data

## Table of Contents

- [Overview](#overview)
- [When to use history requests](#when-to-use-history-requests)
- [Prerequisites](#prerequisites)
- [Step 1 — Find the subscription ID](#step-1--find-the-subscription-id)
- [Step 2 — Confirm the subscription has a job](#step-2--confirm-the-subscription-has-a-job)
- [Step 3 — Find available stage IDs (optional)](#step-3--find-available-stage-ids-optional)
- [Step 4 — Check your request limit](#step-4--check-your-request-limit)
- [Step 5 — Trigger the backfill](#step-5--trigger-the-backfill)
- [Step 6 — Check transaction status](#step-6--check-transaction-status)
- [Step 7 — Cancel a transaction](#step-7--cancel-a-transaction)
- [HistoryTransaction fields](#historytransaction-fields)
- [The date flags are backwards from what you expect](#the-date-flags-are-backwards-from-what-you-expect)
- [Four preconditions, each with its own 404](#four-preconditions-each-with-its-own-404)
- [Batch processing multiple subscriptions](#batch-processing-multiple-subscriptions)
- [See also](#see-also)

---

## Overview

After a subscription is created, Openbridge collects data going forward. To
retrieve data from before the subscription existed — or to re-request a date
range where processing failed — trigger a **history transaction**. Each one
tells Openbridge to run the pipeline for a specific subscription and date range,
and returns the `job_ids` it queued.

---

## When to use history requests

- **Backfill after creating a subscription** — it collects from today onward,
  but you need last quarter too
- **Re-request after a failure** — fix the root cause, then re-request the
  affected dates
- **Targeted stage retrieval** — one dataset re-processed, not all of them
- **Bulk operations** — backfill a date across many subscriptions

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- A subscription that **already has a job**
- A product with historical meta for its (product, subproduct, stage) triple

---

## Step 1 — Find the subscription ID

```bash
obcmd subscription list --status active --fields id,name,product_id
obcmd subscription list --product 2 --fields id,name
```

---

## Step 2 — Confirm the subscription has a job

```bash
obcmd job list --subscription_ids 116223 --fields id,status
```

History resolves product and stage from the job. Without one, the trigger fails
with `404 "No job found for subscription ID N."`

Jobs are created asynchronously, roughly 6–9 seconds after the subscription.
A subscription created in the same breath as the backfill will not have one yet.

---

## Step 3 — Find available stage IDs (optional)

```bash
obcmd product-payload list --product_id 2 --fields name,stage_id
```

Each payload definition has a `stage_id` and a `name` describing the dataset.
Omit `--stage_id` to process all stages for the subscription.

> A `stage_id` appearing here does not mean the product supports history. That
> is governed by historical meta, which is separate. See
> [Four preconditions](#four-preconditions-each-with-its-own-404).

---

## Step 4 — Check your request limit

```bash
obcmd history-limit get
```

There is a maximum number of history transactions that can be active at once.
`history-limit get` returns every limit row — one per (product, subproduct,
stage) — and always as an array.

> This is **not** the list of products that support history. A product can
> appear here and still have no historical meta.

---

## Step 5 — Trigger the backfill

Preview first:

```bash
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-31 --end_date 2026-01-01 --dry-run
```

Then send it:

```bash
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-31 --end_date 2026-01-01
```

A single day:

```bash
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-15 --end_date 2026-01-15
```

Specific non-contiguous dates:

```bash
obcmd history trigger --subscription_id 116223 \
  --dates '["2026-01-05","2026-01-12","2026-02-01"]'
```

One stage, scheduled to begin later:

```bash
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-15 --end_date 2026-01-15 \
  --stage_id 1000 --start_time "2026-03-01 13:40:00"
```

Either `--dates`, or both `--start_date` and `--end_date`, must be supplied.
The response is a HistoryTransaction carrying the `job_ids` it queued.

---

## Step 6 — Check transaction status

```bash
# Every transaction for a subscription
obcmd history list --subscription_id 116223

# One transaction by its own ID
obcmd history get --transaction_id 72418
```

A subscription has no history transactions until one is triggered, so an empty
listing says nothing about whether the product supports history.

---

## Step 7 — Cancel a transaction

```bash
# One transaction
obcmd history cancel --transaction_id 72418 --dry-run
obcmd history cancel --transaction_id 72418 --yes

# Every transaction on a subscription
obcmd history delete --subscription_id 116223 --dry-run
obcmd history delete --subscription_id 116223 --yes
```

Both are destructive and require `--yes`. `history cancel` cancels the jobs the
transaction queued and reports how many were updated:

```json
{ "updated": 14 }
```

The transaction itself stays listed afterwards — cancellation is a state change,
not a deletion.

---

## HistoryTransaction fields

| Flag | Type | Required | Description |
|---|---|---|---|
| `--subscription_id` | integer | yes | Path parameter; the subscription to backfill |
| `--start_date` | `YYYY-MM-DD` | yes* | Range start — the **more recent** date |
| `--end_date` | `YYYY-MM-DD` | yes* | Range end — the **older** date |
| `--dates` | JSON array | yes* | Specific non-contiguous dates; use instead of a range |
| `--product_id` | integer | no | Restrict the run to one product |
| `--stage_id` | integer | no | Restrict to one stage. Requires `--start_time` |
| `--start_time` | `YYYY-MM-DD HH:MM:SS` | no | When processing begins. Must be in the **future** |
| `--primary_run` | boolean | no | Whether this is a primary run |

\* Provide either `--dates`, or both `--start_date` and `--end_date`.

---

## The date flags are backwards from what you expect

`start_date` is the **more recent** date and `end_date` the **older** one. The
API converts both to days back from today and requires `start < end` in that
converted form.

```bash
# Correct: January 31 back to January 1
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-31 --end_date 2026-01-01

# Rejected: "do you have start_date and end_date backwards?"
obcmd history trigger --subscription_id 116223 \
  --start_date 2026-01-01 --end_date 2026-01-31
```

A request for 2026-08-21 → 2026-08-20 comes back as `start_days: 3`,
`end_days: 4`.

`--start_time` is unrelated to the range. It schedules **when processing
begins**, must be in the future, and is required whenever `--stage_id` is used.

---

## Four preconditions, each with its own 404

| Precondition | Failure |
|---|---|
| The subscription has a job | `404 "No job found for subscription ID N."` |
| The product has historical meta for its (product, subproduct, stage) triple | `404 "No historical meta found for product N.default, stage S."` |
| `start_date` is more recent than `end_date` | "do you have start_date and end_date backwards?" |
| `--stage_id` is paired with a future `--start_time` | Usage error, or a rejected schedule |

Historical meta is a property of the product. Facebook Page Insights
(product 2) has it; some products do not, despite appearing in
`history-limit get`. Neither that endpoint nor a payload's `stage_id` is
evidence of history support — the only test is triggering a request.

---

## Batch processing multiple subscriptions

For a CSV of `date,subscription_id,stage_id`:

```csv
date,subscription_id,stage_id
2026-01-01,116223,1001
2026-01-01,116224,1001
2026-01-02,116223,
2026-01-02,116224,
```

```bash
tail -n +2 backfill.csv | while IFS=, read -r date sub stage; do
  if [ -n "$stage" ]; then
    obcmd history trigger --subscription_id "$sub" \
      --dates "[\"$date\"]" --stage_id "$stage" \
      --start_time "2026-03-01 14:00:00" || echo "failed: $sub $date" >&2
  else
    obcmd history trigger --subscription_id "$sub" \
      --start_date "$date" --end_date "$date" || echo "failed: $sub $date" >&2
  fi
done
```

Stagger large batches by incrementing `--start_time` by a few minutes per
request. That keeps the pipeline from being flooded and respects the per-triple
limit from `history-limit get`.

Rate limiting is handled for you: on `429` the CLI waits the `Retry-After`
value, then backs off exponentially with jitter up to `OBCMD_MAX_RETRIES`
attempts.

---

## See also

- [Monitoring pipelines](monitoring-pipelines.md) — watching the jobs a backfill queued
- [Creating a subscription](creating-a-subscription.md) — why a fresh subscription has no job yet
- [Command Reference](../commands.md)
