# Service API: Product Cards

## When to use

Use these endpoints to retrieve product metadata and full product definitions from the Openbridge product catalog. The list endpoint returns lightweight records suitable for rendering product pickers or checking available payloads. The detail endpoint returns the complete product definition including scheduling configuration, history settings, and stage/payload mappings.

---

## Prerequisites

- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### List all active products

```
GET /service/product-cards/card
```

Returns minimal metadata for every active product, including the list of payload names associated with each.

**Example request**

```http
GET https://service.api.openbridge.io/service/product-cards/card
Authorization: Bearer <jwt>
```

**Response**

An array of product objects.

| Field | Type | Description |
|---|---|---|
| `id` | integer | Product ID |
| `name` | string | Product display name |
| `summary` | string | Brief tagline shown alongside the product name |
| `payloads` | array of strings | Names of the payloads (stages) available for this product |

**Example response**

```json
[
  {
    "id": 95,
    "name": "Shopify",
    "summary": "Operations insights for merchant orders, returns, customers, shipments, and many more",
    "payloads": ["sg_orders", "sg_customers", "sg_products"]
  },
]
```

---

### Get a product definition

```
GET /service/product-cards/card/{product_id}
```

Returns the full JSON definition for a single product.

| Path parameter | Description |
|---|---|
| `product_id` | Integer ID of the product |

**Example request**

```http
GET https://service.api.openbridge.io/service/product-cards/card/95
Authorization: Bearer <jwt>
```

**Response**

A single product definition object. Returns `404` if the product ID does not exist.

#### Top-level fields

| Field | Type | Description |
|---|---|---|
| `id` | integer | Product ID |
| `product_group_id` | integer | Foreign key to the product group |
| `name` | string | Product display name (e.g. `"Shopify"`) |
| `summary` | string | Brief tagline shown alongside the product name |
| `description` | string or null | Extended description of the product |
| `worker_name` | string or null | Identifier of the worker process that handles data collection for this product. `null` for storage products |
| `remote_identity_type_name` | string or null | Human-readable name of the OAuth/identity provider required to connect (e.g. `"Shopify Oauth"`) |
| `remote_identity_type_id` | integer or null | Foreign key to the remote identity type. `null` if no remote identity is required |
| `is_storage_product` | 0 or 1 | `1` if this is a destination/storage product (e.g. Snowflake, BigQuery) |
| `active` | 0 or 1 | `1` if the product is active and visible to users |
| `allow_as_trial` | 0 or 1 | `1` if this product can be configured on trial accounts |
| `premium_product` | 0 or 1 | `1` if this is a premium product |
| `initialize_job` | 0 or 1 | `1` if a job record should be initialized for new subscriptions |

#### `subscription_info`

Specifies which subscription product meta keys a subscription must supply. `null` if the product has no meta requirements.

| Field | Type | Description |
|---|---|---|
| `spm_requirements` | array of strings | Meta keys that must be present on each subscription (e.g. `["snowflakeSchema", "snowflakeDatabase"]`) |

#### `backend_info`

An array of job scheduling records, one per subproduct stream. `null` or `[]` for storage products.

| Field | Type | Description |
|---|---|---|
| `subproduct_id` | string | Identifier for this data stream within the product. `"default"` for single-stream products |
| `worker_name` | string | Worker name for this specific job |
| `job_type` | string | Scheduling cadence type (typically `"daily"`) |
| `base_schedule_start` | string or null | Cron expression for when the job window opens each day |
| `base_schedule_end` | string or null | Cron expression for when the job window closes |
| `base_request_start` | integer or null | Days ago to start the first data request for a new subscription |
| `num_days` | integer or null | Number of days of data each job run requests. Mutually exclusive with `days_list` |
| `days_list` | array of integers or null | Explicit list of day offsets to request instead of a rolling window |
| `num_stages` | integer or null | Number of parallel data fetch stages. Mutually exclusive with `stage_list` |
| `stage_list` | array of integers or null | Explicit list of stage IDs to use |

#### `history_info`

An array of historical data configuration records, one per stage per subproduct. `null` for storage products.

| Field | Type | Description |
|---|---|---|
| `stage_id` | integer | The stage this record applies to. Stage IDs ≥ 1000 correspond to named stages |
| `subproduct_id` | string | Must match a `subproduct_id` from `backend_info` |
| `days` | integer | Maximum number of days of history that can be requested for this stage |
| `schedule_offset` | integer or null | Offset in minutes applied to the job schedule for this stage |
| `max_request_time` | integer | Maximum age in days of a single data request for this stage |

#### `stages`

An array of named pipeline stages (payloads) associated with this product. `null` for storage products or products without named stages.

| Field | Type | Description |
|---|---|---|
| `name` | string | Payload/stage name (e.g. `"sg_orders"`) |
| `stage_id` | integer | Numeric ID for this stage. Must be ≥ 1000 |
| `restricted_to` | array of strings or null | If set, subscriptions must match one of the listed values to access this stage. `null` means available to all |

**Example response**

```json
{
  "id": 95,
  "product_group_id": 1,
  "name": "Shopify",
  "summary": "Shopify GraphQL",
  "description": null,
  "worker_name": "shopify_gql",
  "remote_identity_type_name": "Shopify Oauth",
  "remote_identity_type_id": 12,
  "is_storage_product": 0,
  "active": 1,
  "allow_as_trial": 1,
  "premium_product": 0,
  "initialize_job": 1,
  "subscription_info": null,
  "backend_info": [
    {
      "subproduct_id": "default",
      "worker_name": "shopify",
      "job_type": "daily",
      "base_schedule_start": "0 0 * * *",
      "base_schedule_end": null,
      "num_days": 1,
      "days_list": null,
      "base_request_start": 1,
      "num_stages": null,
      "stage_list": [0]
    }
  ],
  "history_info": [
    {
      "stage_id": 1000,
      "subproduct_id": "default",
      "days": 365,
      "schedule_offset": 15,
      "max_request_time": 364
    }
  ],
  "stages": [
    { "name": "sg_orders", "stage_id": 1004, "restricted_to": null },
    { "name": "sg_customers", "stage_id": 1001, "restricted_to": ["premium"] }
  ]
}
```

---

## Error responses

| Status | Description |
|---|---|
| `404` | Product not found |
| `500` | Internal server error — response body contains an `"error"` string with details |
