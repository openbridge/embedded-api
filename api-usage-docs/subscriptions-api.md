# Subscriptions API

The Subscriptions API creates and manages `Subscription` records that connect a source product, a storage destination, and data source credentials (remote identity).

Destinations are products, but they are managed exclusively through the UI. The API supports reading destination records but does not allow creating or updating them.

---

## Base URLs

| API | Base URL |
|---|---|
| Account | `https://account.api.openbridge.io` |
| User | `https://user.api.openbridge.io` |
| Subscriptions | `https://subscriptions.api.openbridge.io` |
| Products (via proxy) | `https://service.api.openbridge.io/service/products` |
| Remote Identity | `https://remote-identity.api.openbridge.io` |

---

## Prerequisites

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

Before creating a subscription you will need your **account ID**, **user ID**, a **source product ID**, the **ID of an existing remote identity** (for source products that connect to a third-party data source), and the **ID of an existing storage destination**.

### Get Account ID and User ID

See [Account and User API](./account-api.md) for the endpoints that return your account ID and user ID. Use the `id` field from each response as `account` and `user` respectively in subscription requests.

---

## Endpoints

### List Products

Returns all active products. Use the `id` field as the `product` value when creating a subscription.

```
GET https://subscriptions.api.openbridge.io/product
```

Common query filters:

- `is_storage_product={0|1}` — `1` for destination products, `0` for source products
- `remote_identity_type={id}` — filter by required remote identity type
- `active={0|1}` — defaults to `1`

---

### Get Product

Returns a single product by ID.

```
GET https://subscriptions.api.openbridge.io/product/{product_id}
```

See the [Products API](./products-api.md) for full field reference, query filters, and example responses.

---

### Get Product Payload Definitions

For source products, retrieve payload definitions to find valid `stage_id` values. These are required in the `stage_ids` subscription meta attribute and in History API requests. This is a separate call to the service API — it is not part of the Subscriptions API.

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

See the [Products API](./products-api.md) for full details on payload definitions.

---

### List Remote Identities

Remote identities represent the data source credentials (OAuth tokens, service account keys, etc.) that authorize Openbridge to pull data on your behalf. They are created and authorized through the Openbridge UI — you cannot create them via the API.

```
GET https://remote-identity.api.openbridge.io/ri
```

Use the `id` from the matching record as `remote_identity` in the subscription request. Most source products also require this same ID to be passed as the `remote_identity_id` meta attribute (as a string value).

> **Note:** Not all products require a remote identity. Destination products and source products that do not connect to a third-party data source do not use this field.

---

### List Storage Destinations

Destinations are read-only via the API; create and manage them in the UI.

```
GET https://subscriptions.api.openbridge.io/storages?status=active
```

Use the destination's `id` as `storage_group` when creating a source subscription.

---

### Create Subscription

```
POST https://subscriptions.api.openbridge.io/sub
```

**Example — source product with `stage_ids` and `remote_identity_id`:**

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": "{account_id}",
      "user": "{user_id}",
      "product": 79,
      "name": "My Subscription",
      "status": "active",
      "date_start": "2024-01-01T00:00:00Z",
      "date_end": "2024-01-01T00:00:00Z",
      "remote_identity": "{remote_identity_id}",
      "storage_group": "{storage_group_id}",
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[1000]",
          "data_format": "STRING",
          "product": 79
        },
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "{remote_identity_id}",
          "data_format": "STRING",
          "product": 79
        }
      ]
    }
  }
}
```

**Meta attributes pattern:**

The `subscription_product_meta_attributes` array passes product-specific configuration alongside the subscription. Each entry has the following fields:

- `data_key` — the attribute name (e.g., `stage_ids`, `remote_identity_id`, `profile_id`, `project_id`)
- `data_value` — the value as a string
- `data_format` — `STRING` or `JSON`
- `product` — the product ID this meta entry applies to
- `data_id` — set to `0` for new entries

`stage_ids` is required for source products that use pipeline stages. `remote_identity_id` is required as an SPM entry for source products that connect to a third-party data source — it carries the same value as the top-level `remote_identity` field, passed as a string. Additional keys are product-specific — consult your product's documentation for the full list. Destination products do not use `subscription_product_meta_attributes`.

---

### Get Subscription

```
GET https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

Returns a single subscription record by ID.

---

### List Subscriptions

```
GET https://subscriptions.api.openbridge.io/sub
```

Common query filters:

- `status__not=invalid` — exclude invalid subscriptions
- `account={account_id}` — filter by account
- `product={product_id}` — filter by product

---

### Update Subscription

Partial update. All fields are optional.

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

**Example — update `stage_ids` meta:**

```json
{
  "data": {
    "type": "Subscription",
    "id": "{subscription_id}",
    "attributes": {
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[1000]",
          "data_format": "STRING",
          "product": 79
        }
      ]
    }
  }
}
```

---

### List Subscription Product Meta

Returns the `SubscriptionProductMeta` records for a subscription.

```
GET https://subscriptions.api.openbridge.io/spm?subscription={subscription_id}
```

Filter by key:

```
GET https://subscriptions.api.openbridge.io/spm?subscription={subscription_id}&data_key=stage_ids
```

---

## Field Reference

### Subscription Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `account` | integer | Yes | Account ID (from `GET /account`) |
| `user` | integer | Yes | User ID (from `GET /user`) |
| `product` | integer | Yes | Product ID (from `GET /product`) |
| `name` | string | No | Human-readable label for the subscription |
| `status` | enum | Yes | One of: `active`, `cancelled`, `paused`, `invalid` |
| `date_start` | datetime | Yes | Subscription start date (ISO 8601) |
| `date_end` | datetime | Yes | Subscription end date (ISO 8601) |
| `remote_identity` | integer | No | ID of the connected data source credential |
| `storage_group` | integer | No | ID of the storage destination (from `GET /storages`) |
| `subscription_product_meta_attributes` | array | No* | Product-specific configuration metadata |

\* Required for source products. Destination products do not use this field.

### SubscriptionProductMeta Fields

| Field | Type | Description |
|---|---|---|
| `data_id` | integer | Set to `0` for new entries |
| `data_key` | string | Attribute name (e.g., `stage_ids`, `remote_identity_id`, `profile_id`) |
| `data_value` | string | Attribute value as a string |
| `data_format` | enum | `STRING` or `JSON` |
| `product` | integer | Product ID this meta entry applies to |
