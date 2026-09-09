# Amazon Notifications API Pipeline

## Overview

This tutorial follows the customer workflow for a unified Amazon SP-API Notifications pipeline, **product ID `107`**. Customers configure prerequisite AWS roles once, select an Amazon identity and notification datasets, choose an AWS region, and provision the pipeline. The service automatically routes each notification type through SQS or EventBridge and delivers events through Firehose to S3.

The original SQS-only product (`86`) is **legacy**. Use its endpoints only to modify or delete existing subscriptions; see [Legacy subscription maintenance](#legacy-subscription-maintenance).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Configure AWS prerequisite roles](#step-1--configure-aws-prerequisite-roles)
- [Step 2 — Choose or create a remote identity](#step-2--choose-or-create-a-remote-identity)
- [Step 3 — Select notification datasets](#step-3--select-notification-datasets)
- [Step 4 — Choose an AWS region and provision notifications](#step-4--choose-an-aws-region-and-provision-notifications)
- [Step 5 — Store provisioning results and create the pipeline subscription](#step-5--store-provisioning-results-and-create-the-pipeline-subscription)
- [Updating a unified subscription](#updating-a-unified-subscription)
- [Deleting a unified subscription](#deleting-a-unified-subscription)
- [Legacy subscription maintenance](#legacy-subscription-maintenance)

---

## Prerequisites

- A JWT access token — see [Authentication API](../api-usage-docs/authentication-api.md).
- Your account ID and user ID — see [Identity Configuration Step 1](./identity-configuration.md#step-1--look-up-your-account-and-user-ids).
- An active Amazon Seller Central or Vendor Central account.
- A storage destination — see [Subscription Configuration Step 3](./subscription-configuration.md#step-3--identify-your-storage-destination).
- Access to deploy the Openbridge prerequisite CloudFormation template in the customer's AWS account.

## Step 1 — Configure AWS prerequisite roles

If the customer has not already configured the unified notification prerequisites, deploy the [Openbridge unified notifications CloudFormation template](https://openbridge-customer-templates-production.s3.us-east-1.amazonaws.com/amazon-notifications-api/notifications-api-prereq.yaml) in their AWS account.

The template creates the IAM roles the service uses to provision and operate notification resources. Copy these stack outputs:

| Stack output | Use |
|---|---|
| `ManagementRoleArn` | Supply as `role_arn`; default role name is `openbridge-spapi-cf-manager` |
| `EventBridgeToFirehoseRoleArn` | Supply as `eb_to_fh_role_arn`; default role name is `openbridge-eventbridge-to-firehose-role` |
| `FirehoseDeliveryRoleArn` | The service discovers the fixed role `openbridge-spapi-firehose-role` internally |

Reuse the prerequisite roles for subsequent subscriptions. **Do not run a separate CloudFormation stack for every SQS subscription.** The service provisions the per-pipeline queues, delivery streams, and other resources. Use the AWS region covered by the prerequisite stack's permissions when provisioning; the template's resource policies include its deployment region.

## Step 2 — Choose or create a remote identity

Select an Amazon Seller identity (type `17`) or Amazon Vendor identity (type `18`). To create one, follow the [Identity Configuration tutorial](./identity-configuration.md).

To list existing seller identities:

```http
GET https://remote-identity.api.openbridge.io/sri?remote_identity_type=17&invalid_identity=0
Authorization: Bearer <jwt>
```

For vendor identities, replace `17` with `18`. Save the selected identity's `id`; the examples below use seller identity `362`.

An identity with an active legacy SQS pipeline (product `86`) cannot provision a unified pipeline. Cancel the legacy pipeline before creating the new one.

## Step 3 — Select notification datasets

Fetch the available datasets using the unified endpoint:

```http
GET https://service.api.openbridge.io/service/sp/notifications-unified/list-notification-types?account_type=seller
Authorization: Bearer <jwt>
```

Use `account_type=seller` for identity type `17`, or `account_type=vendor` for type `18`. Let the customer choose from the returned `notification_types` list. It includes both SQS and EventBridge types; the service selects the delivery path automatically.

The examples use `ACCOUNT_STATUS_CHANGED` (SQS) and `BRANDED_ITEM_CONTENT_CHANGE` (EventBridge), both supported for seller identities. Pass the selected names as an array when provisioning.

## Step 4 — Choose an AWS region and provision notifications

Ask the customer to select their preferred AWS region. The service currently accepts `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`, `af-south-1`, and `ap-east-1`. This is the deployment region for AWS resources, separate from the identity's Amazon SP-API region. Ensure the prerequisite roles allow resources in the selected region.

Call the provisioning endpoint with the identity ID, chosen datasets, AWS region, and stack output ARNs:

```http
POST https://service.api.openbridge.io/service/sp/notifications-unified/362
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "eb_to_fh_role_arn": "arn:aws:iam::123456789012:role/openbridge-eventbridge-to-firehose-role",
      "role_arn": "arn:aws:iam::123456789012:role/openbridge-spapi-cf-manager",
      "notification_types": ["ACCOUNT_STATUS_CHANGED", "BRANDED_ITEM_CONTENT_CHANGE"],
      "aws_region": "us-east-1"
    }
  }
}
```

`role_arn`, `notification_types`, `eb_to_fh_role_arn` and `aws_region` are required.

**Example response — `207 Multi-Status`:**

```json
{
  "data": {
    "type": "SPAPINotifications",
    "attributes": {
      "subscriptions": {
        "BRANDED_ITEM_CONTENT_CHANGE": "sub_eb456",
        "ACCOUNT_STATUS_CHANGED": "sub_sqs123"
      },
      "failed": {},
      "meta": {
        "shared_pipeline_id": "acd744566393dd48",
        "s3_bucket_name": "ob-sp-notifications-123456789012-us-east-1",
        "s3_notification_prefix": "acd744566393dd48/",
        "s3_notification_queue_arn": "arn:aws:sqs:us-east-1:123456789012:ob-sp-notifications-acd744566393dd48-s3-events",
        "s3_notification_configuration_id": "ob-sp-notifications-acd744566393dd48",
        "eventbridge_pipeline_id": "42e3362c5564225d",
        "event_bus_name": "aws.partner/sellingpartnerapi.amazon.com/123456789012/amzn1.sellerapps.app.example",
        "eventbridge_rule_id": "ob-sp-notifications-rule-42e3362c5564225d",
        "eventbridge_target_id": "ob-sp-notifications-target-42e3362c5564225d",
        "eventbridge_destination_id": "dest_eb456",
        "sqs_pipeline_id": "247f910d878122ed",
        "sqs_pipeline_name": "ob-sp-notifications-247f910d878122ed",
        "sqs_destination_id": "dest_sqs123",
        "sqs_source_queue_arn": "arn:aws:sqs:us-east-1:123456789012:ob-sp-notifications-247f910d878122ed-queue",
        "eventbridge_pipe_arn": "arn:aws:pipes:us-east-1:123456789012:pipe/ob-sp-notifications-247f910d878122ed",
        "firehose_arn": "arn:aws:firehose:us-east-1:123456789012:deliverystream/ob-sp-notifications-247f910d878122ed",
        "sqs_pipe_role_arn": "arn:aws:iam::123456789012:role/Amazon_EventBridge_Pipe_ob-sp-notifications-247f910d878122ed",
        "sqs_firehose_role_arn": "arn:aws:iam::123456789012:role/Amazon_Firehose_ob-sp-notifications-247f910d878122ed",
        "sqs_pipe_log_group": "/aws/vendedlogs/pipes/ob-sp-notifications-247f910d878122ed",
        "sqs_firehose_log_group": "/aws/kinesisfirehose/ob-sp-notifications-247f910d878122ed"
      }
    }
  }
}
```

A `207` response is also returned when every selected type succeeds. Inspect `data.attributes.failed` and surface any per-type failures before proceeding. If provisioning returns an error, resolve it before creating the Openbridge pipeline. See the [unified endpoint reference](../api-usage-docs/service-amazon-sp-api.md#unified-notifications) for error and lifecycle details.

## Step 5 — Store provisioning results and create the pipeline subscription

Create the Openbridge pipeline using **product `107`**:

```http
POST https://subscriptions.api.openbridge.io/v2/sub
Authorization: Bearer <jwt>
Content-Type: application/json
```

Store the provisioning results in subscription product metadata (SPM), using the v2 API's `product_parameters` object. **Preserve every field in `data.attributes.meta`**, including fields for both delivery paths. Deletion uses this metadata to find and clean up resources.

| Product parameter | Value |
|---|---|
| `identity_type` | `seller` or `vendor`, matching the chosen identity |
| `role_arn` | Management role ARN sent to provisioning |
| `eb_to_fh_role_arn` | EventBridge-to-Firehose role ARN, when used |
| `aws_region` | AWS region sent to provisioning |
| `selected_tables` | JSON-stringified array of successfully provisioned notification types |
| `notification_subscriptions` | JSON-stringified complete `data.attributes.subscriptions` map, as with the legacy SQS product |
| `notifications_meta` | JSON-stringified **complete** `data.attributes.meta` object; do not select only a subset of fields |

Store metadata as the `notifications_meta` JSON value, rather than flattening its fields into separate product parameters. The cleanup implementation reads this object together with `role_arn`, `aws_region`, and `notification_subscriptions`.

The example below uses the successful provisioning response from Step 4. Review any entries in `failed` before creating the subscription; resolve them or explicitly accept the successfully provisioned subset.

```http
POST https://subscriptions.api.openbridge.io/v2/sub
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 107,
      "name": "My Unified SP-API Notifications Pipeline",
      "status": "active",
      "date_start": "2026-09-09T00:00:00Z",
      "remote_identity": 362,
      "storage_group": 1,
      "product_parameters": {
        "identity_type": "seller",
        "role_arn": "arn:aws:iam::123456789012:role/openbridge-spapi-cf-manager",
        "eb_to_fh_role_arn": "arn:aws:iam::123456789012:role/openbridge-eventbridge-to-firehose-role",
        "aws_region": "us-east-1",
        "selected_tables": "[\"BRANDED_ITEM_CONTENT_CHANGE\",\"ACCOUNT_STATUS_CHANGED\"]",
        "notification_subscriptions": "{\"BRANDED_ITEM_CONTENT_CHANGE\":\"sub_eb456\",\"ACCOUNT_STATUS_CHANGED\":\"sub_sqs123\"}",
        "notifications_meta": "{\"shared_pipeline_id\":\"acd744566393dd48\",\"s3_bucket_name\":\"ob-sp-notifications-123456789012-us-east-1\",\"s3_notification_prefix\":\"acd744566393dd48/\",\"s3_notification_queue_arn\":\"arn:aws:sqs:us-east-1:123456789012:ob-sp-notifications-acd744566393dd48-s3-events\",\"s3_notification_configuration_id\":\"ob-sp-notifications-acd744566393dd48\",\"eventbridge_pipeline_id\":\"42e3362c5564225d\",\"event_bus_name\":\"aws.partner/sellingpartnerapi.amazon.com/123456789012/amzn1.sellerapps.app.example\",\"eventbridge_rule_id\":\"ob-sp-notifications-rule-42e3362c5564225d\",\"eventbridge_target_id\":\"ob-sp-notifications-target-42e3362c5564225d\",\"eventbridge_destination_id\":\"dest_eb456\",\"sqs_pipeline_id\":\"247f910d878122ed\",\"sqs_pipeline_name\":\"ob-sp-notifications-247f910d878122ed\",\"sqs_destination_id\":\"dest_sqs123\",\"sqs_source_queue_arn\":\"arn:aws:sqs:us-east-1:123456789012:ob-sp-notifications-247f910d878122ed-queue\",\"eventbridge_pipe_arn\":\"arn:aws:pipes:us-east-1:123456789012:pipe/ob-sp-notifications-247f910d878122ed\",\"firehose_arn\":\"arn:aws:firehose:us-east-1:123456789012:deliverystream/ob-sp-notifications-247f910d878122ed\",\"sqs_pipe_role_arn\":\"arn:aws:iam::123456789012:role/Amazon_EventBridge_Pipe_ob-sp-notifications-247f910d878122ed\",\"sqs_firehose_role_arn\":\"arn:aws:iam::123456789012:role/Amazon_Firehose_ob-sp-notifications-247f910d878122ed\",\"sqs_pipe_log_group\":\"/aws/vendedlogs/pipes/ob-sp-notifications-247f910d878122ed\",\"sqs_firehose_log_group\":\"/aws/kinesisfirehose/ob-sp-notifications-247f910d878122ed\"}"
      }
    }
  }
}
```

Replace the account, user, identity, storage group, name, and start date with the customer's values. Use the role ARNs and region from the provisioning request, and replace the JSON-stringified `selected_tables`, `notification_subscriptions`, and complete `notifications_meta` values with the actual provisioning results. Save the returned **Openbridge subscription ID** for updates and deletion; the per-type IDs returned by provisioning are upstream Amazon IDs.

See the [Subscription Configuration tutorial](./subscription-configuration.md) and [Subscriptions API](../api-usage-docs/subscriptions-api.md) for the general subscription request contract.

## Updating a unified subscription

1. Call `PATCH /service/sp/notifications-unified/{remote_identity_id}/{subscription_id}` with the full provisioning body from Step 4 and the customer's revised selection. Use the Openbridge subscription ID in the path.
2. Inspect the returned `subscriptions`, `failed`, and `meta`. Persist the complete returned maps through `PATCH /v2/sub/{subscription_id}` on the Subscriptions API, using the same product parameter mapping as Step 5 and updating any changed role/region values.

The service disables upstream subscriptions before creating replacements. Eligible SQS infrastructure is reused when the AWS account and region are unchanged and the new selection includes SQS types. An update is not atomic: provisioning failure can leave the previous upstream subscriptions disabled.

`product_parameters` updates merge supplied keys. Replace the complete `notifications_meta` JSON value with the latest response rather than merging old path-specific metadata into it.

## Deleting a unified subscription

First, clean up the upstream subscriptions and AWS delivery resources:

```http
DELETE https://service.api.openbridge.io/service/sp/notifications-unified/362/12345
Authorization: Bearer <jwt>
```

Here `12345` is the Openbridge subscription ID. Cleanup requires the stored metadata from Step 5. On `204 No Content`, mark the Openbridge subscription invalid:

```http
PATCH https://subscriptions.api.openbridge.io/v2/sub/12345
Authorization: Bearer <jwt>
Content-Type: application/json
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

The service removes the pipeline's resources while retaining the shared S3 bucket and objects, shared EventBridge bus/destination, and prerequisite customer roles. If cleanup fails, retain the metadata and resolve the failure before completing cancellation.

---

## Legacy subscription maintenance

> **Legacy:** The original SQS-only Notifications product (`86`) and `/sp/notifications` endpoints should only be used to modify or delete existing legacy SP notifications subscriptions. Create new subscriptions using the unified workflow above.

Existing legacy pipelines use two customer-configured SQS queues and store queue ARNs/URLs, `sqs_destination_id`, `notification_subscriptions`, and `selected_tables` in their product parameters. Keep those values available for maintenance. The legacy per-subscription CloudFormation queue setup does not apply to unified pipelines.

### Update an existing legacy subscription

To update an existing notification subscription (e.g., to change the subscribed notification types), use two requests:

**1. Update the upstream SP-API subscription:**

```
PATCH https://service.api.openbridge.io/service/sp/notifications/{remote_identity_id}/{subscription_id}
```

Include the updated `queue_arn` and `notification_types` in `data.attributes`:

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

This deletes and re-creates the upstream SP-API subscriptions. Use the Openbridge subscription ID in the path.

**2. Update the pipeline subscription:**

```
PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
```

Update the `notification_subscriptions`, `selected_tables`, and any other changed keys in `product_parameters` (partial merge — omitted keys keep their stored value).

See the [Subscriptions API (v2)](../api-usage-docs/subscriptions-api.md) for full PATCH documentation and the [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md) for the update notification endpoint.

---

### Delete an existing legacy subscription

Deleting a notification pipeline involves cleaning up both the upstream SP-API subscriptions and the Openbridge pipeline subscription.

**1. Delete the upstream SP-API subscription:**

```
DELETE https://service.api.openbridge.io/service/sp/notifications/{remote_identity_id}/{subscription_id}
```

This removes all upstream SP-API subscriptions and the registered SQS destination for the given identity. Returns `204 No Content` on success.

**2. Mark the pipeline subscription as invalid:**

```
PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
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
