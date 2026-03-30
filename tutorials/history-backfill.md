# Requesting Historical Data

## Table of Contents

- [Overview](#overview)
- [When to use history requests](#when-to-use-history-requests)
- [Prerequisites](#prerequisites)
- [Step 1 — Find the subscription ID](#step-1--find-the-subscription-id)
- [Step 2 — Find available stage IDs (optional)](#step-2--find-available-stage-ids-optional)
- [Step 3 — Create a history transaction](#step-3--create-a-history-transaction)
  - [HistoryTransaction fields](#historytransaction-fields)
  - [Minimal request — date range only](#minimal-request--date-range-only)
  - [Targeted request — with stage ID and start time](#targeted-request--with-stage-id-and-start-time)
  - [Non-contiguous dates](#non-contiguous-dates)
- [Step 4 — Check transaction status](#step-4--check-transaction-status)
- [Step 5 — Cancel a transaction](#step-5--cancel-a-transaction)
- [Batch processing multiple subscriptions](#batch-processing-multiple-subscriptions)
  - [CSV format](#csv-format)
  - [Processing the batch](#processing-the-batch)
- [Rate limits and quotas](#rate-limits-and-quotas)
- [Using the CLI](#using-the-cli)

---

## Overview

After a subscription is created, Openbridge begins collecting data going forward. To retrieve data from before the subscription was created — or to re-request data for a date range where processing failed — use the History API to create `HistoryTransaction` records. Each transaction tells Openbridge to run the pipeline for a specific subscription and date range.

---

## When to use history requests

- **Backfill after creating a new subscription** — your subscription collects data from today onward, but you need last quarter's data too.
- **Re-request after a failure** — a healthcheck shows errors for certain dates. Fix the root cause (invalid identity, rate limit, etc.), then re-request the affected date range.
- **Targeted stage retrieval** — you only need one specific dataset (stage) re-processed, not all stages for the subscription.
- **Bulk operations** — you need to backfill across many subscriptions at once using a CSV of subscription IDs and date ranges.

---

## Prerequisites

All API calls require a JWT access token. Obtain one by exchanging your refresh token with the [Authentication API](../api-usage-docs/authentication-api.md).

You will need:
- A **subscription ID** for an active subscription
- Optionally, a **stage ID** to target a specific dataset

---

## Step 1 — Find the subscription ID

List your subscriptions to find the one you want to backfill:

```
GET https://subscriptions.api.openbridge.io/sub?account={account_id}
```

Use the `id` field from the subscription record. You can filter by product:

```
GET https://subscriptions.api.openbridge.io/sub?account={account_id}&product={product_id}
```

See the [Subscriptions API](../api-usage-docs/subscriptions-api.md) for all available query filters.

---

## Step 2 — Find available stage IDs (optional)

If you want to target a specific dataset within the subscription's product, look up the available stage IDs:

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

Each record in the response has a `stage_id` and a `name` describing the dataset. Use the `stage_id` value in your history request to limit processing to that specific dataset.

If you omit the `stage_id`, Openbridge processes all stages for the subscription.

---

## Step 3 — Create a history transaction

```
POST https://service.api.openbridge.io/service/history/production/history/{subscription_id}
```

### HistoryTransaction fields

| Field | Type | Required | Description |
|---|---|---|---|
| `start_date` | string (`YYYY-MM-DD`) | Yes* | Start of the date range |
| `end_date` | string (`YYYY-MM-DD`) | Yes* | End of the date range |
| `dates` | array of strings | Yes* | Specific non-contiguous dates to retrieve; use instead of `start_date`/`end_date` |
| `product_id` | integer | No | Limit to a specific product within the subscription |
| `stage_id` | integer | No | Limit to a specific pipeline stage |
| `start_time` | string (`YYYY-MM-DD HH:MM:SS`) | No | Schedule processing to begin at this time rather than immediately |

\* Provide either `dates` or both `start_date` and `end_date`.

### Minimal request — date range only

Backfill all data for a single day:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "start_date": "2024-06-03",
      "end_date": "2024-06-03"
    }
  }
}
```

Backfill a range:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "start_date": "2024-01-01",
      "end_date": "2024-03-31"
    }
  }
}
```

### Targeted request — with stage ID and start time

Process only stage `1000`, scheduled to begin at a specific time:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "start_date": "2024-04-01",
      "end_date": "2024-04-01",
      "stage_id": 1000,
      "start_time": "2024-07-01 13:40:00"
    }
  }
}
```

The `start_time` is useful when submitting many requests at once — stagger them to avoid overwhelming the pipeline.

### Non-contiguous dates

Use the `dates` array when you need specific dates that are not a continuous range:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "dates": ["2024-09-01", "2024-09-15", "2024-10-01"],
      "stage_id": 1000,
      "start_time": "2024-10-02 14:00:00"
    }
  }
}
```

---

## Step 4 — Check transaction status

After creating a transaction, check its status:

```
GET https://service.api.openbridge.io/service/history/production/history/status/{subscription_id}
```

This returns all transaction status records for the subscription. Each record includes a `status` field indicating whether the transaction is pending, processing, completed, or failed.

To check a specific transaction by its own ID:

```
GET https://service.api.openbridge.io/service/history/production/history/{transaction_id}
```

---

## Step 5 — Cancel a transaction

If you need to cancel a pending or in-progress transaction:

```
PATCH https://service.api.openbridge.io/service/history/production/history/status/{transaction_id}
```

```json
{
  "data": {
    "type": "HistoryTransaction",
    "id": 72418,
    "attributes": {
      "status": "cancelled"
    }
  }
}
```

---

## Batch processing multiple subscriptions

When you need to create history transactions across many subscriptions — for example, backfilling a date for every active subscription — prepare a CSV file and process it programmatically.

### CSV format

```
date,subscription_id,stage_id
2024-01-01,116223,1001
2024-01-01,116224,1001
2024-01-02,116223,
2024-01-02,116224,
```

Each row creates one history transaction. The `stage_id` column is optional — leave it empty to process all stages.

### Processing the batch

For each row in the CSV, POST a `HistoryTransaction` to the History API:

```
POST https://service.api.openbridge.io/service/history/production/history/{subscription_id}
```

With the payload constructed from the row's date and optional stage ID.

When submitting many requests, stagger them by setting `start_time` to a value in the future, incrementing by a few minutes per request. This avoids overwhelming the pipeline and respects rate limits.

---

## Rate limits and quotas

There is a maximum number of history transactions you can have active at once. Check your current limit:

```
GET https://service.api.openbridge.io/service/history/production/history/meta/max-request
```

If you hit the limit, wait for existing transactions to complete before submitting new ones.

---

## Using the CLI

The `embed-cli` provides shorthand commands for the workflows above.

**Create a single history transaction:**

```bash
embed-cli jobs create --start 2024-01-01 --end 2024-01-01 --subscription 116223
```

**Create a history transaction with a stage ID:**

```bash
embed-cli jobs create --start 2024-01-01 --end 2024-01-01 --subscription 116223 --stage 1001
```

**Batch process a CSV file:**

```bash
embed-cli jobs batch --file backfill.csv
```

The CSV format is `date,subscription_id,stage_id` (with a header row). The CLI handles progress tracking, error logging, and BOM removal automatically.

See [History API](../api-usage-docs/history-api.md) for the full endpoint reference.
