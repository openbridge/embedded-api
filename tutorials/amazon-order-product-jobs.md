# Creating Amazon Order Product Jobs

## Table of Contents

- [Overview](#overview)
- [When to use product jobs](#when-to-use-product-jobs)
- [Prerequisites](#prerequisites)
- [Step 1 — Find the primary job ID](#step-1--find-the-primary-job-id)
- [Step 2 — Find the stage ID](#step-2--find-the-stage-id)
- [Step 3 — Prepare your order IDs](#step-3--prepare-your-order-ids)
  - [Inline list](#inline-list)
  - [CSV file](#csv-file)
- [Step 4 — Build the product job payload](#step-4--build-the-product-job-payload)
  - [Product job fields](#product-job-fields)
  - [Scheduling and staggering](#scheduling-and-staggering)
- [Step 5 — POST the product job](#step-5--post-the-product-job)
- [Batch processing with multiple requests](#batch-processing-with-multiple-requests)
  - [Batching rules](#batching-rules)
  - [Example — 250 orders in 3 batches](#example--250-orders-in-3-batches)
- [Using the CLI](#using-the-cli)

---

## Overview

Amazon Seller products on Openbridge process data at the subscription level — the pipeline runs on a schedule and collects all available data. But some Amazon workflows require data for specific order IDs rather than a broad collection run. Product jobs let you attach a list of Amazon order IDs to a job, telling the pipeline to process data specifically for those orders.

This is a specialized operation tied to a primary (parent) job. You create a secondary job under the primary, passing order IDs in the `extra_context` field. The pipeline then processes only the data related to those orders.

---

## When to use product jobs

- **Order-level data retrieval** — you need data for specific Amazon orders, not the entire account
- **Targeted re-processing** — certain orders failed or have incomplete data and you want to re-request just those
- **Bulk order processing** — you have a list of order IDs (from a report, a support ticket, or an internal system) and need Openbridge to process them

---

## Prerequisites

All API calls require a JWT access token. Obtain one by exchanging your refresh token with the [Authentication API](../api-usage-docs/authentication-api.md).

You will need:
- The **primary job ID** for an existing job on the subscription (the parent job that the product job will be created under)
- A **stage ID** for the Amazon Seller product (defaults to `1000` if not specified)
- One or more **Amazon order IDs** in the format `###-#######-#######`

---

## Step 1 — Find the primary job ID

List jobs for the subscription to find a primary job:

```
GET https://service.api.openbridge.io/service/jobs/jobs?subscription_ids={subscription_id}
```

Look for a job where `is_primary` is `true`. Use its `id` as the parent for your product job.

You can filter further by stage:

```
GET https://service.api.openbridge.io/service/jobs/jobs?subscription_ids={subscription_id}&stage_id={stage_id}
```

See the [Jobs API](../api-usage-docs/jobs-api.md) for all available query filters.

---

## Step 2 — Find the stage ID

If you don't already know the stage ID for the dataset you want, look it up from the product's payload definitions:

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

For Amazon Orders API (product `53`), the response will list the available stages and their names. Use the `stage_id` value for the dataset you need.

---

## Step 3 — Prepare your order IDs

Order IDs must be in Amazon's standard format: `###-#######-#######` (three groups of digits separated by hyphens).

### Inline list

For a small number of orders, pass them directly:

```
113-3282521-2385810,112-8345146-1897812,113-3282522-2385808
```

### CSV file

For larger sets, use a CSV file with a header row:

```
order_id
113-3282521-2385810
112-8345146-1897812
113-3282522-2385808
112-8345147-1897803
112-3767086-2904225
111-9720949-8700227
111-0214429-6480225
111-2400059-7724248
```

---

## Step 4 — Build the product job payload

A product job is a secondary `Job` record created under a primary job. The order IDs are passed as a stringified JSON object in the `extra_context` field.

### Product job fields

| Field | Type | Description |
|---|---|---|
| `is_primary` | boolean | Always `false` — this is a secondary job |
| `valid_date_start` | string (`YYYY-MM-DD`) | Start date for the job's validity window |
| `valid_date_end` | string (`YYYY-MM-DD`) | End date for the job's validity window |
| `stage_id` | integer | Pipeline stage to process |
| `extra_context` | string | Stringified JSON containing the order IDs |
| `request_start` | integer | Set to `1` |
| `request_end` | integer | Set to `0` |
| `schedule` | string | Cron expression for when the job should run |

**Payload example:**

```json
{
  "data": {
    "type": "Job",
    "attributes": {
      "is_primary": false,
      "valid_date_start": "2024-06-01",
      "valid_date_end": "2024-06-01",
      "stage_id": 1000,
      "extra_context": "{\"order_ids\": [\"113-3282521-2385810\",\"112-8345146-1897812\"]}",
      "request_start": 1,
      "request_end": 0,
      "schedule": "30 14 * * *"
    }
  }
}
```

### Scheduling and staggering

The `schedule` field is a cron expression that tells the pipeline when to process this job. When submitting multiple batches, stagger the schedule by 15 minutes per batch to avoid overloading the pipeline:

- Batch 1: `"30 14 * * *"` (2:30 PM UTC)
- Batch 2: `"45 14 * * *"` (2:45 PM UTC)
- Batch 3: `"00 15 * * *"` (3:00 PM UTC)

Set `valid_date_start` and `valid_date_end` to the same date — typically today's date or a future date that aligns with the schedule.

---

## Step 5 — POST the product job

Create the product job under the primary job:

```
POST https://service.api.openbridge.io/service/jobs/jobs/{primary_job_id}
```

**Example request:**

```json
{
  "data": {
    "type": "Job",
    "attributes": {
      "is_primary": false,
      "valid_date_start": "2024-06-01",
      "valid_date_end": "2024-06-01",
      "stage_id": 1000,
      "extra_context": "{\"order_ids\": [\"113-3282521-2385810\",\"112-8345146-1897812\",\"113-3282522-2385808\"]}",
      "request_start": 1,
      "request_end": 0,
      "schedule": "30 14 * * *"
    }
  }
}
```

On success, the API returns the created job record.

---

## Batch processing with multiple requests

### Batching rules

The `extra_context` field has a practical size limit. Batch order IDs into groups of **100 per request**. For each batch:

1. Take the next 100 order IDs
2. Build the `extra_context` JSON with those IDs
3. Set the `schedule` to 15 minutes after the previous batch
4. POST the job
5. Wait briefly between requests to avoid rate limiting

### Example — 250 orders in 3 batches

Given 250 order IDs, split into:

**Batch 1** (orders 1-100, scheduled at offset +15 min):

```json
{
  "data": {
    "type": "Job",
    "attributes": {
      "is_primary": false,
      "valid_date_start": "2024-06-01",
      "valid_date_end": "2024-06-01",
      "stage_id": 1000,
      "extra_context": "{\"order_ids\": [\"113-3282521-2385810\", ... (100 IDs)]}",
      "request_start": 1,
      "request_end": 0,
      "schedule": "30 14 * * *"
    }
  }
}
```

**Batch 2** (orders 101-200, scheduled at offset +30 min):

```json
{
  "data": {
    "type": "Job",
    "attributes": {
      "is_primary": false,
      "valid_date_start": "2024-06-01",
      "valid_date_end": "2024-06-01",
      "stage_id": 1000,
      "extra_context": "{\"order_ids\": [\"112-8345146-1897812\", ... (100 IDs)]}",
      "request_start": 1,
      "request_end": 0,
      "schedule": "45 14 * * *"
    }
  }
}
```

**Batch 3** (orders 201-250, scheduled at offset +45 min):

```json
{
  "data": {
    "type": "Job",
    "attributes": {
      "is_primary": false,
      "valid_date_start": "2024-06-01",
      "valid_date_end": "2024-06-01",
      "stage_id": 1000,
      "extra_context": "{\"order_ids\": [\"111-9720949-8700227\", ... (50 IDs)]}",
      "request_start": 1,
      "request_end": 0,
      "schedule": "00 15 * * *"
    }
  }
}
```

Each batch is a separate POST to the same `{primary_job_id}` endpoint.

---

## Using the CLI

The `embed-cli` handles batching, scheduling, and CSV parsing automatically.

**Create product jobs from a comma-separated list:**

```bash
embed-cli jobs create-product --job-id 12345 --orders "113-3282521-2385810,112-8345146-1897812,113-3282522-2385808"
```

**Create product jobs from a CSV file:**

```bash
embed-cli jobs create-product --job-id 12345 --file orders.csv
```

**Specify a stage ID (default is 1000):**

```bash
embed-cli jobs create-product --job-id 12345 --stage 1002 --file orders.csv
```

The CLI automatically:
- Validates order ID format (`###-#######-#######`)
- Splits orders into batches of 100
- Staggers each batch's schedule by 15 minutes
- Logs progress for each batch

See the [Jobs API](../api-usage-docs/jobs-api.md) for the full endpoint reference.
