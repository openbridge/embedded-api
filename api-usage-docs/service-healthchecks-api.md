# Service API: Healthchecks

## When to use

Use this endpoint to retrieve healthcheck records for your account's subscriptions. Healthcheck records surface the most recent execution status for each subscription — use them to monitor whether subscriptions are running successfully or encountering errors.

---

## Prerequisites

- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).
- The `account_id` in the request path must match the account ID encoded in your JWT. Requests for any other account ID are rejected with `403 Forbidden`.

---

## Endpoint

### List healthchecks for an account

```
GET /service/healthchecks/{environment}/healthchecks/account/{account_id}
```

| Path parameter | Description |
|---|---|
| `environment` | `dev` or `production` |
| `account_id` | Your Openbridge account ID. Must match the account ID in your JWT. |

**Example request**

```http
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/3558
Authorization: Bearer <jwt>
```

---

## Query parameters

Results can be filtered by any of the fields below using Django filter lookup suffixes (`__exact`, `__gte`, `__lte`, `__gt`, `__lt`, `__contains`, `__icontains`). Omit the suffix to use exact matching.

**Ordering** — pass `order_by` as a comma-separated list of field names. Prefix a field name with `-` for descending order (e.g. `order_by=-modified_at`).

### Filter fields

| Field | Supported lookups | Description |
|---|---|---|
| `id` | `exact`, `gt`, `gte`, `lt`, `lte` | Healthcheck record ID |
| `modified_at` | `exact`, `gt`, `gte`, `lt`, `lte` | Timestamp the record was last modified |
| `hc_runtime` | `exact`, `gt`, `gte`, `lt`, `lte` | Timestamp the healthcheck ran |
| `status` | `exact` | Health check status (e.g. `OK`, `ERROR`) |
| `subscription_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Openbridge subscription ID |
| `subscription_name` | `exact`, `contains`, `icontains` | Subscription display name |
| `product_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Product ID |
| `subproduct_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Sub-product ID |
| `product_name` | `exact`, `contains`, `icontains` | Product display name |
| `payload_name` | `exact`, `contains`, `icontains` | Payload/table name |
| `job_id` | `exact`, `gt`, `gte`, `lt`, `lte` | Associated job ID |
| `storage_id` | `exact`, `contains`, `icontains` | Storage destination ID |
| `message` | `exact`, `contains`, `icontains` | Health check message |
| `err_msg` | `exact`, `contains`, `icontains` | Error message text |
| `owner` | `exact`, `contains`, `icontains` | Owner identifier |
| `sender` | `exact` | Sender identifier (ex. `supervisor`, `zeroadmin`) |

**Example: errors since a date**

```http
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/3558?status=ERROR&modified_at__gte=2024-01-01%2000%3A00%3A00
Authorization: Bearer <jwt>
```

**Example: filter by subscription, ordered by most recent**

```http
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/3558?subscription_id=12345&order_by=-modified_at
Authorization: Bearer <jwt>
```

---

## Response

Results are returned as a paginated JSON:API response.

**Response fields**

| Field | Type | Description |
|---|---|---|
| `id` | integer | Healthcheck record ID |
| `account_id` | integer | Openbridge account ID |
| `subscription_id` | integer | Associated subscription ID |
| `subscription_name` | string | Subscription display name |
| `product_id` | integer | Product ID |
| `subproduct_id` | integer | Sub-product ID |
| `product_name` | string | Product display name |
| `payload_name` | string | Payload/table name |
| `storage_id` | string | Storage destination ID |
| `status` | string | Health check status (`OK`, `ERROR`, etc.) |
| `message` | string | Health check message |
| `err_msg` | string | Error message if status is `ERROR` |
| `error_code` | string | Error code if applicable |
| `hc_runtime` | datetime | When the healthcheck ran |
| `modified_at` | datetime | When this record was last updated |
| `job_id` | integer | Associated job ID |
| `transaction_id` | string | Pipeline transaction ID |
| `file_path` | string | File path associated with the check |
| `owner` | string | Owner identifier |
| `sender` | string | Sender identifier |
| `company` | string | Company name |
| `email_address` | string | Email address |

---

## Authorization enforcement

The service API validates that the `account_id` path parameter matches the account ID in your JWT before forwarding the request. There is no way to retrieve healthchecks for a different account, even with a valid token.
