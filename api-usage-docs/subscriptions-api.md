# Subscriptions API (v2)

The Subscriptions API creates and manages `Subscription` records that connect a source product, a storage destination, and data source credentials (remote identity).

Destinations are products, but they are managed exclusively through the UI. The API supports reading destination records but does not allow creating or updating them.

> **Migrating from v1?** See [Subscriptions API (Legacy v1)](./subscriptions-api-legacy.md). V1 still works - unversioned paths are legacy aliases for it - but its responses now include a `Deprecation` header. V2 is recommended for all new integrations. V2 returns a smaller subscription representation and replaces clunky `Subscription Product Meta` object representation with a more streamlined `Product Parameters`.

---

## Base URLs

| API | Base URL |
|---|---|
| Account | `https://account.api.openbridge.io` |
| User | `https://user.api.openbridge.io` |
| Subscriptions | `https://subscriptions.api.openbridge.io` |
| Products (via proxy) | `https://service.api.openbridge.io/service/products` |
| Remote Identity | `https://remote-identity.api.openbridge.io` |

All Subscriptions API endpoints below are prefixed `/v2`.

---

## Prerequisites

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

Before creating a subscription you will need your **account ID**, **user ID**, a **source product ID**, the **ID of an existing remote identity** (for source products that connect to a third-party data source), and the **ID of an existing storage destination**.

### Get Account ID and User ID

See [Account and User API](./account-user-api.md) for the endpoints that return your account ID and user ID. Use the `id` field from each response as `account` and `user` respectively in subscription requests.

---

## Endpoints

### List Products

Returns all active products. Use the `id` field as the `product` value when creating a subscription.

```
GET https://subscriptions.api.openbridge.io/v2/product
```

Common query filters:

- `is_storage_product={0|1}` — `1` for destination products, `0` for source products
- `remote_identity_type={id}` — filter by required remote identity type
- `active={0|1}` — defaults to `1`

---

### Get Product

Returns a single product by ID.

```
GET https://subscriptions.api.openbridge.io/v2/product/{product_id}
```

See the [Products API](./products-api.md) for full field reference, query filters, and example responses.

---

### Get Product Payload Definitions

For source products, retrieve payload definitions to find valid `stage_id` values. These are required in the `stage_ids` product parameter and in History API requests. This is a separate call to the service API — it is not part of the Subscriptions API and is not versioned.

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

See the [Products API](./products-api.md) for full details on payload definitions.

---

### List Remote Identities

Remote identities represent the data source credentials (OAuth tokens, service account keys, etc.) that authorize Openbridge to pull data on your behalf. They are created and authorized through the Openbridge UI — you cannot create them via the API. This is a separate, unversioned service.

```
GET https://remote-identity.api.openbridge.io/ri
```

Use the `id` from the matching record as `remote_identity` when creating a subscription. Most source products also require this same ID to be passed as the `remote_identity_id` product parameter (as a string value).

> **Note:** Not all products require a remote identity. Destination products and source products that do not connect to a third-party data source do not use this field.

---

### List Storage Destinations

Destinations are read-only via the API; create and manage them in the UI.

```
GET https://subscriptions.api.openbridge.io/v2/storages?status=active
```

Use the destination's `id` as `storage_group` when creating a source subscription. Each returned subscription uses the smaller v2 subscription representation described below.

---

### Create Subscription

```
POST https://subscriptions.api.openbridge.io/v2/sub
```

Both v1 and v2 reject subscription creation for an inactive product, and reject a status change that reactivates a subscription when its existing (or replacement) product is inactive.

**Example — source product with `stage_ids` and `remote_identity_id`:**

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 123,
      "user": 321,
      "product": 79,
      "name": "My Subscription",
      "status": "active",
      "date_start": "2024-01-01T00:00:00Z",
      "date_end": "2024-01-01T00:00:00Z",
      "remote_identity": 7460,
      "storage_group": "1688",
      "product_parameters": {
        "stage_ids": "[1000]"
      }
    }
  }
}
```

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  --data @subscription.json \
  "https://subscriptions.api.openbridge.io/v2/sub"
```

**`product_parameters` pattern:**

`product_parameters` replaces the v1 `subscription_product_meta_attributes` row array with a flat key/value object. Keys become parameter names and values are stored as strings. JSON-looking and numeric-looking values are returned verbatim as their stored strings and should be parsed client-side when needed. `data_format` and other row-level bookkeeping (`data_id`, `product`) are inferred internally and no longer sent by the client.

