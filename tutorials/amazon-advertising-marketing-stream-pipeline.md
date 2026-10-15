# Amazon Advertising Marketing Stream S3 Pipeline

Marketing Stream S3 uses **`/service/amzadv/stream-s3`** in the Service API. The managed S3 delivery flow uses this endpoint prefix; `/stream-v2` belongs to the [legacy tutorial](./amazon-advertising-marketing-stream-pipeline-legacy.md).

Amazon delivers dataset files to S3, with queue notifications used by Openbridge to process the files into your configured storage destination. Openbridge provisions and manages these delivery resources in its own AWS account. **Customers do not need an AWS account, an IAM role ARN, or a CloudFormation template.**

## Prerequisites

- A [JWT access token](../api-usage-docs/authentication-api.md).
- Your [account and user IDs](./identity-configuration.md#step-1--look-up-your-account-and-user-ids).
- An Amazon Advertising remote identity (type `14`) with access to the advertiser account.
- A configured [storage destination](./subscription-configuration.md#step-3--identify-your-storage-destination).

## Step 1 — Choose or create a remote identity

Follow the [Identity Configuration tutorial](./identity-configuration.md) to connect an Amazon Advertising account through OAuth, or list existing valid identities:

```http
GET https://remote-identity.api.openbridge.io/ri?remote_identity_type=14&invalid_identity=0
Authorization: Bearer <jwt>
```

Record the identity's `id`. The service uses its `region` (`na`, `eu`, or `fe`) to select the Amazon API and AWS delivery region; you do not send a region in the create request.

## Step 2 — Select an advertiser account

Use the new advertiser-account lookup, which does not require a profile ID:

```http
GET https://service.api.openbridge.io/service/amzadv/list-adv-v2/112
Authorization: Bearer <jwt>
```

Replace `112` with your remote identity ID. The service returns a flat array of Amazon `advertiserAccounts` records and collects all pages from Amazon. Record the selected record's `advertiserAccountId` as `advertiser_id`. To filter the lookup, append `?advertiser_id={advertiserAccountId}`.

This flow uses advertiser account IDs for all requests. Profile lookup and profile-scoped advertiser lookup are no longer setup steps. The service request does not use `profile_type`, but the product `110` subscription schema still requires it; retain the account type (`ads`, `dsp`, or `managedDsp`) for Step 5.

## Step 3 — Select datasets

Marketing Stream S3 uses **product ID `110`** with stage ID **`1000`** for every dataset selection. Retrieve the valid dataset IDs:

```http
GET https://service.api.openbridge.io/service/amzadv/stream-s3/list-datasets
Authorization: Bearer <jwt>
```

The endpoint returns a JSON array:

```json
{
  "data": {
    "type": "AMSDatasets",
    "attributes": {
      "datasets": [
        "ads-performance-v1",
        "ads-converted-product-v1"
      ]
    }
  }
}
```

The stage ID remains `1000` whether you select one dataset or both. All selected datasets use the shared notification queue and bucket returned in Step 4.

## Step 4 — Provision managed delivery resources

```http
POST https://service.api.openbridge.io/service/amzadv/stream-s3/112
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "advertiser_id": "ADVERTISER_ACCOUNT_ID",
      "datasets": ["ads-performance-v1", "ads-converted-product-v1"]
    }
  }
}
```

Use the advertiser account ID from Step 2. These are the two setup fields consumed by the new implementation; omit `role_arn`, `aws_account_id`, `profile_id`, and `profile_type`.

### Poll the asynchronous operation

The service returns `202 Accepted` and a `Location` header:

```http
Location: https://service.api.openbridge.io/service/amzadv/stream/poll-async/{request_id}
```

```json
{
  "data": {
    "type": "AmazonAdvertisingBrandMetricsStream",
    "id": "ADVERTISER_ACCOUNT_ID",
    "attributes": {"status": "CREATING"}
  }
}
```

Send authenticated `GET` requests to the returned `Location` using the same user token. Poll while the HTTP status is `202`, for example every two seconds with an application timeout. Continue only after `200 OK`; handle terminal errors before creating the pipeline subscription. The shared polling path remains `/stream/poll-async`, for managed S3 delivery operations.

The completed response uses the following `data` envelope:

```json
{
  "data": {
    "type": "ServiceAmzAdvBrandMetricsStream",
    "advertiser_id": "589711999947333868",
    "attributes": {
      "sqs_notification_url": "https://sqs.us-east-1.amazonaws.com/699059249070/ams-dev-ri6073-589711999947333868-s3-notifications",
      "bucket": "openbridge-ams-us-east-1-589711999947333868",
      "amz_subscription_ids": {
        "ads-performance-v1": "amzn1.ads-stream.sub1.4VzvRZFtnSqGFKLhHomypB",
        "ads-converted-product-v1": "amzn1.ads-stream.sub1.6sGplvMSZ73EW51WDlnM6w"
      }
    }
  }
}
```

All selected datasets share `sqs_notification_url` and `bucket`. Save those values and the complete `amz_subscription_ids` map, preserving the hyphenated dataset keys. The service no longer returns `queue_urls`, `dataset_params`, or a per-dataset queue ARN.

The service worker and shared polling handler currently store and return the completed object without the outer `data` wrapper. Clients supporting that implementation should also accept the unwrapped object (`response.attributes` instead of `response.data.attributes`).

## Step 5 — Create the pipeline subscription

Create the pipeline through the [Subscriptions API (v2)](../api-usage-docs/subscriptions-api.md):

```http
POST https://subscriptions.api.openbridge.io/v2/sub
Authorization: Bearer <jwt>
Content-Type: application/json
```

Prepare `product_parameters` for product `110`:

| Key | Value |
|---|---|
| `advertiser_id` | Required nonempty alphanumeric string from Step 2 |
| `selected_tables` | Required JSON-stringified nonempty array of unique dataset ID strings |
| `stage_ids` | Optional; when supplied, use `"[1000]"` for this product |
| `profile_type` | Required string: `ads`, `dsp`, or `managedDsp` |
| `sqs_notification_url` | Required nonempty string: the shared notification queue URL from Step 4 |
| `bucket` | Save the shared bucket name from Step 4 |
| `amz_subscription_ids` | Save the complete map from Step 4 as a JSON string; required by the service update/delete handlers |

Set `remote_identity` at the top level. An AWS IAM role parameter is not part of this setup. The product schema allows additional properties, so retain `bucket` and `amz_subscription_ids` alongside its required fields. `queue_urls` and `dataset_params` are no longer required by the schema.

The schema defines `selected_tables` and `stage_ids` as arrays, but the v2 subscription validator requires JSON-encoded strings in the request and decodes them before validation. `sqs_notification_url` is a plain URL string, copied directly from the service response. Although its schema description still refers to a stringified dataset map, the service returns one shared URL.

**Integration limitation:** the product `110` resource validator still reads the removed `queue_urls` and `dataset_params` fields. The template below satisfies the corrected schema after selection-array decoding, but that validator must also be aligned with the new fields for end-to-end subscription creation.

The following is a request **template** for one dataset. Replace all account, destination, advertiser, and resource examples with your values:

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 110,
      "name": "My Marketing Stream v2",
      "status": "active",
      "date_start": "2026-10-13T00:00:00Z",
      "remote_identity": 112,
      "storage_group": 1,
      "product_parameters": {
        "advertiser_id": "589711999947333868",
        "profile_type": "ads",
        "sqs_notification_url": "https://sqs.us-east-1.amazonaws.com/123456789012/example-queue",
        "bucket": "example-openbridge-managed-bucket",
        "amz_subscription_ids": "{\"ads-performance-v1\":\"AMAZON_STREAM_SUBSCRIPTION_ID\"}",
        "selected_tables": "[\"ads-performance-v1\"]",
        "stage_ids": "[1000]"
      }
    }
  }
}
```

For multiple datasets, include every selected dataset in `amz_subscription_ids` and `selected_tables`, and keep `stage_ids` as `"[1000]"`. Keep the single shared `sqs_notification_url` and `bucket`.

## Updating a marketing stream subscription

The current service URL configuration exposes only the update worker route:

```http
PATCH https://service.api.openbridge.io/service/amzadv/stream-s3/update/{remote_identity_id}/{co_id}/{subscription_id}
```

This route calls `update_stack` and requires an existing ConsoleOps request ID (`co_id`). It is not the customer-facing async entry point. The `update` handler that creates that request and returns a polling `Location` is currently not routed. A customer-facing dataset update cannot be started through the documented public endpoints until that route is restored; do not create a `co_id` or call the worker directly.

When the customer-facing update entry point is available, its handler expects the stored `advertiser_id` and the **full desired dataset list**, not just additions, using the same body as Step 4. The implementation archives **all existing Amazon stream subscriptions** and registers the requested datasets again, including retained datasets. Allow for a delivery interruption.

After a successful managed resource update, update the pipeline:

```http
PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
Authorization: Bearer <jwt>
Content-Type: application/json
```

Send `data.type: "Subscription"`, `data.id` equal to the subscription ID, and `data.attributes.product_parameters` containing the refreshed `sqs_notification_url`, `bucket`, and JSON-stringified `amz_subscription_ids`, plus JSON-stringified `selected_tables` and optional `stage_ids`. Preserve the required `advertiser_id` and `profile_type`. Replace the complete Amazon subscription ID map, because IDs can change. The product validation limitation in Step 5 also applies to updates. Omitted product parameter keys keep their stored values.

## Deleting a marketing stream subscription

First archive the registered Amazon streams while their metadata is still available:

```http
DELETE https://service.api.openbridge.io/service/amzadv/stream-s3/delete/{remote_identity_id}/{subscription_id}
Authorization: Bearer <jwt>
```

After `204 No Content`, mark the pipeline subscription invalid:

```http
PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Subscription",
    "id": "12345",
    "attributes": {"status": "invalid"}
  }
}
```

The reviewed delete handler archives Amazon stream subscriptions; it does not delete the managed S3 bucket or SQS queues. See [subscription status management](./subscription-configuration.md#deleting-a-subscription) for pipeline behavior.
