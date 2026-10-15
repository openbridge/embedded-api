# Service API: Amazon Advertising

> **Amazon Advertising API reference**: [https://advertising.amazon.com/API/docs/en-us](https://advertising.amazon.com/API/docs/en-us)

## When to use

Use these endpoints when configuring Amazon Advertising subscriptions. Before creating a subscription you need a `profile_id` — the numeric ID of the advertiser's Amazon Advertising account. Brand IDs are needed for Sponsored Brands report subscriptions.

---

## Prerequisites

- A `remote_identity_id` of type **Amazon Advertising** (remote identity type: `amazon-advertising`). See [Remote Identity API](./remote-identity-api.md).
- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### List profiles

Returns the Amazon Advertising profiles accessible to the connected identity. Use the `profile_id` from the response when creating a subscription.

```
GET /service/amzadv/profiles-only/{remote_identity_id}
```

**Query parameters**

| Parameter | Type | Description |
|---|---|---|
| `profile_types` | string | Comma-separated filter: `seller`, `vendor`, `dsp`, `attribution`. Omit to return all types. |
| `is_manager` | string | `true` if the identity is connected to a manager account, `false` otherwise. |

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/profiles-only/112?profile_types=seller,vendor&is_manager=false
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": 4463883966959342,
    "type": "AmazonAdvertisingProfile",
    "attributes": {
      "country_code": "US",
      "currency_code": "USD",
      "daily_budget": 10.0,
      "timezone": "America/Los_Angeles",
      "account_info": {
        "id": "ENTITY1234567890",
        "type": "AmazonAdvertisingProfileAccountInfo",
        "attributes": {
          "marketplace_country": "US",
          "marketplace_string_id": "ATVPDKIKX0DER",
          "name": "My Seller Account",
          "type": "seller",
          "subType": "",
          "valid_payment_method": true
        }
      }
    }
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Profile ID (numeric) | Use as `profile_id` in subscription [`product_parameters`](./subscriptions-api.md) |
| `attributes.country_code` | ISO country code for this profile | — |
| `attributes.currency_code` | Currency for this profile's budget | — |
| `attributes.timezone` | Timezone used for reporting | — |
| `attributes.account_info.attributes.type` | Account type: `seller`, `vendor`, `dsp` | Use to select the correct product |
| `attributes.account_info.attributes.marketplace_string_id` | Amazon marketplace ID | — |
| `attributes.account_info.attributes.name` | Display name of the account | — |

> **Deprecation note**: `GET /amzadv/profiles/{remote_identity_id}` is deprecated and returns both profiles and brands in one call. Use `profiles-only` instead.

---

### List brands

Returns the brand portfolio for a given profile. Mainly used for to fetch brand metadata for specified profiles.

```
GET /service/amzadv/brands/{remote_identity_id}
```

**Query parameters**

| Parameter | Type | Description |
|---|---|---|
| `profiles` | string | Comma-separated list of `profile_id` values to scope the brand lookup. |

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/brands/5163?profiles=4463883966959342
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": "BRAND123456",
    "type": "AmazonAdvertisingProfileBrand",
    "attributes": {
      "brand_entity_id": "ENTITY_BRAND_123456",
      "brand_registry_name": "My Brand Name"
    }
  }
]
```

**Field reference**

| Field | Description |
|---|---|---|
| `id` | Brand ID |
| `attributes.brand_entity_id` |
| `attributes.brand_registry_name` |

---

### Check if profile is KDP

Returns whether the specified profile belongs to a Kindle Direct Publishing (KDP) account.

```
GET /service/amzadv/is-kdp/{remote_identity_id}/{profile_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/is-kdp/112/4463883966959342
Authorization: Bearer <jwt>
```

---

### DSP report field maps

Returns metadata about the field mappings available for DSP reports.

```
GET /service/amzadv/dsp/meta/maps
```

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/dsp/meta/maps
Authorization: Bearer <jwt>
```

---

### DSP report metrics

Returns the available metrics for DSP reports.

```
GET /service/amzadv/dsp/meta/metrics
```

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/dsp/meta/metrics
Authorization: Bearer <jwt>
```

---

### Test attribution report

Tests whether attribution reporting is available for a given profile.

```
GET /service/amzadv/attribution-report-test/{remote_identity_id}/{profile_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/attribution-report-test/112/4463883966959342
Authorization: Bearer <jwt>
```

---

### List advertisers

Returns a list of advertisers accessible under a given profile ID.

```
GET /service/amzadv/list-adv/{remote_identity_id}/{profile_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/list-adv/112/4463883966959342
Authorization: Bearer <jwt>
```

---

### Retrieve access token

Returns the current LWA (Login with Amazon) access token and client ID for the given identity. Use this when you need to call Amazon Advertising APIs directly.

```
GET /service/amzadv/token/{remote_identity_id}
```

Also available at `/service/lwa/token/{remote_identity_id}` (alias; the `/amzadv/token/` path is preferred for new integrations).

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/token/112
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "data": {
    "access_token": "Atza|...",
    "client_id": "amzn1.application-oa2-client.abc_123"
  }
}
```

---

### Marketing Stream v2

Marketing Stream v2 (product ID `110`) uses `/service/amzadv/stream-s3` and Openbridge-managed delivery resources. No customer AWS account, IAM role, or CloudFormation template is required. Follow the [Marketing Stream v2 pipeline tutorial](../tutorials/amazon-advertising-marketing-stream-pipeline.md) for requests, async response handling, and subscription metadata.

| Method | Path | Purpose |
|---|---|---|
| GET | `/service/amzadv/list-adv-v2/{remote_identity_id}` | List advertiser accounts; optional `advertiser_id` filter |
| POST | `/service/amzadv/stream-s3/{remote_identity_id}` | Provision resources and register selected datasets |
| GET | `/service/amzadv/stream/poll-async/{request_id}` | Poll the `Location` returned by create or update |
| PATCH | `/service/amzadv/stream-s3/update/{remote_identity_id}/{co_id}/{subscription_id}` | Internal update worker; requires an existing ConsoleOps request |
| DELETE | `/service/amzadv/stream-s3/delete/{remote_identity_id}/{subscription_id}` | Archive registered Amazon streams |

Create and the update handler accept `data.attributes.advertiser_id` and a nonempty `data.attributes.datasets` array containing `ads-performance-v1` and/or `ads-converted-product-v1`. There is currently no routed managed S3 dataset-list endpoint.

Completed operations return a shared `sqs_notification_url` and `bucket`, plus `amz_subscription_ids` keyed by dataset ID. They no longer return per-dataset `queue_urls` or `dataset_params`. Product `110` requires `advertiser_id`, `sqs_notification_url`, `selected_tables`, and `profile_type`; see the tutorial for wire encoding, additional lifecycle metadata, and the current resource validation limitation.

For the older `/stream-v2` customer-managed AWS flow, see the [legacy tutorial](../tutorials/amazon-advertising-marketing-stream-pipeline-legacy.md).

The customer-facing async update handler is currently not routed. The update worker listed above is not a customer entry point; see the tutorial for this limitation.
