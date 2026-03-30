# Amazon Notifications API Pipeline

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Choose or create a remote identity](#step-1--choose-or-create-a-remote-identity)
- [Step 2 — Select notification datasets](#step-2--select-notification-datasets)
- [Step 3 — Configure AWS SQS queues](#step-3--configure-aws-sqs-queues)
- [Step 4 — Create the notification subscription via Service API](#step-4--create-the-notification-subscription-via-service-api)
- [Step 5 — Create the pipeline subscription](#step-5--create-the-pipeline-subscription)
  - [Subscription meta fields](#subscription-meta-fields)
  - [Full example request](#full-example-request)
- [Updating a notification subscription](#updating-a-notification-subscription)
- [Deleting a notification subscription](#deleting-a-notification-subscription)

---

## Overview

This tutorial walks through creating an Amazon SP-API Notifications pipeline subscription end-to-end. The Notifications API product (product ID `86`) provisions SQS-based event subscriptions that deliver near-real-time order, inventory, and other event data from Amazon Seller Central or Vendor Central.

The flow mirrors the Openbridge website wizard: choose an identity, pick notification types, configure AWS SQS queues, register the queues with Amazon via the Service API, and finally create the pipeline subscription.

---

## Prerequisites

- A JWT access token — see [Authentication API](../api-usage-docs/authentication-api.md)
- Your account ID and user ID — see [Identity Configuration Step 1](./identity-configuration.md#step-1--look-up-your-account-and-user-ids)
- An active Amazon Seller Central or Vendor Central account
- A storage destination already configured — see [Subscription Configuration Step 3](./subscription-configuration.md#step-3--identify-your-storage-destination)

---

## Step 1 — Choose or create a remote identity

The Notifications API requires an Amazon Selling Partner identity. Two identity types are supported:

| Identity type | Type ID | Use case |
|---|---|---|
| Amazon Seller | `17` | Seller Central accounts |
| Amazon Vendor | `18` | Vendor Central accounts |

### Create a new identity

If you do not have an identity yet, follow the [Identity Configuration tutorial](./identity-configuration.md) to create one via the OAuth flow.

### List existing identities

To find an existing seller identity, list shared remote identities filtered by type:

```http
GET https://remote-identity.api.openbridge.io/sri?remote_identity_type=17&invalid_identity=0
Authorization: Bearer <jwt>
```

For vendor identities, replace `17` with `18`.

**Example response:**

```json
{
  "links": {
    "first": "https://remote-identity.api.openbridge.io/sri?remote_identity_type=17&invalid_identity=0&page=1",
    "last": "https://remote-identity.api.openbridge.io/sri?remote_identity_type=17&invalid_identity=0&page=1",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "RemoteIdentity",
      "id": "362",
      "attributes": {
        "name": "My Seller Account",
        "created_at": "2024-01-15T12:00:00",
        "modified_at": "2024-06-01T08:30:00",
        "remote_unique_id": "ATVPDKIKX0DER",
        "account_id": 1,
        "user_id": 1,
        "invalid_identity": 0,
        "region": "global",
        "email": "seller@example.com"
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 1,
      "count": 1
    }
  }
}
```

Record the identity `id` (e.g., `362`) — you will need it in subsequent steps.

See the [Remote Identity API](../api-usage-docs/remote-identity-api.md) for full endpoint details.

---

## Step 2 — Select notification datasets

Fetch the available notification types for your account type:

```http
GET https://service.api.openbridge.io/service/sp/notifications/list-notification-types?account_type=seller
Authorization: Bearer <jwt>
```

For vendor identities, use `account_type=vendor`.

> **Note:** The `account_type` must match the identity type chosen in Step 1 — `seller` for type `17`, `vendor` for type `18`.

Choose the notification types you want to subscribe to (e.g., `ORDER_CHANGE`, `FBA_INVENTORY_AVAILABILITY_CHANGES`). You will pass these as an array in Step 4 and as a stringified JSON array in the subscription meta in Step 5.

For the full list of valid notification type values by account type, see the [SP-API Notification Type Values](https://developer-docs.amazon.com/sp-api/docs/notification-type-values) reference.

See the [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md) for full endpoint details.

---

## Step 3 — Configure AWS SQS queues

The Notifications API product requires **two** SQS queues in your AWS account:

1. **SP-API SQS Queue** — receives notifications directly from Amazon's SP-API
2. **S3 Notifications SQS Queue** — used by Openbridge for processing notification data

### Deploy the CloudFormation template

Openbridge provides a CloudFormation template that creates both queues with the correct permissions:

```
https://openbridge-customer-templates-production.s3.amazonaws.com/amazon-notifications-api/notifications-api.yaml
```

Deploy this template in your AWS account. Once the stack completes, copy the two SQS ARNs from the stack outputs.

For detailed instructions on configuring the required AWS resources, see the [Notifications API SQS Configuration](https://docs.openbridge.com/en/articles/9997411-amazon-notifications-api-sqs-configuration) documentation.

### ARN format

SQS ARNs follow this pattern:

```
arn:aws:sqs:us-east-1:000000000000:notifications-api-queue
```

You will also need the SQS queue URLs, which can be derived from the ARN:

```
https://sqs.{region}.amazonaws.com/{accountId}/{queueName}
```

For example, if the ARN is `arn:aws:sqs:us-east-1:123456789012:my-sp-notifications-queue`, the URL is:

```
https://sqs.us-east-1.amazonaws.com/123456789012/my-sp-notifications-queue
```

> **Note:** Each pair of SQS queues can only be used for one pipeline subscription. If you have multiple seller or vendor accounts, deploy a separate CloudFormation stack for each.

---

## Step 4 — Create the notification subscription via Service API

Register the SP-API SQS queue with Amazon and subscribe to your chosen notification types:

```
POST https://service.api.openbridge.io/service/sp/notifications/{remote_identity_id}
```

Replace `{remote_identity_id}` with the identity ID from Step 1.

**Example request:**

```http
POST https://service.api.openbridge.io/service/sp/notifications/362
Authorization: Bearer <jwt>
Content-Type: application/json
```

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

| Field | Description |
|---|---|
| `queue_arn` | ARN of the **SP-API SQS Queue** (the queue that receives notifications from Amazon) |
| `notification_types` | Array of notification type names to subscribe to. All must be valid for the account type or the request will fail. |

**Example response:**

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

Save the `subscriptions` and `destination_id` values from the response — they are required for the pipeline subscription meta in Step 5.

See the [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md) for full endpoint details.

---

## Step 5 — Create the pipeline subscription

With all the pieces gathered from the previous steps, create the pipeline subscription for product `86` (Amazon Selling Partner Notifications).

```
POST https://subscriptions.api.openbridge.io/sub
```

For general detail on subscription creation, see the [Subscription Configuration tutorial](./subscription-configuration.md).

### Subscription meta fields

This product requires 9 meta fields in `subscription_product_meta_attributes`. It does **not** use `stage_ids` — dataset selection is handled via the `selected_tables` meta field instead.

| `data_key` | `data_format` | Source | Description |
|---|---|---|---|
| `remote_identity_id` | STRING | Step 1 | The identity ID as a string |
| `identity_type` | STRING | Step 1 | `"seller"` or `"vendor"` |
| `sqs_queue_arn` | STRING | Step 3 | SP-API SQS Queue ARN |
| `sqs_queue_url` | STRING | Step 3 | SP-API SQS Queue URL (derived from ARN) |
| `sqs_notification_arn` | STRING | Step 3 | S3 Notifications SQS Queue ARN |
| `sqs_notification_url` | STRING | Step 3 | S3 Notifications SQS Queue URL (derived from ARN) |
| `sqs_destination_id` | STRING | Step 4 | `destination_id` from the create notification response |
| `notification_subscriptions` | JSON | Step 4 | Stringified `subscriptions` map from the create notification response |
| `selected_tables` | JSON | Step 2 | Stringified array of selected notification type names |

### Full example request

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 86,
      "name": "My SP-API Notifications Pipeline",
      "status": "active",
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "remote_identity": 362,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "362",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "identity_type",
          "data_value": "seller",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "sqs_queue_arn",
          "data_value": "arn:aws:sqs:us-east-1:123456789012:my-sp-notifications-queue",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "sqs_queue_url",
          "data_value": "https://sqs.us-east-1.amazonaws.com/123456789012/my-sp-notifications-queue",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "sqs_notification_arn",
          "data_value": "arn:aws:sqs:us-east-1:123456789012:my-s3-notifications-queue",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "sqs_notification_url",
          "data_value": "https://sqs.us-east-1.amazonaws.com/123456789012/my-s3-notifications-queue",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "sqs_destination_id",
          "data_value": "dest_xyz789",
          "data_format": "STRING",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "notification_subscriptions",
          "data_value": "{\"ORDER_CHANGE\":\"sub_abc123\",\"FBA_INVENTORY_AVAILABILITY_CHANGES\":\"sub_def456\"}",
          "data_format": "JSON",
          "product": 86
        },
        {
          "data_id": 0,
          "data_key": "selected_tables",
          "data_value": "[\"ORDER_CHANGE\",\"FBA_INVENTORY_AVAILABILITY_CHANGES\"]",
          "data_format": "JSON",
          "product": 86
        }
      ]
    }
  }
}
```

Replace the placeholder values (`account`, `user`, `remote_identity`, `storage_group`, and all `data_value` entries) with values from your account and the previous steps.

---

## Updating a notification subscription

To update an existing notification subscription (e.g., to change the subscribed notification types), use two requests:

**1. Update the upstream SP-API subscription:**

```
PATCH https://service.api.openbridge.io/service/sp/notifications/{remote_identity_id}/{subscription_id}
```

The request body is the same as the create endpoint — include the updated `queue_arn` and `notification_types`. This deletes and re-creates the upstream SP-API subscriptions.

**2. Update the pipeline subscription:**

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

Update the `notification_subscriptions`, `selected_tables`, and any other changed meta fields.

See the [Subscriptions API](../api-usage-docs/subscriptions-api.md) for full PATCH documentation and the [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md) for the update notification endpoint.

---

## Deleting a notification subscription

Deleting a notification pipeline involves cleaning up both the upstream SP-API subscriptions and the Openbridge pipeline subscription.

**1. Delete the upstream SP-API subscription:**

```
DELETE https://service.api.openbridge.io/service/sp/notifications/{remote_identity_id}/{subscription_id}
```

This removes all upstream SP-API subscriptions and the registered SQS destination for the given identity. Returns `204 No Content` on success.

**2. Mark the pipeline subscription as invalid:**

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

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

See the [Subscription Configuration tutorial](./subscription-configuration.md#deleting-a-subscription) for more detail on subscription status management.
