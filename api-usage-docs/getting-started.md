# Getting Started

A subscription connects a data source product, a storage destination, and data source credentials (remote identity). This guide walks you through the full sequence — from looking up your account details to optionally backfilling historical data.

---

## Order of Operations

1. [Get your account ID](#step-1--get-your-account-id)
2. [Get your user ID](#step-2--get-your-user-id)
3. [List available source products](#step-3--list-available-products)
4. [Retrieve product payload definitions](#step-4--get-product-payload-definitions) (to find valid `stage_id` values, for source products that use them)
5. [Find your remote identity ID](#step-5--find-your-remote-identity-id)
6. [Identify your storage destination](#step-6--identify-your-storage-destination)
7. [Create a subscription](#step-7--create-a-subscription)
8. [Verify the subscription is active](#step-8--verify-the-subscription)
9. [(Optional) Request historical data](#step-9--optional-request-historical-data)

---

## Step-by-Step

### Step 1 — Get Your Account ID

```
GET https://account.api.openbridge.io/account
```

Returns your account details. Use the `id` field as the `account` value in subscription requests.

---

### Step 2 — Get Your User ID

```
GET https://user.api.openbridge.io/user
```

Returns your user details. Use the `id` field as the `user` value in subscription requests.

---

### Step 3 — List Available Products

```
GET https://subscriptions.api.openbridge.io/product
```

Returns all available products. Use a product's `id` as the `product` field when creating a subscription.

---

### Step 4 — Get Product Payload Definitions

For **source products**, retrieve the available payloads to find valid `stage_id` values. These values are used in the `stage_ids` subscription meta attribute.

```
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?enabled=true
```

Each payload object contains a `stage_id`. Pass the relevant value(s) in the `stage_ids` meta attribute when creating the subscription.

> **Note:** `stage_ids` applies to source (data) products only. Destination products do not use this attribute.

---

### Step 5 — Find Your Remote Identity ID

Remote identities represent the data source credentials (OAuth tokens, service account keys, etc.) that authorize Openbridge to pull data on your behalf. They are created and authorized through the Openbridge UI — you cannot create them via the API.

Once a remote identity exists, look up its ID:

```
GET https://remote-identity.api.openbridge.io/ri
```

Use the `id` field from the matching record as the `remote_identity` value in your subscription request. Most source products also require you to pass this same ID as the `remote_identity_id` meta attribute (as a string).

> **Note:** Not all products require a remote identity. Destination products, and any source products that do not connect to a third-party data source, do not use this field.

---

### Step 6 — Identify Your Storage Destination

Destinations are managed through the UI — do not attempt to create or update them via the API. To find the ID of an existing destination, list your storage subscriptions:

```
GET https://subscriptions.api.openbridge.io/storages?status=active
```

Use the destination's `id` as the `storage_group` field when creating a source subscription.

---

### Step 7 — Create a Subscription

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

The `subscription_product_meta_attributes` array carries product-specific configuration. For source products that connect to a third-party data source, both `stage_ids` and `remote_identity_id` are typically required — `remote_identity_id` duplicates the top-level `remote_identity` value as a string inside the meta array. Additional keys (such as `profile_id`, `project_id`) are product-specific. Consult your product's documentation for the full list of required meta keys. Destination products do not use this field.

---

### Step 8 — Verify the Subscription

```
GET https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

Check that `status` is `active`. If it is not, review the subscription's meta attributes and ensure the remote identity and storage group IDs are correct.

---

### Step 9 — (Optional) Request Historical Data

Once a subscription is active, you can trigger historical data retrieval for a past date range. See the [History API reference](./history-api.md) for full details.
