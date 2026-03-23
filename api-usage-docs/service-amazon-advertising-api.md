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

**Example request**

```http
GET https://service.api.openbridge.io/service/amzadv/profiles-only/112?profile_types=seller,vendor
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
| `id` | Profile ID (numeric) | Use as `profile_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
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
  "access_token": "Atza|...",
  "client_id": "amzn1.application-oa2-client.abc123"
}
```
