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

This flow uses advertiser account IDs for all requests. The legacy profile-type selection (`ads`, `dsp`, `managedDsp`), profile lookup, and profile-scoped advertiser lookup are no longer setup steps.

## Step 3 — Select datasets and find the product

The new service accepts these dataset IDs:

| Dataset ID |
|---|
| `ads-performance-v1` |
| `ads-converted-product-v1` |

Choose a nonempty array, such as `["ads-performance-v1", "ads-converted-product-v1"]`. The reviewed service code has a dataset-list method but no `/stream-s3/list-datasets` route; the legacy `/stream-v2/list-datasets` returns datasets for the old flow.

Find the Marketing Stream v2 product in the [Products API](../api-usage-docs/products-api.md):

```http
GET https://subscriptions.api.openbridge.io/product?remote_identity_type=14&name__icontains=Marketing
Authorization: Bearer <jwt>
```

Follow pagination and confirm the product's name and `required_meta_fields`. Record its numeric `id` and retrieve its payload definitions:

```http
GET https://service.api.openbridge.io/service/products/product/{product_id}/payloads?stage_id__gte=1000
Authorization: Bearer <jwt>
```

Resolve the stages for your selected datasets from these definitions. Do not reuse legacy product `87`, legacy payload mappings, or example stage IDs. The new product ID and dataset-to-payload mappings are not established by the reviewed service implementation; its `109` reference is explicitly marked TODO.

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

The completed response has **top-level `attributes`**, unlike the initial `data.attributes` envelope. Example for one selected dataset:

```json
{
  "type": "ServiceAmzAdvBrandMetricsStream",
  "advertiser_id": "ADVERTISER_ACCOUNT_ID",
  "attributes": {
    "queue_urls": {
      "ads-performance-v1": "https://sqs.us-east-1.amazonaws.com/123456789012/example-queue"
    },
    "dataset_params": {
      "ads-performance-v1": {
        "amz_subscription_id": "AMAZON_STREAM_SUBSCRIPTION_ID",
        "bucket": "example-openbridge-managed-bucket",
        "queue": "arn:aws:sqs:us-east-1:123456789012:example-queue"
      }
    }
  }
}
```

Save both maps exactly as returned, including the hyphenated dataset keys. `queue_urls` contains queue URLs; `dataset_params` contains each Amazon subscription ID, bucket name, and queue ARN. These are Openbridge-managed resources, not customer AWS resources. The response type names shown above are the names currently emitted by the service.

## Step 5 — Create the pipeline subscription

Create the pipeline through the [Subscriptions API (v2)](../api-usage-docs/subscriptions-api.md):

```http
POST https://subscriptions.api.openbridge.io/v2/sub
Authorization: Bearer <jwt>
Content-Type: application/json
```

Prepare `product_parameters` using the selected product's catalog requirements:

| Key | Value |
|---|---|
| `advertiser_id` | Advertiser account ID from Step 2 |
| `queue_urls` | JSON-stringified complete `queue_urls` map from Step 4 |
| `dataset_params` | JSON-stringified complete `dataset_params` map from Step 4 |
| `selected_tables` | JSON-stringified array of selected dataset IDs |
| `stage_ids` | JSON-stringified array of corresponding stage IDs from Step 3 |

Set `remote_identity` at the top level. An AWS IAM role parameter is not part of this setup. Confirm any additional required metadata against the selected product before submitting.

The following is a request **template** for one dataset. Replace the product placeholder with the numeric product ID and the stage placeholder inside the JSON string with the actual numeric stage ID. Replace all account, destination, advertiser, and resource examples with your values:

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": "<marketing_stream_v2_product_id>",
      "name": "My Marketing Stream v2",
      "status": "active",
      "date_start": "2026-10-13T00:00:00Z",
      "remote_identity": 112,
      "storage_group": 1,
      "product_parameters": {
        "advertiser_id": "ADVERTISER_ACCOUNT_ID",
        "queue_urls": "{\"ads-performance-v1\":\"https://sqs.us-east-1.amazonaws.com/123456789012/example-queue\"}",
        "dataset_params": "{\"ads-performance-v1\":{\"amz_subscription_id\":\"AMAZON_STREAM_SUBSCRIPTION_ID\",\"bucket\":\"example-openbridge-managed-bucket\",\"queue\":\"arn:aws:sqs:us-east-1:123456789012:example-queue\"}}",
        "selected_tables": "[\"ads-performance-v1\"]",
        "stage_ids": "[<stage_id>]"
      }
    }
  }
}
```

For multiple datasets, include every selected dataset in both response maps and both selection arrays.

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

Send `data.type: "Subscription"`, `data.id` equal to the subscription ID, and `data.attributes.product_parameters` containing the newly stringified `queue_urls`, `dataset_params`, `selected_tables`, and `stage_ids`. Replace both resource maps with the complete successful response, because Amazon stream subscription IDs can change. Omitted product parameter keys keep their stored values.

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