`stage_ids` is required for source products that use pipeline stages. Unlike v1, `remote_identity_id` does not need to be set in `product_parameters`. Set remote identity via the top-level `remote_identity` field instead, and the API copies it into the internal parameter row automatically when needed (see [Remote identity reconciliation](#remote-identity-reconciliation) below). Additional keys are product-specific. Consult the product's documentation for the full list.

---

### Get Subscription

```
GET https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
```

```json
{
  "data": {
    "type": "Subscription",
    "id": "107003",
    "attributes": {
      "status": "active",
      "date_start": "2025-07-21T11:35:27",
      "created_at": "2026-02-24T15:34:47.986089",
      "modified_at": "2026-02-24T15:36:46.172014",
      "name": "My Snowflake Oauth",
      "invalidated_at": null,
      "account_id": 123,
      "product_id": 79,
      "subproduct_id": "default",
      "remote_identity_id": 7460,
      "storage_group_id": 1688,
      "multi_storage_parent_id": null,
      "user_id": 321
    }
  }
}
```


Returns a single subscription record by ID, using the smaller v2 representation (see [Field Reference](#field-reference)).

---

### List Subscriptions

```
GET https://subscriptions.api.openbridge.io/v2/sub
```

Supported filters: `id`, `name`, `status`, `status__not` (e.g. `status__not=invalid`), `date_start`, `created_at`, `modified_at`, `invalidated_at`, and account, product, product-plan, storage-group, user, or remote-identity IDs (e.g. `account={account_id}`, `product={product_id}`). V1-only filters (`price`, `date_end`, `auto_renew`, `quantity`, `stripe_subscription_id`, `rabbit_payload_successful`, `primary_job_id`, `pipeline`, `invalid_subscription`, `notified_at`) are not available in v2.

---

### Update Subscription

Partial update. All fields are optional.

```
PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
```

`product_parameters` on update is a **partial merge**, not a replacement:

- Omitted keys keep their stored value.
- Supplied keys replace their stored value after validation.
- An omitted or empty `product_parameters` object does not clear the existing parameter set.
- The subscription and its parameter updates run in one database transaction.
- The legacy `subscription_product_meta_attributes` attribute is rejected.

**Example — update `stage_ids` without touching other stored parameters:**

```json
{
  "data": {
    "type": "Subscription",
    "id": "{subscription_id}",
    "attributes": {
      "product_parameters": {
        "stage_ids": "[1000]"
      }
    }
  }
}
```

General parameter-set replacement and general `null`-to-delete behavior are not supported. Remote identity has its own explicit clearing behavior, described next.

#### Remote identity reconciliation

V1 consumers may encounter remote identity in both the subscription and an SPM row. V2 treats the top-level subscription field as canonical, while still maintaining the legacy `remote_identity_id` SPP row internally for backend compatibility.

Create and update accept remote identity in any of these locations:

- `data.attributes.remote_identity`
- `data.attributes.remote_identity_id`
- `data.attributes.product_parameters.remote_identity_id`

Behavior:

- Supplying the value in one location sets both the subscription foreign key and its internal SPP row.
- Supplying it in multiple locations is allowed only when all values identify the same remote identity (integer and equivalent numeric-string forms compare equal).
- Conflicting values return `400` and change nothing.
- The identity must exist, be owned by or shared with the authenticated account, be valid, and match the product's configured remote-identity type when one is configured.
- Remote identity is revalidated only when the request explicitly supplies or clears it — an unrelated update (e.g. a status-only PATCH) does not fail because an existing identity has since become invalid.
- Setting a supported remote-identity input to `null` clears it, but only when the product does not require remote identity. Required identities cannot be cleared.
- Responses expose the value as `remote_identity_id`; the write field `remote_identity` is never returned. The derived SPP row is not exposed in `GET /v2/spp` or `/v2/spp/bulk` attributes.

Preferred request form:

```json
{
  "data": {
    "type": "Subscription",
    "id": "{subscription_id}",
    "attributes": {
      "remote_identity": 7460
    }
  }
}
```

---

### Subscription Product Parameters (SPP)

V2 renames the public concept from **subscription product metadata (SPM)** to **subscription product parameters (SPP)**. `/v1/spm` routes do not exist in v2 — use `/v2/spp`.

#### Read parameters for one subscription

Returns a single aggregate resource whose ID is the subscription ID (not a paginated list of rows like v1's `/spm`):

```
GET https://subscriptions.api.openbridge.io/v2/spp?subscription_id={subscription_id}
```

```json
{
  "data": {
    "type": "SubscriptionProductParameters",
    "id": "48",
    "attributes": {
      "stage_ids": "[1000]",
      "remote_identity_id": "7460"
    }
  }
}
```

- `subscription_id` is required and exact; row-level filters from v1 (`subscription`, `subscription__in`, `product`, `data_id`, `data_key`, `data_value`) do not apply here.
- Missing or invalid `subscription_id` returns `400`; a missing or unauthorized subscription returns `404`.
- A subscription without parameters returns `200` with an empty `attributes` object.
- The internally derived `remote_identity_id` parameter is included for backward compatibility with subscription's `remote_identity_id` attribute.

#### Read parameters for multiple subscriptions

```
GET https://subscriptions.api.openbridge.io/v2/spp/bulk?subscription_ids={id1},{id2}
```

```json
{
  "data": [
    {
      "type": "SubscriptionProductParameters",
      "id": "123",
      "attributes": {
        "profile_id": "1234567890",
        "aws_iam_role_arn": "arn:aws:iam::1234567890:role/openbridge-customer-cloudformation",
        ...
      },
    {
      "type": "SubscriptionProductParameters",
      "id": "234",
      "attributes": {
        "snowflake_database": "DATABASE",
        "snowflake_warehouse": "FOOBAR",
        ...
      }
    }
  ]
}
```

Accepts 1 to 100 unique, comma-separated positive subscription IDs and returns resources in the requested order. The request is all-or-nothing: if any subscription is missing or inaccessible, the entire request returns `404` (the error detail lists all unresolved IDs). Subscriptions without parameters still appear with empty `attributes`.

**Example: 404**
```json
{
  "errors": [
    {
      "detail": "Subscriptions were not found or are not accessible: 123456,654321"
    }
  ]
}
```

#### Create a parameter row

```
POST https://subscriptions.api.openbridge.io/v2/spp
```

> **Note:** Calling this endpoint directly is typically not necessary. The general way to add or set product parameters is via `product_parameters` on `POST /v2/sub` (create) or `PATCH /v2/sub/{subscription_id}` (partial-merge update). See [Create Subscription](#create-subscription) and [Update Subscription](#update-subscription) for more information.

```json
{
  "data": {
    "type": "SubscriptionProductParameter",
    "attributes": {
      "data_key": "stage_ids",
      "data_value": "[1000]",
      "subscription": 48
    }
  }
}
```

Requires exactly a non-empty string `data_key`, a present string `data_value` (may be empty), and a positive `subscription` ID. Inferred fields (`product`, `product_id`, `subscription_id`, `data_id`, `data_format`) and unknown attributes are rejected with `400` — the old plural row type is not accepted as an alias, and product/data ID/format are computed server-side. A duplicate key within the subscription returns `409` without changing the existing row. `remote_identity_id` cannot be created here — use subscription `PATCH` instead.

Example response:

```json
{
  "data": {
    "type": "SubscriptionProductParameter",
    "id": "901",
    "attributes": {
      "data_key": "stage_ids",
      "data_value": "[1000]",
      "subscription_id": 48,
      "product_id": 79,
      "created_at": "2026-08-04T14:30:00Z",
      "modified_at": "2026-08-04T14:30:00Z"
    }
  }
}
```

---

## Field Reference

### Subscription — readable attributes

| Field | Type | Description |
|---|---|---|
| `id` | integer | Subscription ID |
| `status` | enum | One of: `active`, `cancelled`, `paused`, `invalid` |
| `name` | string \| null | Human-readable label for the subscription |
| `date_start` | datetime | Subscription start date (ISO 8601) |
| `created_at` | datetime | Record creation time |
| `modified_at` | datetime | Record last-modified time |
| `invalidated_at` | datetime \| null | Time the subscription was cancelled/invalidated |
| `account_id` | integer \| null | Reference to the owning account |
| `product_id` | integer \| null | Reference to the product |
| `remote_identity_id` | integer \| null | Reference to the connected data source credential |
| `storage_group_id` | integer \| null | Reference to the storage destination |
| `user_id` | integer \| null | Reference to the user |

### Subscription — write-only attributes

| Field | Type | Required | Description |
|---|---|---|---|
| `account` | integer | Yes (create) | Account ID (from `GET /account`) |
| `user` | integer | Yes (create) | User ID (from `GET /user`) |
| `product` | integer | Yes (create) | Product ID (from `GET /v2/product`) |
| `status` | enum | Yes (create) | One of: `active`, `cancelled`, `paused`, `invalid` |
| `date_start` | datetime | Yes (create) | Subscription start date (ISO 8601) |
| `date_end` | datetime | No | Accepted on write; never returned |
| `remote_identity` | integer | No | ID of the connected data source credential (canonical input — see [reconciliation](#remote-identity-reconciliation)) |
| `storage_group` | integer | No | ID of the storage destination (from `GET /v2/storages`) |
| `product_parameters` | object | No* | Product-specific configuration; flat key/value map |

\* Required for source products. Destination products do not use this field.

The following v1 response fields are **not present** in v2 and should not be sent on write: `price`, `auto_renew`, `quantity`, `stripe_subscription_id`, `rabbit_payload_successful`, `primary_job_id`, `pipeline`, `invalid_subscription`, `notified_at`, `canonical_name`, `history_requested`, `unique_hash`, `product_plan`, `product_plan_id`.

### SubscriptionProductParameters (aggregate — GET `/v2/spp`, `/v2/spp/bulk`)

| Field | Type | Description |
|---|---|---|
| `id` | string | The subscription ID |
| `attributes` | object | Flat map of `data_key` → `data_value` for the subscription |
