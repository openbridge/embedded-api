# History API

The History API creates and manages `HistoryTransaction` records that trigger historical data retrieval runs for a given subscription and date range.

---

## Base URLs

| API | Base URL |
|---|---|
| History | `https://service.api.openbridge.io/service/history/production/history` |
| Subscriptions | `https://subscriptions.api.openbridge.io` |
| Products (via proxy) | `https://service.api.openbridge.io/service/products` |

---

## Prerequisites

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

Before calling the History API you will need a **subscription ID** and, optionally, a **product ID** and **stage ID**. Use the calls below to look these up.

### Get Subscription ID

Returns subscriptions for your account. Use the `id` field as `subscription_id` in History API requests.

```
GET https://subscriptions.api.openbridge.io/sub?account={account_id}
```

### Get Product ID and Stage ID

See [Products API](./products-api.md) for the endpoints that return available products and their payload definitions. Use the product `id` as `product_id` and the payload `stage_id` values in History API requests.

---

## Endpoints

### Create History Transaction

Triggers a historical data retrieval run for a subscription over the specified date range.

```
POST https://service.api.openbridge.io/service/history/production/history/{subscription_id}
```

**Minimal request** — date range only:

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

**With optional fields** — specify a product, stage, and start time:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "product_id": 85,
      "start_date": "2024-04-01",
      "end_date": "2024-04-01",
      "stage_id": 1000,
      "start_time": "2024-07-01 13:40:00"
    }
  }
}
```

**With a `dates` array** — pass specific non-contiguous dates instead of a range:

```json
{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "dates": ["2025-09-10", "2024-09-09"],
      "stage_id": 1000,
      "start_time": "2025-09-11 14:00:00"
    }
  }
}
```

---

### Get History Transaction by ID

Returns a single `HistoryTransaction` record by its own ID.

```
GET https://service.api.openbridge.io/service/history/production/history/{transaction_id}
```

---

### Get Transaction Status by Subscription

Returns transaction status records associated with the given subscription.

```
GET https://service.api.openbridge.io/service/history/production/history/status/{subscription_id}
```

---

### Update Transaction Status

Updates the status of a specific transaction. The primary use case is cancellation.

```
PATCH https://service.api.openbridge.io/service/history/production/history/status/{transaction_id}
```

**Request body:**

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

### Get Max Request Metadata

Returns the maximum number of history requests permitted.

```
GET https://service.api.openbridge.io/service/history/production/history/meta/max-request
```

---

## Field Reference

These fields are used in `HistoryTransaction` request bodies.

| Field | Type | Required | Description |
|---|---|---|---|
| `start_date` | string (`YYYY-MM-DD`) | Yes* | Start of the date range to retrieve history for. Required when `dates` is not provided. |
| `end_date` | string (`YYYY-MM-DD`) | Yes* | End of the date range. Required when `dates` is not provided. |
| `dates` | array of strings | Yes* | List of specific dates to retrieve history for. Use instead of `start_date`/`end_date`. |
| `product_id` | integer | No | ID of the product within the subscription to run history for. Obtained from the Products API. |
| `stage_id` | integer | No | Filters history retrieval to a specific pipeline stage. Obtained from the product's payload definitions. |
| `start_time` | string (`YYYY-MM-DD HH:MM:SS`) | No | Datetime from which processing should begin within the given date range. |
| `status` | string | No | Transaction status. Accepted value for updates: `cancelled`. |

\* Either `dates` or both `start_date` and `end_date` must be provided.
