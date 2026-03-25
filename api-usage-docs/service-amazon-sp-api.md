# Service API: Amazon SP-API

> **Amazon SP-API reference**: [https://developer-docs.amazon.com/sp-api/docs](https://developer-docs.amazon.com/sp-api/docs)

## When to use

Use these endpoints when configuring Amazon Selling Partner API (SP-API) subscriptions. Before creating a subscription you need the marketplace IDs the seller participates in. The notifications endpoints provision SQS-based event subscriptions for near-real-time order and inventory data.

---

## Prerequisites

- A `remote_identity_id` of type **Amazon Seller** (remote identity type ID `17`) or **Amazon Vendor** (remote identity type ID `18`) for marketplace lookups and notifications. See [Remote Identity API](./remote-identity-api.md).
- For private app validation (`/sp/validate-creds` and `/sp/sp-id`), credentials are passed directly in the request body — no `remote_identity_id` needed.
- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### List marketplaces

Returns the Amazon marketplaces the selling partner participates in, based on their connected identity. Use the `id` field from each returned marketplace when creating a subscription.

```
GET /service/sp/marketplaces/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/sp/marketplaces/214
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": "ATVPDKIKX0DER",
    "name": "Amazon.com",
    "countryCode": "US",
    "defaultCurrencyCode": "USD",
    "defaultLanguageCode": "en_US",
    "domainName": "www.amazon.com"
  },
  {
    "id": "A2EUQ1WTGCTBG2",
    "name": "Amazon.ca",
    "countryCode": "CA",
    "defaultCurrencyCode": "CAD",
    "defaultLanguageCode": "en_CA",
    "domainName": "www.amazon.ca"
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Amazon marketplace ID string | Use as `marketplace_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `name` | Human-readable marketplace name | Display in UI |
| `countryCode` | ISO 3166-1 alpha-2 country code | — |
| `defaultCurrencyCode` | Default currency for this marketplace | — |
| `domainName` | Amazon storefront domain | — |

For the full list of marketplace IDs by country and region, see the [SP-API Marketplace IDs](https://developer-docs.amazon.com/sp-api/docs/marketplace-ids) reference.

---

### Resolve selling partner ID

Resolves the Amazon Seller ID for a private app (developer-owned) credential set. Used when the selling partner ID is not known in advance.

```
POST /service/sp/sp-id
```

**Request body**

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "client_id": "amzn1.application-oa2-client.xxx",
      "client_secret": "yyy",
      "region": "na",
      "refresh_token": "Atzr|..."
    }
  }
}
```

**Required fields**

| Field | Description |
|---|---|
| `client_id` | LWA application client ID |
| `client_secret` | LWA application client secret |
| `region` | SP-API region: `na`, `eu`, or `fe` |
| `refresh_token` | LWA refresh token |

**Example response**

```json
[
  {
    "type": "Service",
    "attributes": {
      "selling_partner_id": "A3EXAMPLE123456"
    }
  }
]
```

---

### Validate ASINs

Validates a list of ASINs against the marketplaces accessible to the given identity. Returns which ASINs are valid and which are not found.

```
POST /service/sp/validate-asins/{remote_identity_id}
```

**Request body**

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "asins": ["B00EXAMPLE1", "B00EXAMPLE2", "B00INVALID99"]
    }
  }
}
```

**Example response**

```json
{
  "valid_asins": [
    {
      "asin": "B00EXAMPLE1",
      "attributes": { ... }
    },
    {
      "asin": "B00EXAMPLE2",
      "attributes": { ... }
    }
  ],
  "invalid_asins": ["B00INVALID99"]
}
```

> ASINs are tested in batches of 20 across all marketplaces the identity participates in.

---

### Validate private app credentials

Validates a set of private SP-API application credentials by attempting to obtain an access token and call a live SP-API endpoint. Returns `204 No Content` on success.

```
POST /service/sp/validate-creds
```

**Request body**

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "client_id": "amzn1.application-oa2-client.xxx",
      "client_secret": "yyy",
      "region": "na",
      "refresh_token": "Atzr|..."
    }
  }
}
```

**Required fields** — same as `/sp/sp-id`.

**Responses**

| Status | Meaning |
|---|---|
| `204 No Content` | Credentials are valid |
| `400 Bad Request` | Credentials are invalid or the SP-API call failed |

---

## Notifications

SP-API notifications deliver event-driven updates (order changes, inventory changes, etc.) via SQS. These endpoints register an SQS queue as a destination and create subscriptions for selected notification types.

### List notification types

Returns the valid notification type names for a given account type.

```
GET /service/sp/notifications/list-notification-types?account_type={seller|vendor}
```

**Query parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_type` | string | Yes | `seller` or `vendor` |

**Example request**

```http
GET https://service.api.openbridge.io/service/sp/notifications/list-notification-types?account_type=seller
Authorization: Bearer <jwt>
```

For the full list of valid notification type values by account type, see the [SP-API Notification Type Values](https://developer-docs.amazon.com/sp-api/docs/notification-type-values) reference.

---

### Create notification subscription

Registers an SQS queue as a notification destination and subscribes to the specified notification types. If existing subscriptions are found, they are deleted and replaced. 

Note: Openbridge requires two SQS queues for this product. One is used directly by Amazon to push events to and another is used by Openbridge for processing. It is strongly recommended that these are configured with the [CloudFormation template provided by Openbridge](https://openbridge-customer-templates-production.s3.amazonaws.com/amazon-notifications-api/notifications-api.yaml). For more information about configuring the required pieces in AWS, visit the [Notifications API documentation here](https://docs.openbridge.com/en/articles/9997411-amazon-notifications-api-sqs-configuration).

```
POST /service/sp/notifications/{remote_identity_id}
```

**Request body**

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "queue_arn": "arn:aws:sqs:us-east-1:123456789012:my-sp-notifications-queue",
      "notification_types": ["ORDER_CHANGE", "FBA_INVENTORY_AVAILABILITY_CHANGES"]
    }
  }
}
```

**Required attributes**

| Field | Description |
|---|---|
| `queue_arn` | ARN of the SQS queue to receive notifications |
| `notification_types` | Array of notification type names to subscribe to. These must all be valid for the account type (seller or vendor) or the request will fail. |

**Example response**

```json
{
  "type": "SPAPINotifications",
  "attributes": {
    "subscriptions": {
      "ORDER_CHANGE": "sub_abc123",
      "FBA_INVENTORY_AVAILABILITY_CHANGES": "sub_def456"
    },
    "destination_id": "dest_xyz789"
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `attributes.subscriptions` | Map of notification type → subscription ID | Store subscription IDs for later update/delete |
| `attributes.destination_id` | SQS destination ID registered with SP-API | Store for cleanup on subscription delete |

> The identity type determines which notification types are valid. Seller identities (type ID `17`) have access to seller notification types; all others are treated as vendor.

---

### Update notification subscription

Replaces an existing notification subscription by deleting it and re-creating it with new parameters.

```
PATCH /service/sp/notifications/{remote_identity_id}/{subscription_id}
```

The request body is the same as the create endpoint. The `subscription_id` is the Openbridge subscription ID (not the SP-API subscription ID).

---

### Delete notification subscription

Removes all upstream SP-API subscriptions and the registered SQS destination for the given identity.

```
DELETE /service/sp/notifications/{remote_identity_id}/{subscription_id}
```

Returns `204 No Content` on success.
