# Amazon Advertising Marketing Stream Pipeline

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Choose or create a remote identity](#step-1--choose-or-create-a-remote-identity)
- [Step 2 — Select a profile type](#step-2--select-a-profile-type)
- [Step 3 — Select a profile](#step-3--select-a-profile)
  - [Sponsored Ads profiles (seller/vendor)](#sponsored-ads-profiles-sellervendor)
  - [DSP profiles](#dsp-profiles)
- [Step 4 — (DSP only) Select an advertiser](#step-4--dsp-only-select-an-advertiser)
- [Step 5 — Select marketing stream datasets](#step-5--select-marketing-stream-datasets)
- [Step 6 — Provide an AWS IAM Role ARN and generate SQS queues](#step-6--provide-an-aws-iam-role-arn-and-generate-sqs-queues)
- [Step 7 — Create the pipeline subscription](#step-7--create-the-pipeline-subscription)
  - [Subscription meta fields](#subscription-meta-fields)
  - [Full example request (Sponsored Ads)](#full-example-request-sponsored-ads)
  - [Full example request (DSP)](#full-example-request-dsp)
- [Updating a marketing stream subscription](#updating-a-marketing-stream-subscription)
- [Deleting a marketing stream subscription](#deleting-a-marketing-stream-subscription)

---

## Overview

This tutorial walks through creating an Amazon Advertising Marketing Stream pipeline subscription end-to-end. The Marketing Stream product (product ID `87`) delivers near-real-time advertising performance data via Amazon's Marketing Stream API into SQS queues provisioned by Openbridge.

Three profile-type flows are supported:

| Profile type | Description |
|---|---|
| **Sponsored Ads** (`ads`) | Seller or Vendor accounts running Sponsored Products, Sponsored Brands, or Sponsored Display campaigns |
| **DSP** (`dsp`) | Demand-Side Platform accounts |
| **Managed DSP** (`managedDsp`) | DSP manager accounts acting on behalf of advertisers |

The flow mirrors the Openbridge website wizard: choose an identity, select a profile type, pick a profile (and advertiser for DSP), choose datasets, provide an AWS IAM Role ARN to provision SQS queues, and finally create the pipeline subscription.

---

## Prerequisites

- A JWT access token — see [Authentication API](../api-usage-docs/authentication-api.md)
- Your account ID and user ID — see [Identity Configuration Step 1](./identity-configuration.md#step-1--look-up-your-account-and-user-ids)
- An active Amazon Advertising account
- An AWS IAM Role ARN with permissions for Openbridge to provision SQS queues on your behalf
- A storage destination already configured — see [Subscription Configuration Step 3](./subscription-configuration.md#step-3--identify-your-storage-destination)

---

## Step 1 — Choose or create a remote identity

The Marketing Stream product requires an **Amazon Advertising** identity (remote identity type `14`).

### Create a new identity

If you do not have an identity yet, follow the [Identity Configuration tutorial](./identity-configuration.md) to create one via the OAuth flow. Amazon Advertising identities are region-specific — use the correct region for your marketplace:

| Region identifier | Region name |
|---|---|
| `na` | North America |
| `eu` | Europe |
| `fe` | Far East |

### List existing identities

To find an existing Amazon Advertising identity, list remote identities filtered by type:

```http
GET https://remote-identity.api.openbridge.io/ri?remote_identity_type=14&invalid_identity=0
Authorization: Bearer <jwt>
```

**Example response:**

```json
{
  "links": {
    "first": "https://remote-identity.api.openbridge.io/ri?remote_identity_type=14&invalid_identity=0&page=1",
    "last": "https://remote-identity.api.openbridge.io/ri?remote_identity_type=14&invalid_identity=0&page=1",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "RemoteIdentity",
      "id": "112",
      "attributes": {
        "name": "My Advertising Account",
        "created_at": "2024-01-15T12:00:00",
        "modified_at": "2024-06-01T08:30:00",
        "remote_unique_id": "amzn1.account.AEHZ5",
        "account_id": 1,
        "user_id": 1,
        "invalid_identity": 0,
        "region": "na",
        "email": "advertiser@example.com"
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

Record the identity `id` (e.g., `112`) and `region` (e.g., `na`) — you will need both in subsequent steps.

See the [Remote Identity API](../api-usage-docs/remote-identity-api.md) for full endpoint details.

---

## Step 2 — Select a profile type

Before fetching profiles, decide which profile type applies to your use case:

| Profile type value | Use case |
|---|---|
| `ads` | Seller or Vendor accounts (Sponsored Products, Sponsored Brands, Sponsored Display) |
| `dsp` | DSP advertiser accounts |
| `managedDsp` | DSP manager accounts operating on behalf of advertisers |

This choice determines the wizard flow, the available datasets, and how the SQS queue payload is constructed. Record your `profile_type` — you will use it in Steps 3, 5, and 6.

---

## Step 3 — Select a profile

### Sponsored Ads profiles (seller/vendor)

For `ads` profile types, fetch seller and vendor profiles:

```http
GET https://service.api.openbridge.io/service/amzadv/profiles-only/{remote_identity_id}?profile_types=seller,vendor
Authorization: Bearer <jwt>
```

Replace `{remote_identity_id}` with the identity ID from Step 1.

**Example response:**

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

Record the profile `id` (e.g., `4463883966959342`). For Sponsored Ads, the `advertiser_id` meta field will be set to `NOT_APPLICABLE`.

> **Note:** Profiles with `subType` of `AMAZON_ATTRIBUTION` are excluded and cannot be used with Marketing Stream.

### DSP profiles

For `dsp` profile types, fetch DSP profiles:

```http
GET https://service.api.openbridge.io/service/amzadv/profiles-only/{remote_identity_id}?profile_types=dsp
Authorization: Bearer <jwt>
```

For `managedDsp` profile types, fetch managed DSP accounts:

```http
GET https://service.api.openbridge.io/service/amzadv/profiles-only/{remote_identity_id}?profile_types=dsp&is_manager=true
Authorization: Bearer <jwt>
```

For managed DSP accounts, the response includes a `dsp_advertiser_id` field. Record this value — it is used as the `advertiser_id` in subsequent steps. For managed DSP, the `profile_id` meta field will be set to `NOT_APPLICABLE`.

See the [Service API: Amazon Advertising](../api-usage-docs/service-amazon-advertising-api.md) for full endpoint details.

---

## Step 4 — (DSP only) Select an advertiser

This step applies only to the `dsp` profile type. If your profile type is `ads` or `managedDsp`, skip to Step 5.

Fetch the advertisers available under your DSP profile:

```http
GET https://service.api.openbridge.io/service/amzadv/list-adv/{remote_identity_id}/{profile_id}
Authorization: Bearer <jwt>
```

Replace `{remote_identity_id}` with your identity ID and `{profile_id}` with the DSP profile ID from Step 3.

**Example response:**

```json
[
  {
    "id": "ADV123456",
    "type": "AmazonAdvertisingAdvertiser",
    "attributes": {
      "name": "My DSP Advertiser",
      "country": "US",
      "currency": "USD",
      "timezone": "America/Los_Angeles",
      "url": "https://example.com"
    }
  }
]
```

Record the advertiser `id` (e.g., `ADV123456`) — you will use it as the `advertiser_id` in the SQS payload and subscription meta.

---

## Step 5 — Select marketing stream datasets

Fetch the available marketing stream datasets for your region and profile type:

```http
GET https://service.api.openbridge.io/service/amzadv/stream-v2/list-datasets?region={region}&profile_type={profile_type}
Authorization: Bearer <jwt>
```

Replace `{region}` with your identity's region (e.g., `na`) and `{profile_type}` with the type from Step 2 (e.g., `ads` or `dsp`).

The response returns a list of dataset names. Below are the known datasets and their internal payload names:

### Sponsored Ads datasets

| Dataset name | Payload name |
|---|---|
| `sp-traffic` | `amzn_stream2_sp_traffic` |
| `sp-conversion` | `amzn_stream2_sp_conversion` |
| `budget-usage` | `amzn_stream2_budget_usage` |
| `sd-traffic` | `amzn_stream2_sd_traffic` |
| `sd-conversion` | `amzn_stream2_sb_conversion` |
| `sb-traffic` | `amzn_stream2_sb_traffic` |
| `sb-conversion` | `amzn_stream2_sd_conversion` |
| `sb-clickstream` | `amzn_stream2_sb_clickstream` |
| `sb-rich-media` | `amzn_stream2_sb_rich_media` |
| `sp-budget-recommendations` | `amzn_stream2_sp_budget_recommendations` |
| `sponsored-ads-campaign-diagnostics-recommendations` | `amzn_stream2_campaign_recommendations` |
| `campaigns` | `amzn_stream2_campaigns` |
| `adgroups` | `amzn_stream2_adgroups` |
| `ads` | `amzn_stream2_ads` |
| `targets` | `amzn_stream2_targets` |

### DSP datasets

| Dataset name | Payload name |
|---|---|
| `adsp-traffic` | `amzn_stream2_adsp_traffic` |
| `adsp-conversion` | `amzn_stream2_adsp_conversion` |
| `adsp-clickstream` | `amzn_stream2_adsp_clickstream` |
| `adsp-rich-media` | `amzn_stream2_adsp_rich_media` |
| `adsp-campaigns` | `amzn_stream2_adsp_campaigns` |
| `adsp-campaign-flights` | `amzn_stream2_adsp_campaign_flights` |
| `adsp-adgroups` | `amzn_stream2_adsp_adgroups` |

Choose the datasets you want to subscribe to and record them as an array (e.g., `["sp-traffic", "sp-conversion", "budget-usage"]`). You will pass this array in Step 6 and as a stringified JSON array in the subscription meta in Step 7.

---

## Step 6 — Provide an AWS IAM Role ARN and generate SQS queues

The Marketing Stream product requires an AWS IAM Role ARN that grants Openbridge permission to create and manage SQS queues in your AWS account. Openbridge uses this role to provision dedicated SQS queues for each selected dataset.

### Create the SQS queues

```
POST https://service.api.openbridge.io/service/amzadv/stream-v2/{remote_identity_id}
```

Replace `{remote_identity_id}` with the identity ID from Step 1.

**Example request (Sponsored Ads):**

```http
POST https://service.api.openbridge.io/service/amzadv/stream-v2/112
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "role_arn": "arn:aws:iam::123456789012:role/openbridge-marketing-stream-role",
      "datasets": ["sp-traffic", "sp-conversion", "budget-usage"],
      "profile_type": "ads",
      "profile_id": "4463883966959342"
    }
  }
}
```

**Example request (DSP):**

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "role_arn": "arn:aws:iam::123456789012:role/openbridge-marketing-stream-role",
      "datasets": ["adsp-traffic", "adsp-conversion"],
      "profile_type": "dsp",
      "advertiser_id": "ADV123456"
    }
  }
}
```

| Field | Description |
|---|---|
| `role_arn` | AWS IAM Role ARN granting Openbridge permissions to manage SQS queues |
| `datasets` | Array of dataset names from Step 5 |
| `profile_type` | `"ads"` for Sponsored Ads, `"dsp"` for DSP and Managed DSP |
| `profile_id` | Required when `profile_type` is `"ads"` — the profile ID from Step 3 |
| `advertiser_id` | Required when `profile_type` is `"dsp"` — the advertiser ID from Step 4 (or the `dsp_advertiser_id` for managed DSP) |

### Async response handling

This endpoint returns an **asynchronous response**. The initial response includes a `Location` header with a polling URL. Poll this URL until you receive an HTTP `200` response with the queue data.

- **Poll interval:** 2 seconds
- **Timeout:** up to 13 minutes (the queue provisioning process can take several minutes)

**Example success response:**

```json
{
  "data": {
    "type": "AmazonAdvertisingStreamV2",
    "attributes": {
      "queue_urls": {
        "sp-traffic": "https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-sp-traffic-abc123",
        "sp-conversion": "https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-sp-conversion-abc123",
        "budget-usage": "https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-budget-usage-abc123"
      },
      "dataset_params": {
        "sp-traffic": {"stream_id": "str_abc123"},
        "sp-conversion": {"stream_id": "str_def456"},
        "budget-usage": {"stream_id": "str_ghi789"}
      }
    }
  }
}
```

Save the `queue_urls` and `dataset_params` values from the response — they are required for the pipeline subscription meta in Step 7.

---

## Step 7 — Create the pipeline subscription

With all the pieces gathered from the previous steps, create the pipeline subscription for product `87` (Amazon Advertising Marketing Stream).

```
POST https://subscriptions.api.openbridge.io/sub
```

For general detail on subscription creation, see the [Subscription Configuration tutorial](./subscription-configuration.md).

### Subscription meta fields

This product requires 9 meta fields in `subscription_product_meta_attributes`.

| `data_key` | `data_format` | Source | Description |
|---|---|---|---|
| `remote_identity_id` | STRING | Step 1 | The identity ID as a string |
| `profile_id` | STRING | Step 3 | The advertising profile ID. Set to `"NOT_APPLICABLE"` for managed DSP. |
| `profile_type` | STRING | Step 2 | `"ads"`, `"dsp"`, or `"managedDsp"` |
| `advertiser_id` | STRING | Step 4 | The advertiser ID. Set to `"NOT_APPLICABLE"` for Sponsored Ads (`ads`). |
| `aws_iam_role_arn` | STRING | Step 6 | The AWS IAM Role ARN provided in the SQS generation request |
| `queue_urls` | JSON | Step 6 | Stringified `queue_urls` map from the SQS generation response |
| `dataset_params` | JSON | Step 6 | Stringified `dataset_params` map from the SQS generation response |
| `selected_tables` | JSON | Step 5 | Stringified array of selected dataset names |
| `stage_ids` | JSON | Step 5 | Stringified array of stage IDs corresponding to the selected datasets |

> **Note:** The `stage_ids` are resolved by mapping each selected dataset name to its corresponding payload stage via the [Products API payload definitions](../api-usage-docs/products-api.md). Each dataset name maps to a payload name (see the tables in Step 5), and the payload's `stage_id` is used.

### Full example request (Sponsored Ads)

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 87,
      "name": "My Marketing Stream - Sponsored Ads",
      "status": "active",
      "quantity": 1,
      "price": 0.00,
      "auto_renew": 1,
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": "",
      "remote_identity": 112,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "112",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "profile_id",
          "data_value": "4463883966959342",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "profile_type",
          "data_value": "ads",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "advertiser_id",
          "data_value": "NOT_APPLICABLE",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "aws_iam_role_arn",
          "data_value": "arn:aws:iam::123456789012:role/openbridge-marketing-stream-role",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "queue_urls",
          "data_value": "{\"sp_traffic\":\"https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-sp-traffic-abc123\",\"sp_conversion\":\"https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-sp-conversion-abc123\",\"budget_usage\":\"https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-budget-usage-abc123\"}",
          "data_format": "JSON",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "dataset_params",
          "data_value": "{\"sp-traffic\":{\"stream_id\":\"str_abc123\"},\"sp-conversion\":{\"stream_id\":\"str_def456\"},\"budget-usage\":{\"stream_id\":\"str_ghi789\"}}",
          "data_format": "JSON",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "selected_tables",
          "data_value": "[\"sp-traffic\",\"sp-conversion\",\"budget-usage\"]",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[101,102,103]",
          "data_format": "JSON",
          "product": 87
        }
      ]
    }
  }
}
```

### Full example request (DSP)

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 87,
      "name": "My Marketing Stream - DSP",
      "status": "active",
      "quantity": 1,
      "price": 0.00,
      "auto_renew": 1,
      "date_start": "2024-06-01T00:00:00Z",
      "date_end": "2024-06-01T00:00:00Z",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": "",
      "remote_identity": 112,
      "storage_group": 1,
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "112",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "profile_id",
          "data_value": "4463883966959342",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "profile_type",
          "data_value": "dsp",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "advertiser_id",
          "data_value": "ADV123456",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "aws_iam_role_arn",
          "data_value": "arn:aws:iam::123456789012:role/openbridge-marketing-stream-role",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "queue_urls",
          "data_value": "{\"adsp_traffic\":\"https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-adsp-traffic-abc123\",\"adsp_conversion\":\"https://sqs.us-east-1.amazonaws.com/123456789012/ob-stream2-adsp-conversion-abc123\"}",
          "data_format": "JSON",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "dataset_params",
          "data_value": "{\"adsp-traffic\":{\"stream_id\":\"str_xyz123\"},\"adsp-conversion\":{\"stream_id\":\"str_xyz456\"}}",
          "data_format": "JSON",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "selected_tables",
          "data_value": "[\"adsp-traffic\",\"adsp-conversion\"]",
          "data_format": "STRING",
          "product": 87
        },
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[201,202]",
          "data_format": "JSON",
          "product": 87
        }
      ]
    }
  }
}
```

Replace the placeholder values (`account`, `user`, `remote_identity`, `storage_group`, and all `data_value` entries) with values from your account and the previous steps.

---

## Updating a marketing stream subscription

To update an existing marketing stream subscription (e.g., to add or remove datasets), use two requests:

**1. Update the SQS queues via Service API:**

```
PATCH https://service.api.openbridge.io/service/amzadv/stream-v2/update/{remote_identity_id}/{subscription_id}
```

The request body is the same structure as the create endpoint — include the `role_arn`, updated `datasets`, `profile_type`, and `profile_id` or `advertiser_id`. This is an async operation with the same polling behavior as the create endpoint.

**2. Update the pipeline subscription:**

```
PATCH https://subscriptions.api.openbridge.io/sub/{subscription_id}
```

Update the `queue_urls`, `dataset_params`, `selected_tables`, `stage_ids`, and any other changed meta fields with the new values from the update response.

See the [Subscriptions API](../api-usage-docs/subscriptions-api.md) for full PATCH documentation.

---

## Deleting a marketing stream subscription

To delete a marketing stream pipeline, mark the pipeline subscription as invalid:

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
