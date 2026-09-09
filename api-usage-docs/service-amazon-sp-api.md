# Service API: Amazon SP-API

> **Amazon SP-API reference**: [https://developer-docs.amazon.com/sp-api/docs](https://developer-docs.amazon.com/sp-api/docs)

## When to use

Use these endpoints when configuring Amazon Selling Partner API (SP-API) subscriptions. Before creating a subscription you need the marketplace IDs the seller participates in. The unified notifications endpoints configure SQS and EventBridge event subscriptions, with delivery through Firehose to S3.

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
| `id` | Amazon marketplace ID string | Use as `marketplace_id` in subscription [`product_parameters`](./subscriptions-api.md) |
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

## Unified notifications

Use `/sp/notifications-unified` for new notification pipelines. The service chooses SQS or EventBridge for each requested notification type and provisions the corresponding delivery resources in your AWS account. Both paths deliver through Firehose to a shared regional S3 bucket, with a pipeline-specific prefix and an SQS queue for S3 object notifications.

### List unified notification types

Returns the notification type names supported by the service for a seller or vendor account, including both SQS and EventBridge types. The response lists names only; destination selection is automatic when creating a pipeline.

```
GET /service/sp/notifications-unified/list-notification-types?account_type={seller|vendor}
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_type` | string | Yes | `seller` or `vendor`; a missing or invalid value returns `400 Bad Request` |

**Example request**

```http
GET https://service.api.openbridge.io/service/sp/notifications-unified/list-notification-types?account_type=vendor
Authorization: Bearer <jwt>
```

**Example response** — `200 OK`

```json
{
  "type": "SPAPINotifications",
  "attributes": {
    "notification_types": [
      "DETAIL_PAGE_TRAFFIC_EVENT",
      "FEED_PROCESSING_FINISHED",
      "ITEM_INVENTORY_EVENT_CHANGE",
      "ITEM_SALES_EVENT_CHANGE",
      "REPORT_PROCESSING_FINISHED",
      "LISTINGS_ITEM_ISSUES_CHANGE",
      "PRODUCT_TYPE_DEFINITIONS_CHANGE"
    ]
  }
}
```

---

### Create unified notification subscription

```
POST /service/sp/notifications-unified/{remote_identity_id}
```

The identity must be an Amazon Seller (type `17`) or Amazon Vendor (type `18`). Its type determines the allowed notification types. If the identity has an active legacy SQS notification pipeline (product `86`), creation returns `400 Bad Request`; cancel that pipeline before creating the unified pipeline.

**AWS prerequisites**

- Supply a customer IAM role that Openbridge can assume to configure the notification resources in the specified AWS account and region.
- For EventBridge notification types, also supply the role EventBridge uses to deliver to Firehose, and ensure the customer account contains the Firehose delivery role named `openbridge-spapi-firehose-role`.
- The service provisions the SQS delivery resources; a customer-provided `queue_arn` is not a unified request attribute.

**Example request** — combines an SQS type and an EventBridge type for a seller identity

```http
POST https://service.api.openbridge.io/service/sp/notifications-unified/214
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "notification_types": ["ORDER_CHANGE", "LISTINGS_ITEM_STATUS_CHANGE"],
      "role_arn": "arn:aws:iam::123456789012:role/openbridge-spapi-cf-manager",
      "eb_to_fh_role_arn": "arn:aws:iam::123456789012:role/openbridge-eventbridge-to-firehose-role",
      "aws_region": "us-east-1"
    }
  }
}
```

**Request attributes**

| Field | Type | Required | Description |
|---|---|---|---|
| `notification_types` | array of strings | Yes | Non-empty list of names returned by the unified list endpoint for the identity's account type |
| `role_arn` | string | Yes | Customer IAM role ARN assumed by Openbridge to configure AWS resources |
| `eb_to_fh_role_arn` | string | For EventBridge types | IAM role ARN used by the EventBridge target to deliver to Firehose; omit for SQS-only requests |
| `aws_region` | string | Yes | Currently accepted values: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`, `af-south-1`, `ap-east-1`. This is the AWS deployment region, separate from the identity's SP-API region. |

Existing upstream subscriptions are reused if they already reference the expected destination. An existing subscription for the same notification type at a different destination causes an error rather than automatic replacement.

**Example response** — `207 Multi-Status` (abbreviated `meta`)

```json
{
  "type": "SPAPINotifications",
  "attributes": {
    "subscriptions": {
      "ORDER_CHANGE": "sub_abc123",
      "LISTINGS_ITEM_STATUS_CHANGE": "sub_def456"
    },
    "failed": {},
    "meta": {
      "shared_pipeline_id": "0123456789abcdef",
      "s3_bucket_name": "ob-sp-notifications-123456789012-us-east-1",
      "s3_notification_prefix": "0123456789abcdef/",
      "s3_notification_queue_arn": "arn:aws:sqs:us-east-1:123456789012:ob-sp-notifications-0123456789abcdef-s3-events",
      "s3_notification_configuration_id": "ob-sp-notifications-0123456789abcdef",
      "sqs_destination_id": "dest_sqs123",
      "eventbridge_destination_id": "dest_eb456"
    }
  }
}
```

| Field | Description |
|---|---|
| `attributes.subscriptions` | Map of successfully subscribed notification types to upstream SP-API subscription IDs |
| `attributes.failed` | Map of failed notification types to upstream error details; inspect this even when the request returns `207` |
| `attributes.meta` | Shared S3 bucket, prefix, notification queue, and configuration identifiers, plus metadata for each configured delivery path |
| `attributes.meta.sqs_*`, `eventbridge_pipe_arn`, `firehose_arn` | SQS path identifiers, source queue, roles, log groups, EventBridge Pipe, and Firehose stream; present when SQS types are configured |
| `attributes.meta.eventbridge_pipeline_id`, `event_bus_name`, `eventbridge_rule_id`, `eventbridge_target_id`, `eventbridge_destination_id` | EventBridge path identifiers; present when EventBridge types are configured |

Preserve the returned subscriptions and complete metadata for the Openbridge subscription lifecycle. The service's update/delete operations depend on stored subscription product metadata; this response does not contain an Openbridge subscription ID.

**Responses**

| Status | Meaning |
|---|---|
| `207 Multi-Status` | Pipeline setup completed; may contain individual notification failures. Also returned when every requested type succeeds. |
| `400 Bad Request` | Invalid request, unsupported notification type, active legacy SQS pipeline, destination conflict, or setup failure. Failure to subscribe to any type in a requested delivery path also fails setup. |
| `403 Forbidden` | Role assumption or an explicitly handled credential/permission check failed |

---

### Update unified notification subscription

```
PATCH /service/sp/notifications-unified/{remote_identity_id}/{subscription_id}
```

Use the full create request body, including the desired notification types and AWS role/region attributes. The path's `subscription_id` is the **Openbridge subscription ID**, not an upstream SP-API subscription ID. The subscription must belong to the authenticated account, the specified remote identity, and product `107`.

The service disables the existing upstream subscriptions before creating the replacements. When the AWS account and region are unchanged, stored SQS source-queue metadata exists, and the new selection still includes an SQS type, it preserves and reuses the existing SQS delivery pipeline and destination. Otherwise, it cleans up the existing delivery resources before recreating them. This is not an atomic update: a creation failure can leave the previous upstream subscriptions disabled.

Successful setup returns the same `207 Multi-Status` body as create. If cleanup fails, the service returns that error and does not attempt creation.

---

### Delete unified notification subscription

```
DELETE /service/sp/notifications-unified/{remote_identity_id}/{subscription_id}
```

Uses the Openbridge subscription ID for product `107`, with the same account and identity ownership checks as update. No request body is required. Cleanup uses the subscription's stored notification subscriptions, AWS role/region, and pipeline metadata.

Removes upstream notification subscriptions and the pipeline's delivery resources: the SQS destination and delivery pipeline, EventBridge rule/target and Firehose stream, and the pipeline-specific S3 notification configuration and queue, as applicable. The shared S3 bucket and its objects, shared EventBridge bus/destination, and pre-existing customer roles are retained.

| Status | Meaning |
|---|---|
| `204 No Content` | Cleanup completed |
| `400 Bad Request` | Missing or invalid stored metadata, or upstream/resource cleanup failed |
| `403 Forbidden` | Subscription belongs to a different account, remote identity, or product |

---

## Legacy notifications

> **Legacy:** Use the `/sp/notifications` endpoints below only to modify or delete existing legacy SP notifications subscriptions. Use [Unified notifications](#unified-notifications) to create new subscriptions.

Legacy SP-API notifications deliver event-driven updates (order changes, inventory changes, etc.) via SQS.

### List notification types (legacy)

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

### Update notification subscription (legacy)

Replaces an existing notification subscription by deleting it and re-creating it with new parameters.

Note: Openbridge requires two SQS queues for this product. One is used directly by Amazon to push events to and another is used by Openbridge for processing. It is strongly recommended that these are configured with the [CloudFormation template provided by Openbridge](https://openbridge-customer-templates-production.s3.amazonaws.com/amazon-notifications-api/notifications-api.yaml). For more information about configuring the required pieces in AWS, visit the [Notifications API documentation here](https://docs.openbridge.com/en/articles/9997411-amazon-notifications-api-sqs-configuration).

```
PATCH /service/sp/notifications/{remote_identity_id}/{subscription_id}
```

The `subscription_id` is the Openbridge subscription ID (not the SP-API subscription ID).

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

### Delete notification subscription (legacy)

Removes all upstream SP-API subscriptions and the registered SQS destination for the given identity.

```
DELETE /service/sp/notifications/{remote_identity_id}/{subscription_id}
```

Returns `204 No Content` on success.
