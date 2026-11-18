# Amazon Advertising Marketing Stream S3 Pipeline

Marketing Stream S3 (product `110`) delivers Amazon dataset files through shared, regional S3 and SQS resources managed by Openbridge. Setup requires an Amazon Advertising connection and an Openbridge storage destination. For the customer-managed AWS workflow, see the [legacy Marketing Stream tutorial](./amazon-advertising-marketing-stream-pipeline-legacy.md).

## Prerequisites

- An [Openbridge JWT access token](../api-usage-docs/authentication-api.md).
- Your [Openbridge account and user IDs](./identity-configuration.md#step-1--look-up-your-account-and-user-ids).
- An Amazon Advertising [remote identity](./identity-configuration.md) (type `14`) with access to the advertiser.
- A configured [storage destination](./subscription-configuration.md#step-3--identify-your-storage-destination).

## Step 1 — Find your advertiser and datasets

```http
GET https://service.api.openbridge.io/service/amzadv/list-adv-v2/112
Authorization: Bearer <jwt>
```

Replace `112` with your remote identity ID. The response is an array of advertiser accounts. Use the selected account's `advertiserAccountId` as the string `advertiser_id`. To look up a known ID, append `?advertiser_id={advertiserAccountId}`.

Before registering datasets, verify that the ID matches a seller or vendor profile's top-level `id` from `GET /service/amzadv/profiles-only/112?profile_types=seller,vendor&is_manager=false`. The Subscriptions API checks this match when you save product `110`. For a manager identity, query with `is_manager=true` and include `"is_manager": "true"` in the pipeline's `product_parameters`. [Amazon Advertising profile lookup](../api-usage-docs/service-amazon-advertising-api.md#list-profiles)

```http
GET https://service.api.openbridge.io/service/amzadv/stream-s3/list-datasets
Authorization: Bearer <jwt>
```

```json
{
  "type": "AMSDatasets",
  "attributes": {
    "datasets": ["ads-performance-v1", "ads-converted-product-v1"]
  }
}
```

## Step 2 — Register the datasets with Amazon

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
      "advertiser_id": "589711999947333868",
      "datasets": ["ads-performance-v1"]
    }
  }
}
```

Send at least one supported dataset. The Service API selects the shared S3 bucket and notification queue based on the remote identity's region. Successful registration returns `200 OK` in the same request.

```json
{
  "type": "ServiceAmzAdvBrandMetricsStream",
  "advertiser_id": "589711999947333868",
  "attributes": {
    "amz_subscription_ids": {
      "ads-performance-v1": "AMAZON_STREAM_SUBSCRIPTION_ID"
    }
  }
}
```

Save the complete map at `attributes.amz_subscription_ids`. Keep each dataset key exactly as returned. Registrations are made one dataset at a time, so a failed multi-dataset request can leave Amazon subscriptions that need cleanup before retrying.

## Step 3 — Create the Openbridge pipeline

Send the advertiser ID and the JSON-stringified dataset-to-subscription-ID map as `product_parameters`. Use the remote identity from Step 1 and your Openbridge storage group. The two required product parameters are `advertiser_id` and `amz_subscription_ids`. The Subscriptions API stores the map as a string, and the Service API reads it back for updates and deletes. [Subscriptions API](../api-usage-docs/subscriptions-api.md)

```http
POST https://subscriptions.api.openbridge.io/v2/sub
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 110,
      "name": "My Marketing Stream",
      "status": "active",
      "date_start": "2026-11-18T00:00:00Z",
      "remote_identity": 112,
      "storage_group": 1,
      "product_parameters": {
        "advertiser_id": "589711999947333868",
        "amz_subscription_ids": "{\"ads-performance-v1\":\"AMAZON_STREAM_SUBSCRIPTION_ID\"}"
      }
    }
  }
}
```

Replace the example IDs and start date with your values. Save the Openbridge subscription ID from the `201 Created` response.

## Update the dataset selection

```http
PATCH https://service.api.openbridge.io/service/amzadv/stream-s3/update/{remote_identity_id}/{subscription_id}
Authorization: Bearer <jwt>
Content-Type: application/json
```

Use the Openbridge subscription ID and send the same body as in Step 2 with the existing advertiser ID and the **full desired dataset list**. Check the list against the supported IDs before sending it. The service archives every Amazon subscription in the stored map before registering the requested datasets, including datasets you keep. This can interrupt delivery, and a failed update can leave the previous streams archived.

After `200 OK`, send `PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}` with `data.type` set to `Subscription`, `data.id` set to the Openbridge subscription ID, and the new JSON-stringified map in `data.attributes.product_parameters.amz_subscription_ids`. Replace the entire map so subsequent updates and deletes use the current Amazon IDs.

## Delete the pipeline

```http
DELETE https://service.api.openbridge.io/service/amzadv/stream-s3/delete/{remote_identity_id}/{subscription_id}
Authorization: Bearer <jwt>
```

The Service API archives the Amazon streams using the pipeline's stored metadata. After `204 No Content`, mark the Openbridge subscription invalid with `PATCH https://subscriptions.api.openbridge.io/v2/sub/{subscription_id}` and this body. [Subscription status management](./subscription-configuration.md#deleting-a-subscription)

```json
{
  "data": {
    "type": "Subscription",
    "id": "12345",
    "attributes": {"status": "invalid"}
  }
}
```

## Clean up orphaned Amazon streams

Use the cleanup endpoint if a registration left Amazon streams without an active Openbridge pipeline.

```http
DELETE https://service.api.openbridge.io/service/amzadv/stream-s3/delete-orphaned/{remote_identity_id}/{advertiser_id}
Authorization: Bearer <jwt>
```

This endpoint archives **all** streams returned for the advertiser except those already archived or suspended. It returns `204 No Content` on success and `400 Bad Request` if any active product `110` subscription exists for the remote identity.
