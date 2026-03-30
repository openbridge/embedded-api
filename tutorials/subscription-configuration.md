# Subscription Configuration

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Choose your source product](#step-1--choose-your-source-product)
  - [Look up the product](#look-up-the-product)
  - [Check required meta fields](#check-required-meta-fields)
- [Step 2 — Look up available stage IDs](#step-2--look-up-available-stage-ids)
- [Step 3 — Identify your storage destination](#step-3--identify-your-storage-destination)
- [Step 4 — Find your remote identity](#step-4--find-your-remote-identity)
- [Step 5 — Gather product-specific meta values](#step-5--gather-product-specific-meta-values)
- [Step 6 — Build and send the create request](#step-6--build-and-send-the-create-request)
  - [Subscription fields](#subscription-fields)
  - [SubscriptionProductMeta fields](#subscriptionproductmeta-fields)
  - [Example 1 — Simple product (Amazon Orders API)](#example-1--simple-product-amazon-orders-api)
  - [Example 2 — Product with additional meta (Amazon Sponsored Ads V3)](#example-2--product-with-additional-meta-amazon-sponsored-ads-v3)
- [Limiting collected datasets with stage_ids](#limiting-collected-datasets-with-stage_ids)
- [Updating a subscription](#updating-a-subscription)
- [Pausing or cancelling a subscription](#pausing-or-cancelling-a-subscription)
- [Deleting a subscription](#deleting-a-subscription)

---

## Overview

A subscription connects three things: a **source product** (what data to collect), a **storage destination** (where to send it), and a **remote identity** (the credentials that authorize data collection). Creating a subscription through the API follows a predictable sequence — look up the product, gather the required metadata, and POST the subscription record.

---

## Prerequisites

All API calls require a JWT access token. Obtain one by exchanging your refresh token with the [Authentication API](../api-usage-docs/authentication-api.md).

You will also need your **account ID** and **user ID** before creating a subscription. See [Step 1 of the Identity Configuration tutorial](./identity-configuration.md#step-1--look-up-your-account-and-user-ids) or the [Account and User API](../api-usage-docs/account-user-api.md) for how to retrieve them.

---

## Step 1 — Choose your source product

### Look up the product

Fetch the product you want to subscribe to:

```
GET https://subscriptions.api.openbridge.io/product/{product_id}
```

Or list all available source products:

```
GET https://subscriptions.api.openbridge.io/product?is_storage_product=0
```

The response includes the product's `id`, required identity type, and the meta fields needed for its subscriptions:

```json
{
  "type": "Product",
  "id": "53",
  "attributes": {
    "active": 1,
    "name": "Orders",
    "is_storage_product": 0,
    "required_meta_fields": [
      "remote_identity_id"
    ]
  },
  "relationships": {
    "remote_identity_type": {
      "data": {
        "type": "RemoteIdentityType",
        "id": "17"
      }
    }
  }
}
```

See the [Products API](../api-usage-docs/products-api.md) for query filters and the full field reference.

### Check required meta fields

The `required_meta_fields` array tells you which `subscription_product_meta_attributes` entries are needed. Common patterns:

- **Amazon Seller/Vendor products** — `["remote_identity_id"]`
- **Amazon Advertising products** — `["remote_identity_id", "profile_id"]`
- **Facebook products** — `["remote_identity_id", "ad_account_id"]` or `["remote_identity_id", "account_id"]`
- **Google products** — `["remote_identity_id", "manager_customer_id", "client_customer_id"]`

See the [Product Overview](../products/product-overview.md) for the full list of products and their required meta fields.

---

## Step 2 — Look up available stage IDs

Source products have pipeline stages that define which datasets are collected. You need the valid `stage_id` values for the product to include them in your subscription.

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
```

Filter with `stage_id__gte=1000` — values below 1000 are legacy records.

**Example response:**

```json
{
  "data": [
    {
      "type": "Product",
      "id": "2180",
      "attributes": {
        "name": "amzn_attribution_advertisers",
        "stage_id": 1000
      }
    },
    {
      "type": "Product",
      "id": "2181",
      "attributes": {
        "name": "amzn_attribution_metrics",
        "stage_id": 1001
      }
    }
  ]
}
```

Record the `stage_id` values. You will pass them as a stringified JSON array in the `stage_ids` meta attribute when creating the subscription.

---

## Step 3 — Identify your storage destination

Storage destinations are created and managed exclusively through the Openbridge UI. To find the ID of an existing destination, list your active storages:

```
GET https://subscriptions.api.openbridge.io/storages?status=active
```

Use the destination's `id` as the `storage_group` value when creating the subscription.

---

## Step 4 — Find your remote identity

Most source products require a remote identity — the OAuth credentials that authorize Openbridge to pull data from the third-party source. Identities are created through the OAuth flow described in [Identity Configuration](./identity-configuration.md).

To find an existing identity:

```
GET https://remote-identity.api.openbridge.io/sri
```

Use the `id` from the matching record as both the top-level `remote_identity` field and the `remote_identity_id` meta attribute value (as a string).

> **Note:** Not all products require a remote identity. Check the product's `relationships.remote_identity_type.data` — if it is `null`, the product does not need one.

---

## Step 5 — Gather product-specific meta values

Some products require additional metadata beyond `remote_identity_id` and `stage_ids`. This data typically comes from a third-party API call through the Openbridge Service API.

**Amazon Advertising products** (`profile_id`): Call the [Amazon Advertising Profiles](../service-api.md#amazon-advertising-profiles) endpoint to get available profile IDs for the remote identity.

**Facebook products** (`ad_account_id`, `account_id`): Call the [Facebook Ads](../service-api.md#facebook-ads) or [Facebook Page Profiles](../service-api.md#facebook-page-insights-instagram-insights-instagram-stories) endpoint.

**Google products** (`manager_customer_id`, `client_customer_id`, `project_id`, `dataset_id`): Call the relevant [Google endpoint](../service-api.md#google) on the Service API.

**Shopify** (`shop_created_at`): Call the [Shopify Info](../service-api.md#shopify-info) endpoint.

See the [Product Overview](../products/product-overview.md) for the exact meta fields required per product and the [Service API](../service-api.md) for the endpoint details.

---

## Step 6 — Build and send the create request

```
POST https://subscriptions.api.openbridge.io/sub
```

### Subscription fields

| Field | Type | Required | Description |
|---|---|---|---|
| `account` | integer | Yes | Your account ID |
| `user` | integer | Yes | Your user ID |
| `product` | integer | Yes | Product ID from Step 1 |
| `name` | string | No | Human-readable label |
| `status` | enum | Yes | Set to `active` |
| `date_start` | datetime | Yes | ISO 8601 datetime |
| `date_end` | datetime | Yes | ISO 8601 datetime |
| `remote_identity` | integer | Conditional | Remote identity ID; required for products that connect to a third-party source |
| `storage_group` | integer | Conditional | Storage destination ID from Step 3 |
| `subscription_product_meta_attributes` | array | Conditional | Product-specific metadata; required for source products |

### SubscriptionProductMeta fields

Each entry in the `subscription_product_meta_attributes` array has this structure:

| Field | Type | Description |
|---|---|---|
| `data_id` | integer | Always set to `0` for new entries |
| `data_key` | string | Attribute name (e.g., `remote_identity_id`, `stage_ids`, `profile_id`) |
| `data_value` | string | Value as a string |
| `data_format` | enum | `STRING` or `JSON` |
| `product` | integer | The product ID this meta entry applies to |

### Example 1 — Simple product (Amazon Orders API)

Amazon Orders API (product `53`) requires only `remote_identity_id` in its meta fields. It uses identity type `17` (Amazon Selling Partner).

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 53,
      "name": "My Orders API Subscription",
      "status": "active",
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "remote_identity": 1,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "1",
          "data_format": "STRING",
          "product": 53
        }
      ]
    }
  }
}
```

Replace the placeholder values (`account`, `user`, `remote_identity`, `storage_group`, and the `data_value` for `remote_identity_id`) with IDs from your account.

### Example 2 — Product with additional meta (Amazon Sponsored Ads V3)

Amazon Sponsored Ads V3 (product `70`) requires both `remote_identity_id` and `profile_id`. It uses identity type `14` (Amazon Advertising).

The `profile_id` comes from calling the [Amazon Advertising Profiles](../service-api.md#amazon-advertising-profiles) endpoint with the remote identity ID. The response returns the available profiles — use the profile ID for the account you want to collect data from.

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 70,
      "name": "My Sponsored Ads V3 Subscription",
      "status": "active",
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "remote_identity": 2,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "2",
          "data_format": "STRING",
          "product": 70
        },
        {
          "data_id": 0,
          "data_key": "profile_id",
          "data_value": "1234567890",
          "data_format": "STRING",
          "product": 70
        }
      ]
    }
  }
}
```

---

## Limiting collected datasets with stage_ids

By default a subscription collects all available datasets for the product. To limit collection to specific datasets, add a `stage_ids` entry to the `subscription_product_meta_attributes` array.

First, look up the available stage IDs for the product (see [Step 2](#step-2--look-up-available-stage-ids)). Then pass the ones you want as a stringified JSON array:

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 53,
      "name": "My Orders API Subscription",
      "status": "active",
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "remote_identity": 1,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "1",
          "data_format": "STRING",
          "product": 53
        },
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[1000,1001]",
          "data_format": "STRING",
          "product": 53
        }
      ]
    }
  }
}
```

This tells the pipeline to collect only the datasets corresponding to stage IDs `1000` and `1001`. You can add `stage_ids` retroactively to existing subscriptions via a PATCH request.

---

## Updating a subscription

Use a PATCH request to update an existing subscription:

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

Include the subscription `id` in the payload and only the fields you want to change.

**Example — add `stage_ids` to an existing subscription:**

```json
{
  "data": {
    "type": "Subscription",
    "id": "12345",
    "attributes": {
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[1000,1001,1002]",
          "data_format": "STRING",
          "product": 53
        }
      ]
    }
  }
}
```

See the [Subscriptions API](../api-usage-docs/subscriptions-api.md) for full PATCH documentation.

---

## Pausing or cancelling a subscription

Change the subscription's `status` with a PATCH request:

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

```json
{
  "data": {
    "type": "Subscription",
    "id": "12345",
    "attributes": {
      "status": "cancelled"
    }
  }
}
```

Valid status values:

| Status | Effect |
|---|---|
| `active` | Subscription is running and collecting data |
| `cancelled` | Subscription is permanently stopped |
| `paused` | Subscription is temporarily stopped — can be set back to `active` |
| `invalid` | Subscription is marked as deleted (see below) |

---

## Deleting a subscription

Subscriptions cannot be deleted through the API or the Openbridge UI. Instead, set the status to `invalid`:

```json
{
  "data": {
    "type": "Subscription",
    "id": "12345",
    "attributes": {
      "status": "invalid"
    }
  }
}
```

Once marked `invalid`, the subscription no longer appears in the Openbridge UI. An `invalid` subscription can be set back to `active` or `cancelled` as long as no duplicate subscription exists in an `active` or `cancelled` state.
