# Monitoring Pipeline Health

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Get your account ID](#step-1--get-your-account-id)
- [Step 2 — Retrieve healthcheck records](#step-2--retrieve-healthcheck-records)
- [Step 3 — Filter results](#step-3--filter-results)
  - [Filter by status](#filter-by-status)
  - [Filter by subscription](#filter-by-subscription)
  - [Filter by date range](#filter-by-date-range)
  - [Combining filters](#combining-filters)
- [Understanding the response](#understanding-the-response)
  - [Healthcheck fields](#healthcheck-fields)
  - [Key fields for diagnosis](#key-fields-for-diagnosis)
- [Common monitoring patterns](#common-monitoring-patterns)
  - [Detect recent errors](#detect-recent-errors)
  - [Check a specific subscription's health](#check-a-specific-subscriptions-health)
  - [Identify subscriptions with identity problems](#identify-subscriptions-with-identity-problems)
- [Responding to issues](#responding-to-issues)
  - [Error status](#error-status)
  - [Invalid identities](#invalid-identities)
  - [Re-requesting failed data](#re-requesting-failed-data)
- [Using the CLI](#using-the-cli)

---

## Overview

Every time Openbridge runs a pipeline job for one of your subscriptions, it produces a healthcheck record. These records tell you whether the job succeeded, failed, or encountered a warning — and include the error details when something goes wrong.

The Healthchecks API gives you a filterable, paginated view of these records for your account. Use it to build monitoring workflows: detect errors, correlate them to subscriptions and jobs, and take corrective action.

---

## Prerequisites

All API calls require a JWT access token. Obtain one by exchanging your refresh token with the [Authentication API](../api-usage-docs/authentication-api.md).

You will need your **account ID**. The healthchecks endpoint requires it in the URL path, and it must match the account ID encoded in your JWT.

---

## Step 1 — Get your account ID

```
GET https://account.api.openbridge.io/account
```

Use the `id` field from the response. See the [Account and User API](../api-usage-docs/account-user-api.md) for details.

---

## Step 2 — Retrieve healthcheck records

```
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/{account_id}
```

This returns a paginated list of healthcheck records for your account, ordered by most recent first by default. Each record represents one pipeline execution result.

**Example request:**

```
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/3558
Authorization: Bearer {your_access_token}
```

Results are paginated. Use `page={n}` and `page_size={n}` to control pagination.

---

## Step 3 — Filter results

The healthchecks endpoint supports Django-style filter lookups on most fields. Append filters as query parameters.

### Filter by status

Show only error records:

```
GET .../account/{account_id}?status=ERROR
```

### Filter by subscription

Show records for a specific subscription:

```
GET .../account/{account_id}?subscription_id=116223
```

### Filter by date range

Show records modified in the last 7 days (use `modified_at__gte` with a date):

```
GET .../account/{account_id}?modified_at__gte=2024-06-01%2000%3A00%3A00
```

The datetime value must be URL-encoded. The format is `YYYY-MM-DD HH:MM:SS`.

### Combining filters

Filters can be combined. Show errors for a specific subscription since a given date:

```
GET .../account/{account_id}?status=ERROR&subscription_id=116223&modified_at__gte=2024-06-01%2000%3A00%3A00
```

**Available filter fields:**

| Field | Supported lookups | Description |
|---|---|---|
| `status` | `exact` | Healthcheck status (`OK`, `ERROR`, etc.) |
| `subscription_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Subscription ID |
| `subscription_name` | `exact`, `contains`, `icontains` | Subscription display name |
| `product_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Product ID |
| `product_name` | `exact`, `contains`, `icontains` | Product display name |
| `modified_at` | `exact`, `gt`, `gte`, `lt`, `lte` | When the record was last updated |
| `hc_runtime` | `exact`, `gt`, `gte`, `lt`, `lte` | When the healthcheck ran |
| `job_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Associated job ID |
| `err_msg` | `exact`, `contains`, `icontains` | Error message text |
| `payload_name` | `exact`, `contains`, `icontains` | Pipeline dataset name |

**Ordering** — use `order_by` with a field name. Prefix with `-` for descending:

```
GET .../account/{account_id}?order_by=-modified_at
```

---

## Understanding the response

### Healthcheck fields

| Field | Type | Description |
|---|---|---|
| `id` | integer | Healthcheck record ID |
| `subscription_id` | integer | The subscription this check belongs to |
| `subscription_name` | string | Subscription display name |
| `product_id` | integer | Product ID |
| `product_name` | string | Product display name |
| `payload_name` | string | The specific dataset/table name |
| `status` | string | Result status (`OK`, `ERROR`, `IN_PROGRESS`, etc.) |
| `message` | string | Status message |
| `err_msg` | string | Error details (when `status` is `ERROR`) |
| `error_code` | string | Structured error code (when applicable) |
| `hc_runtime` | datetime | When the healthcheck ran |
| `modified_at` | datetime | When this record was last updated |
| `job_id` | integer | The job ID that produced this healthcheck |
| `storage_id` | string | Storage destination identifier |
| `transaction_id` | string | Pipeline transaction ID |

### Key fields for diagnosis

When investigating an issue, focus on:

- **`status`** — tells you if the job succeeded or failed
- **`err_msg`** — the error message explaining what went wrong
- **`subscription_id`** + **`product_name`** — which pipeline had the problem
- **`payload_name`** — which specific dataset within the product failed
- **`job_id`** — allows you to look up the job record via the [Jobs API](../api-usage-docs/jobs-api.md)
- **`hc_runtime`** — when the check occurred, useful for correlating with external events

---

## Common monitoring patterns

### Detect recent errors

Query for errors in the last 7 days, ordered by most recent:

```
GET .../account/{account_id}?status=ERROR&modified_at__gte=2024-06-18%2000%3A00%3A00&order_by=-modified_at
```

This is the most common monitoring query. Run it on a schedule to detect failures early.

### Check a specific subscription's health

After creating or modifying a subscription, check its recent healthchecks:

```
GET .../account/{account_id}?subscription_id=116223&order_by=-modified_at&page_size=10
```

If the most recent records show `OK` status, the subscription is healthy.

### Identify subscriptions with identity problems

When an identity becomes invalid (expired credentials, revoked access), all subscriptions using that identity will start producing errors. Look for patterns in `err_msg`:

```
GET .../account/{account_id}?status=ERROR&err_msg__icontains=unauthorized&order_by=-modified_at
```

Or check the identity directly:

```
GET https://remote-identity.api.openbridge.io/sri?invalid_identity=1
```

If the identity appears in the invalid list, re-authorize it using the flow in [Identity Configuration](./identity-configuration.md#reauthorizing-an-existing-identity).

---

## Responding to issues

### Error status

When you see `ERROR` records:

1. Read the `err_msg` to understand the failure
2. Check whether the error is transient (rate limit, timeout) or permanent (invalid credentials, missing permissions)
3. For transient errors, Openbridge typically retries automatically — check if later healthchecks for the same subscription show `OK`
4. For permanent errors, fix the root cause, then re-request the affected dates using the [History API](./history-backfill.md)

### Invalid identities

Identities are checked every 24 hours. If credentials are revoked or expire:

1. Check for invalid identities: `GET /sri?invalid_identity=1`
2. Re-authorize the identity using the OAuth flow (see [Identity Configuration](./identity-configuration.md#reauthorizing-an-existing-identity))
3. After re-authorization, re-request any failed dates using the History API

If you are reselling Openbridge to end customers, detection and re-authorization notification is your responsibility — Openbridge has no direct channel to your customers.

### Re-requesting failed data

Once the root cause is fixed, create a history transaction for the affected date range:

```
POST https://service.api.openbridge.io/service/history/production/history/{subscription_id}
```

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "start_date": "2024-06-01",
      "end_date": "2024-06-07"
    }
  }
}
```

See [Requesting Historical Data](./history-backfill.md) for the full walkthrough.

---

## Using the CLI

The `embed-cli` provides shorthand commands for healthcheck queries.

**Get all healthchecks (first page):**

```bash
embed-cli health check
```

**Filter by status:**

```bash
embed-cli health check --status healthy
```

**Filter by subscription:**

```bash
embed-cli health check --subscription 116223
```

**Show records from the last 7 days:**

```bash
embed-cli health check --last-days 7
```

**Combine filters:**

```bash
embed-cli health check --status unhealthy --last-days 3 --page-size 50
```

The CLI automatically resolves your account ID from the User API before making the healthcheck request.

See [Service API: Healthchecks](../api-usage-docs/service-healthchecks-api.md) for the full endpoint reference.
