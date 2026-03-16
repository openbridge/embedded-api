# Products API

Products are listed through the Subscriptions API. Payload definitions — which provide the `stage_id` values needed for subscriptions and history requests — are fetched from the Products API. This document covers both calls.

---

## Base URLs

| Endpoint | Base URL |
|---|---|
| List products | `https://subscriptions.api.openbridge.io` |
| Product payload definitions (via proxy) | `https://service.api.openbridge.io/service/products` |

---

## Authentication

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

---

## Endpoints

### List Products

Returns all available products. Use the `id` field as the `product` value when creating a subscription or as `product_id` in History API requests.

```
GET https://subscriptions.api.openbridge.io/product
```

Results are paginated. Use `page={n}` to advance through pages.

**Example response:**

```json
{
  "links": {
    "first": "https://subscriptions.api.openbridge.io/product?page=1",
    "last": "https://subscriptions.api.openbridge.io/product?page=5",
    "next": "https://subscriptions.api.openbridge.io/product?page=2",
    "prev": ""
  },
  "data": [
    {
      "type": "Product",
      "id": "1",
      "attributes": {
        "active": 0,
        "name": "Twitter Tweet Vault",
        "summary": "",
        "is_storage_product": 0,
        "created_at": "2013-10-24T16:11:07",
        "modified_at": "2013-10-24T16:11:07",
        "required_meta_fields": []
      },
      "relationships": {
        "remote_identity_type": {
          "data": null
        }
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 5,
      "count": 100
    }
  }
}
```

---

### Get Product Payload Definitions

Returns the payload definitions for a product. Each record includes a `stage_id` used in the `stage_ids` subscription meta attribute and in History API requests. Applies to source products only.

Note: Filter to payload records with `stage_id >= 1000` for current integrations — filter with `stage_id__gte=1000`:

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

**Example response:**

```json
{
  "links": {
    "first": "/product/81/payloads?page=1",
    "last": "/product/81/payloads?page=1",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "Product",
      "id": "2180",
      "attributes": {
        "name": "amzn_attribution_advertisers",
        "created_at": "2024-05-07T10:27:51.059000-05:00",
        "modified_at": "2024-05-07T10:27:51.092000-05:00",
        "stage_id": 1000
      }
    },
    {
      "type": "Product",
      "id": "2181",
      "attributes": {
        "name": "amzn_attribution_metrics",
        "created_at": "2024-05-07T10:27:51.228000-05:00",
        "modified_at": "2024-05-07T10:27:51.260000-05:00",
        "stage_id": 1001
      }
    },
    {
      "type": "Product",
      "id": "2182",
      "attributes": {
        "name": "amzn_attribution_publishers",
        "created_at": "2024-05-07T10:27:51.411000-05:00",
        "modified_at": "2024-05-07T10:27:51.448000-05:00",
        "stage_id": 1002
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 1,
      "count": 12
    }
  }
}
```

---

## Field Reference

### Product Fields (`GET /product`)

| Field | Type | Description |
|---|---|---|
| `id` | string | Product ID. Use as the `product` value when creating a subscription. |
| `name` | string | Display name of the product |
| `active` | integer | Whether the product is currently active |
| `summary` | string | Short description of the product |
| `is_storage_product` | integer | `1` if this is a storage destination product; `0` if it is a source product |
| `required_meta_fields` | array | List of `subscription_product_meta_attributes` keys required for this product |
| `created_at` | datetime | When the product was created |
| `modified_at` | datetime | When the product was last updated |
| `remote_identity_type` | relationship | The remote identity type required by this product, or `null` if no remote identity is needed |

### Payload Definition Fields (`GET /service/products/product/{id}/payloads`)

| Field | Type | Description |
|---|---|---|
| `id` | string | Payload record ID (not used directly in API calls) |
| `name` | string | Internal pipeline table name for this payload |
| `stage_id` | integer | Stage identifier used in `stage_ids` subscription meta and History API requests. Values `>= 1000` are current; `0` indicates a legacy record. |
| `created_at` | datetime | When the payload record was created |
| `modified_at` | datetime | When the payload record was last updated |
