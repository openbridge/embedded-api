# Amazon Identity Configuration — Advertising, Selling Partner & Vendor Central

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Amazon Reference](#amazon-reference)
  - [Amazon Advertising regions](#amazon-advertising-regions)
  - [Amazon Selling Partner and Vendor Central country codes](#amazon-selling-partner-and-vendor-central-country-codes)
  - [Country-to-API-region mapping](#country-to-api-region-mapping)
  - [Amazon credential formats](#amazon-credential-formats)
  - [Login with Amazon button](#login-with-amazon-button)
- [Openbridge Identity Type Reference](#openbridge-identity-type-reference)
- [Path 1 — Openbridge OAuth App](#path-1--openbridge-oauth-app)
  - [Step 1: Create a state record](#path-1-step-1-create-a-state-record)
  - [Step 2: Redirect to the authorization flow](#path-1-step-2-redirect-to-the-authorization-flow)
  - [Step 3: Handle the return redirect](#path-1-step-3-handle-the-return-redirect)
- [Path 2 — Bring Your Own OAuth App (BYOA)](#path-2--bring-your-own-oauth-app-byoa)
  - [Step 1: Register your OAuth client credentials](#path-2-step-1-register-your-oauth-client-credentials)
  - [Step 2: Create a state record with oauth_id](#path-2-step-2-create-a-state-record-with-oauth_id)
  - [Step 3: Redirect to the authorization flow](#path-2-step-3-redirect-to-the-authorization-flow)
  - [Step 4: Handle the return redirect](#path-2-step-4-handle-the-return-redirect)
  - [Managing OAuth clients](#managing-oauth-clients)
- [Path 3 — Private App (Direct Credential Registration)](#path-3--private-app-direct-credential-registration)
  - [Step 1: Validate credentials (pre-flight)](#path-3-step-1-validate-credentials-pre-flight)
  - [Step 2: Encrypt sensitive credentials](#path-3-step-2-encrypt-sensitive-credentials)
  - [Step 3: Create the remote identity](#path-3-step-3-create-the-remote-identity)
  - [Seller meta keys](#seller-meta-keys)
  - [Vendor meta keys](#vendor-meta-keys)
  - [Seller vs Vendor differences](#seller-vs-vendor-differences)
- [Updating a Private App Identity](#updating-a-private-app-identity)
- [Reauthorizing an OAuth Identity](#reauthorizing-an-oauth-identity)
- [Querying Identities](#querying-identities)

---

## Overview

Openbridge supports three Amazon identity types. The available creation paths depend on the identity type:

| Identity type | Openbridge type ID | Path 1 (Openbridge OAuth) | Path 2 (BYOA) | Path 3 (Private App) |
|---|---|---|---|---|
| **Amazon Advertising** | `14` | Yes | No | No |
| **Amazon Selling Partner** | `17` | Yes | Yes | Yes |
| **Amazon Vendor Central** | `18` | Yes | Yes | Yes |

| Path | When to use | Browser redirect required? | Credentials managed by |
|---|---|---|---|
| **Path 1 — Openbridge OAuth App** | You want Openbridge to handle the OAuth application. Simplest setup. Works for all three identity types. | Yes | Openbridge |
| **Path 2 — BYOA (Bring Your Own OAuth App)** | You have your own Amazon SP-API application and want to use your own client ID and secret for the OAuth flow. Selling Partner and Vendor Central only. | Yes | You (OAuth app) + Amazon (tokens) |
| **Path 3 — Private App** | You have a private (developer-owned) SP-API application with a client ID, client secret, and refresh token. No browser redirect needed. Selling Partner and Vendor Central only. | No | You (all credentials) |

All paths produce a `RemoteIdentity` record that can be attached to subscriptions.

---

## Prerequisites

- A valid JWT access token. See [Authentication API](../api-usage-docs/authentication-api.md).
- Your `account_id` and `user_id`. See [Account and User API](../api-usage-docs/account-user-api.md).
- For Path 2 and Path 3: your Amazon SP-API application credentials (client ID, client secret, and for Path 3, a refresh token).

---

## Amazon Reference

This section documents Amazon-specific concepts: regions, country codes, credential formats, and UX requirements. These are defined by Amazon, not Openbridge. Openbridge path instructions reference this section where Amazon-specific values are needed.

### Amazon Advertising regions

Amazon Advertising uses API region identifiers to route requests:

| Region identifier | Region name |
|---|---|
| `na` | North America |
| `eu` | Europe |
| `fe` | Far East |

### Amazon Selling Partner and Vendor Central country codes

Amazon Selling Partner and Vendor Central APIs use country codes to identify marketplaces:

| Country code | Country |
|---|---|
| `AU` | Australia |
| `BE` | Belgium |
| `BR` | Brazil |
| `CA` | Canada |
| `EG` | Egypt |
| `FR` | France |
| `DE` | Germany |
| `IN` | India |
| `IE` | Ireland |
| `IT` | Italy |
| `JP` | Japan |
| `MX` | Mexico |
| `NL` | Netherlands |
| `PL` | Poland |
| `SA` | Saudi Arabia |
| `SG` | Singapore |
| `ES` | Spain |
| `SE` | Sweden |
| `TR` | Turkey |
| `UK` | United Kingdom |
| `AE` | United Arab Emirates |
| `US` | United States |

### Country-to-API-region mapping

Amazon groups its marketplaces into three API regions. This mapping is required when calling Openbridge validation endpoints and when building meta attributes for Private App identities:

| API region | Country codes |
|---|---|
| `na` | `US`, `CA`, `MX`, `BR` |
| `eu` | `UK`, `FR`, `DE`, `IT`, `ES`, `NL`, `SE`, `PL`, `BE`, `IE`, `EG`, `TR`, `SA`, `AE`, `IN` |
| `fe` | `JP`, `AU`, `SG` |

### Amazon credential formats

These are Amazon-defined credential formats used across Paths 2 and 3:

| Credential | Description | Validation pattern |
|---|---|---|
| Client ID | Amazon LWA application client ID | `^[A-Za-z0-9.-]+$` |
| Client secret | Amazon LWA application client secret | `^[A-Za-z0-9.-]+$` |
| Refresh token | Amazon LWA refresh token | `^Atzr\|IwEB[A-Za-z0-9_-]+$` |
| Application ID | Amazon SP-API application ID | `^[A-Za-z0-9.-]+$` |
| Selling Partner ID | Amazon merchant identifier | Returned by SP-API |
| Vendor Group ID | Amazon vendor identifier | User-provided or auto-generated 10-digit numeric string |

### Login with Amazon button

Any UI that initiates an Amazon OAuth authorization flow (Path 1 or Path 2) **must** use the official Login with Amazon button. Amazon requires this for branding compliance.

See Amazon's official button guidelines and assets: [Login with Amazon Button](https://developer.amazon.com/docs/login-with-amazon/button.html)

Key requirements from Amazon:

- Use the official Login with Amazon button images or CSS-generated buttons provided by Amazon
- Do not modify the button design, colors, or proportions
- The button must be used wherever a user action initiates the Amazon authorization redirect
- Full-page redirect only — **never** load the authorization URL inside a `<frame>` or `<iframe>`

---

## Openbridge Identity Type Reference

Openbridge maps each Amazon identity type to an internal type ID and auth service. The region format column indicates which Amazon region scheme (see [Amazon Reference](#amazon-reference)) applies to each type:

| Openbridge type ID | Amazon identity type | Openbridge auth service | Amazon region format |
|---|---|---|---|
| `14` | Amazon Advertising | `amazon-advertising-oauth2` | API region (`na`, `eu`, `fe`) — see [Advertising regions](#amazon-advertising-regions) |
| `17` | Amazon Selling Partner | `sp-api-oauth` | Country code (`US`, `UK`, `DE`, etc.) — see [country codes](#amazon-selling-partner-and-vendor-central-country-codes) |
| `18` | Amazon Vendor Central | `sp-api-oauth` | Country code (`US`, `UK`, `DE`, etc.) — see [country codes](#amazon-selling-partner-and-vendor-central-country-codes) |

Look up the required identity type from the product's `remote_identity_type` relationship. See [Identity Configuration — Step 2](./identity-configuration.md#step-2--find-the-required-identity-type-for-your-product).

---

## Path 1 — Openbridge OAuth App

This is the standard OAuth redirect flow using Openbridge's built-in OAuth application. Works for all three Amazon identity types (Advertising, Selling Partner, Vendor Central). For complete details on the general OAuth flow, see [Identity Configuration](./identity-configuration.md).

### Path 1, Step 1: Create a state record

See [State API](../api-usage-docs/state-api.md) for the full endpoint reference.

```
POST https://state.api.openbridge.io/state/oauth
```

**Amazon Advertising example:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 14,
        "user_id": "{user_id}",
        "region": "na",
        "return_url": "https://yourapp.com/oauth/complete"
      }
    }
  }
}
```

**Amazon Selling Partner example:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 17,
        "user_id": "{user_id}",
        "region": "US",
        "return_url": "https://yourapp.com/oauth/complete"
      }
    }
  }
}
```

**Amazon Vendor Central example:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 18,
        "user_id": "{user_id}",
        "region": "US",
        "return_url": "https://yourapp.com/oauth/complete"
      }
    }
  }
}
```

| Field | Source | Required | Description |
|---|---|---|---|
| `remote_identity_type_id` | Openbridge | Yes | `14` for Advertising, `17` for Selling Partner, `18` for Vendor Central |
| `user_id` | Openbridge | Yes | Your Openbridge user ID |
| `region` | Amazon | Yes | For Advertising: API region (`na`, `eu`, `fe`). For Selling Partner / Vendor Central: country code — see [Amazon Reference](#amazon-reference) |
| `return_url` | Openbridge | Yes | URL to redirect the browser to after the flow completes |
| `account_id` | Openbridge | Auto | Injected from your JWT by the server — do not supply |

**Example response:**

```json
{
  "data": {
    "type": "ClientState",
    "id": "a3f1c9e2b74d8051fd62a9e0bc3d7f14",
    "attributes": {
      "token": "a3f1c9e2b74d8051fd62a9e0bc3d7f14",
      "state": {
        "remote_identity_type_id": 17,
        "user_id": 309,
        "account_id": 342,
        "region": "US",
        "return_url": "https://yourapp.com/oauth/complete",
        "oauth": true
      },
      "created_at": "2024-01-01T00:00:00Z",
      "modified_at": "2024-01-01T00:00:00Z"
    }
  }
}
```

### Path 1, Step 2: Redirect to the authorization flow

Use the official [Login with Amazon button](#login-with-amazon-button) to trigger this redirect. When the user clicks the button, redirect their browser to:

```
https://oauth.api.openbridge.io/oauth/initialize?state={token}
```

Replace `{token}` with the `token` value from the state response. This triggers a `303` redirect to Amazon's authorization page.

**Never call this URL inside a `<frame>` or `<iframe>` element.** Use a full-page redirect. See [Identity Configuration — Security note](./identity-configuration.md#security-note-must-read).

### Path 1, Step 3: Handle the return redirect

After the user authorizes (or declines), Openbridge redirects the browser to your `return_url` with query parameters:

| Parameter | Type | Description |
|---|---|---|
| `state` | string | The original state token (Openbridge) |
| `ri_id` | integer | ID of the created `RemoteIdentity` (Openbridge) |
| `reauth` | boolean | `true` if re-authorized; `false` if new (Openbridge) |
| `status` | string | Present on error; value is `error` |
| `status_type` | string | Error category, when `status=error` |
| `status_message` | string | Human-readable error description, when `status=error` |

**Success:**

```
https://yourapp.com/oauth/complete?state=a3f1c9e2b74d8051fd62a9e0bc3d7f14&ri_id=362&reauth=false
```

**Error:**

```
https://yourapp.com/oauth/complete?state=a3f1c9e2b74d8051fd62a9e0bc3d7f14&status=error&status_type=access_denied&status_message=The+user+denied+access
```

---

## Path 2 — Bring Your Own OAuth App (BYOA)

Use this path when you have your own Amazon SP-API application and want the OAuth redirect flow to use your credentials instead of Openbridge's built-in application. **Available for Selling Partner (type `17`) and Vendor Central (type `18`) only.** Amazon Advertising (type `14`) does not support BYOA.

### Path 2, Step 1: Register your OAuth client credentials

Create an `OAuth` app record with your Amazon SP-API client credentials (see [Amazon credential formats](#amazon-credential-formats)):

```
POST https://oauth.api.openbridge.io/oauth/apps
```

**Selling Partner example (type `17`):**

```json
{
  "data": {
    "type": "OAuth",
    "attributes": {
      "remote_identity_type": 17,
      "account": "{account_id}",
      "user": "{user_id}",
      "client_id": "amzn1.application-oa2-client.abc123def456",
      "client_secret": "{your_client_secret}",
      "extra_params": "{\"app_id\": \"amzn1.sp.solution.abc123def456\"}"
    }
  }
}
```

**Vendor Central example (type `18`):**

```json
{
  "data": {
    "type": "OAuth",
    "attributes": {
      "remote_identity_type": 18,
      "account": "{account_id}",
      "user": "{user_id}",
      "client_id": "amzn1.application-oa2-client.abc123def456",
      "client_secret": "{your_client_secret}",
      "extra_params": "{\"app_id\": \"amzn1.sp.solution.abc123def456\"}"
    }
  }
}
```

| Field | Source | Required | Description |
|---|---|---|---|
| `remote_identity_type` | Openbridge | Yes | `17` for Selling Partner, `18` for Vendor Central |
| `account` | Openbridge | Yes | Your Openbridge account ID |
| `user` | Openbridge | Yes | Your Openbridge user ID |
| `client_id` | Amazon | Yes | Your Amazon LWA application client ID |
| `client_secret` | Amazon | Yes | Your Amazon LWA application client secret (encrypted at rest; never returned in responses) |
| `extra_params` | Amazon | Yes | JSON-encoded string containing `app_id` — your Amazon SP-API application ID |

`extra_params.app_id` validation pattern: `^[A-Za-z0-9.-]+$`

If a record already exists for the same `account` and `client_id`, the existing record is updated and `200 OK` is returned. Otherwise a new record is created and `201 Created` is returned.

**Example response:**

```json
{
  "data": {
    "type": "OAuth",
    "id": "45",
    "attributes": {
      "name": "17:amzn1.application-oa2-client.abc123def456",
      "remote_identity_type_id": 17,
      "account_id": 342,
      "user_id": 309,
      "client_id": "amzn1.application-oa2-client.abc123def456",
      "extra_params": "{\"app_id\": \"amzn1.sp.solution.abc123def456\"}",
      "created_at": "2024-01-01T00:00:00Z",
      "modified_at": "2024-01-01T00:00:00Z"
    }
  }
}
```

Store the returned `id` (`45` in the example above) — you will use it as `oauth_id` in the next step.

### Path 2, Step 2: Create a state record with oauth_id

Create a state record that includes the `oauth_id` from the previous step:

```
POST https://state.api.openbridge.io/state/oauth
```

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 17,
        "user_id": "{user_id}",
        "region": "US",
        "return_url": "https://yourapp.com/oauth/complete",
        "oauth_id": 45
      }
    }
  }
}
```

The `oauth_id` tells Openbridge to use your registered OAuth application credentials for the authorization flow instead of the built-in application.

All other fields are the same as [Path 1, Step 1](#path-1-step-1-create-a-state-record).

### Path 2, Step 3: Redirect to the authorization flow

Use the official [Login with Amazon button](#login-with-amazon-button) to trigger this redirect. Same mechanism as [Path 1, Step 2](#path-1-step-2-redirect-to-the-authorization-flow):

```
https://oauth.api.openbridge.io/oauth/initialize?state={token}
```

### Path 2, Step 4: Handle the return redirect

Same as [Path 1, Step 3](#path-1-step-3-handle-the-return-redirect). The return URL parameters are identical.

### Managing OAuth clients

**List your OAuth clients filtered by identity type:**

```
GET https://oauth.api.openbridge.io/oauth/apps?remote_identity_type_id=17
```

**Get a specific OAuth client:**

```
GET https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

**Update an OAuth client:**

```
PATCH https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

**Delete an OAuth client:**

```
DELETE https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

Returns `204 No Content` on success.

See [OAuth API](../api-usage-docs/oauth-api.md) for the full reference.

---

## Path 3 — Private App (Direct Credential Registration)

Use this path when you have a private (developer-owned) SP-API application and already possess a client ID, client secret, and refresh token (see [Amazon credential formats](#amazon-credential-formats)). No browser redirect is needed — credentials are registered directly via API. **Available for Selling Partner (type `17`) and Vendor Central (type `18`) only.** Amazon Advertising (type `14`) does not support Private App registration.

### Path 3, Step 1: Validate credentials (pre-flight)

Before creating the identity, validate that the Amazon credentials are correct. The Openbridge validation endpoint differs between Seller and Vendor:

**For Selling Partner (type `17`)** — resolves the Amazon selling partner ID:

```
POST https://service.api.openbridge.io/service/sp/sp-id
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "client_id": "amzn1.application-oa2-client.abc123def456",
      "client_secret": "abc123secret",
      "region": "na",
      "refresh_token": "Atzr|IwEBxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Response:**

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

Store the `selling_partner_id` (Amazon's merchant identifier) — you will use it in Step 3 as Openbridge meta key `32`.

**For Vendor Central (type `18`)** — validates Amazon credentials only:

```
POST https://service.api.openbridge.io/service/sp/validate-creds
```

```json
{
  "data": {
    "type": "Service",
    "attributes": {
      "client_id": "amzn1.application-oa2-client.abc123def456",
      "client_secret": "abc123secret",
      "region": "na",
      "refresh_token": "Atzr|IwEBxxxxxxxxxxxxxxxx"
    }
  }
}
```

Returns `204 No Content` on success. Returns `400 Bad Request` if credentials are invalid.

**Required fields for both endpoints:**

| Field | Source | Description |
|---|---|---|
| `client_id` | Amazon | Amazon LWA application client ID |
| `client_secret` | Amazon | Amazon LWA application client secret |
| `region` | Amazon | SP-API region: `na`, `eu`, or `fe` — map the country code using the [country-to-API-region mapping](#country-to-api-region-mapping) |
| `refresh_token` | Amazon | Amazon LWA refresh token |

See [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md) for the full reference.

### Path 3, Step 2: Encrypt sensitive credentials

Before creating the Openbridge identity, encrypt the Amazon `client_secret` and `refresh_token` using the Openbridge encryption endpoint. This endpoint is part of the [Service API](../api-usage-docs/service-api.md).

```
POST https://service.api.openbridge.io/service/encrypt/encrypt
```

```json
{
  "data": {
    "attributes": {
      "clientSecret": "abc123secret",
      "refreshToken": "Atzr|IwEBxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Response:**

```json
{
  "data": {
    "attributes": {
      "clientSecret": "ENCRYPTED:xxxxxxxxxxxxxxxxxxxx",
      "refreshToken": "ENCRYPTED:yyyyyyyyyyyyyyyyyyyy"
    }
  }
}
```

The response contains the encrypted values for each key you submitted. Use these encrypted values as the `meta_value` for Openbridge meta keys `27` (client_secret) and `7` (refresh_token) in the next step.

### Path 3, Step 3: Create the remote identity

```
POST https://remote-identity.api.openbridge.io/ri
```

**Selling Partner (type `17`) example:**

```json
{
  "data": {
    "type": "RemoteIdentity",
    "attributes": {
      "remote_identity_type": 17,
      "name": "My US Seller Account",
      "account": 342,
      "user": 309,
      "identity_hash": "550e8400-e29b-41d4-a716-446655440000",
      "remote_unique_id": "amzn1.application-oa2-client.abc123def456",
      "region": "US",
      "is_private_app": true,
      "remote_identity_meta_attributes": [
        {
          "remote_identity_type_meta_key": 26,
          "meta_value": "amzn1.application-oa2-client.abc123def456",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 27,
          "meta_value": "ENCRYPTED:xxxxxxxxxxxxxxxxxxxx",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 7,
          "meta_value": "ENCRYPTED:yyyyyyyyyyyyyyyyyyyy",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 31,
          "meta_value": "na",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 32,
          "meta_value": "A3EXAMPLE123456",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 67,
          "meta_value": "true",
          "meta_format": "STRING"
        }
      ]
    }
  }
}
```

**Vendor Central (type `18`) example:**

```json
{
  "data": {
    "type": "RemoteIdentity",
    "attributes": {
      "remote_identity_type": 18,
      "name": "My US Vendor Account",
      "account": 342,
      "user": 309,
      "identity_hash": "550e8400-e29b-41d4-a716-446655440001",
      "remote_unique_id": "amzn1.application-oa2-client.abc123def456",
      "region": "US",
      "is_private_app": true,
      "remote_identity_meta_attributes": [
        {
          "remote_identity_type_meta_key": 26,
          "meta_value": "amzn1.application-oa2-client.abc123def456",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 27,
          "meta_value": "ENCRYPTED:xxxxxxxxxxxxxxxxxxxx",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 7,
          "meta_value": "ENCRYPTED:yyyyyyyyyyyyyyyyyyyy",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 31,
          "meta_value": "na",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 30,
          "meta_value": "US",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 32,
          "meta_value": "1234567890",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 67,
          "meta_value": "true",
          "meta_format": "STRING"
        }
      ]
    }
  }
}
```

**Top-level identity fields:**

| Field | Source | Required | Description |
|---|---|---|---|
| `remote_identity_type` | Openbridge | Yes | `17` for Selling Partner, `18` for Vendor Central |
| `name` | Openbridge | Yes | Display name for the identity |
| `account` | Openbridge | Yes | Your Openbridge account ID |
| `user` | Openbridge | Yes | Your Openbridge user ID |
| `identity_hash` | Openbridge | Yes | A UUID v4 string — generate a unique one for each identity |
| `remote_unique_id` | Amazon | Yes | Set to the Amazon `client_id` value |
| `region` | Amazon | Yes | Country code — see [country codes](#amazon-selling-partner-and-vendor-central-country-codes) |
| `is_private_app` | Openbridge | Yes | Must be `true` for Private App identities |
| `remote_identity_meta_attributes` | Mixed | Yes | Array of meta key/value objects (see tables below) |

### Seller meta keys

Meta attributes required for Selling Partner (type `17`) Private App identities. Each row shows the Openbridge meta key number and the Amazon value it stores:

| Openbridge meta key | Amazon field | Format | Description |
|---|---|---|---|
| `26` | client_id | `STRING` | Amazon LWA application client ID (plaintext) |
| `27` | client_secret | `ENCRYPTED_STRING` | Amazon LWA application client secret (encrypted via Step 2) |
| `7` | refresh_token | `ENCRYPTED_STRING` | Amazon LWA refresh token (encrypted via Step 2) |
| `31` | region | `STRING` | Amazon API region (`na`, `eu`, or `fe`) — mapped from country code via [country-to-API-region mapping](#country-to-api-region-mapping) |
| `32` | selling_partner_id | `STRING` | Amazon selling partner ID returned by the `/sp/sp-id` validation endpoint |
| `67` | is_private_app | `STRING` | Always `"true"` (Openbridge flag) |

### Vendor meta keys

Meta attributes required for Vendor Central (type `18`) Private App identities:

| Openbridge meta key | Amazon field | Format | Description |
|---|---|---|---|
| `26` | client_id | `STRING` | Amazon LWA application client ID (plaintext) |
| `27` | client_secret | `ENCRYPTED_STRING` | Amazon LWA application client secret (encrypted via Step 2) |
| `7` | refresh_token | `ENCRYPTED_STRING` | Amazon LWA refresh token (encrypted via Step 2) |
| `31` | region | `STRING` | Amazon API region (`na`, `eu`, or `fe`) — mapped from country code via [country-to-API-region mapping](#country-to-api-region-mapping) |
| `30` | country_code | `STRING` | Amazon country code as provided (e.g., `US`, `UK`, `DE`) |
| `32` | vendor_group_id | `STRING` | Amazon vendor group ID — user-provided, or generate a random 10-digit numeric string if not known |
| `67` | is_private_app | `STRING` | Always `"true"` (Openbridge flag) |

### Seller vs Vendor differences

| Aspect | Selling Partner (17) | Vendor Central (18) |
|---|---|---|
| Openbridge validation endpoint | `POST /service/sp/sp-id` | `POST /service/sp/validate-creds` |
| Validation returns | Amazon `selling_partner_id` | `204 No Content` (success only) |
| Meta key `30` (country_code) | Not used | Required — Amazon country code |
| Meta key `32` | Amazon `selling_partner_id` from validation | Amazon `vendor_group_id` — user-provided or auto-generated |

**Example response (successful creation):**

```json
{
  "data": {
    "type": "RemoteIdentity",
    "id": "405",
    "attributes": {
      "name": "My US Seller Account",
      "created_at": "2024-06-15T10:30:00",
      "modified_at": "2024-06-15T10:30:00",
      "remote_unique_id": "amzn1.application-oa2-client.abc123def456",
      "account_id": 342,
      "user_id": 309,
      "invalid_identity": 0,
      "region": "US",
      "identity_hash": "550e8400-e29b-41d4-a716-446655440000",
      "is_private_app": true
    },
    "relationships": {
      "remote_identity_type": {
        "data": { "type": "RemoteIdentityType", "id": "17" }
      },
      "account": {
        "data": { "type": "Account", "id": "342" }
      },
      "user": {
        "data": { "type": "User", "id": "309" }
      },
      "oauth": { "data": null }
    }
  }
}
```

---

## Updating a Private App Identity

To update a Private App identity (e.g., rotating Amazon credentials), follow a similar process to creation:

**Step 1 — Get the current meta data:**

```
GET https://remote-identity.api.openbridge.io/rim?remote_identity={remote_identity_id}
```

This returns the existing Openbridge meta records. Non-encrypted fields (like `client_id`, `region`) will have their values visible. Encrypted fields will have format `ENCRYPTED_STRING`.

**Step 2 — Encrypt updated Amazon credentials:**

If you are updating `client_secret` or `refresh_token`, encrypt the new Amazon values using the Openbridge encryption endpoint:

```
POST https://service.api.openbridge.io/service/encrypt/encrypt
```

```json
{
  "data": {
    "attributes": {
      "clientSecret": "new_secret_value",
      "refreshToken": "Atzr|IwEBnewtoken"
    }
  }
}
```

Only include the fields you are updating.

**Step 3 — Update the identity:**

```
PATCH https://remote-identity.api.openbridge.io/ri/{remote_identity_id}
```

```json
{
  "data": {
    "type": "RemoteIdentity",
    "id": 405,
    "attributes": {
      "remote_identity_type": 17,
      "name": "My US Seller Account (Updated)",
      "account": 342,
      "user": 309,
      "identity_hash": "550e8400-e29b-41d4-a716-446655440000",
      "remote_unique_id": "amzn1.application-oa2-client.abc123def456",
      "region": "US",
      "remote_identity_meta_attributes": [
        {
          "remote_identity_type_meta_key": 26,
          "meta_value": "amzn1.application-oa2-client.abc123def456",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 27,
          "meta_value": "ENCRYPTED:newencryptedvalue",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 7,
          "meta_value": "ENCRYPTED:newencryptedtoken",
          "meta_format": "ENCRYPTED_STRING"
        },
        {
          "remote_identity_type_meta_key": 31,
          "meta_value": "na",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 32,
          "meta_value": "A3EXAMPLE123456",
          "meta_format": "STRING"
        },
        {
          "remote_identity_type_meta_key": 67,
          "meta_value": "true",
          "meta_format": "STRING"
        }
      ]
    }
  }
}
```

The `identity_hash` must match the existing identity's `identity_hash`. The full `remote_identity_meta_attributes` array must be provided — it replaces the existing meta data entirely.

---

## Reauthorizing an OAuth Identity

For identities created via Path 1 or Path 2 (OAuth flow), re-authorization uses the same OAuth redirect flow with the `remote_identity_id` included in the state payload. This applies to all three identity types (Advertising, Selling Partner, Vendor Central). Use the official [Login with Amazon button](#login-with-amazon-button) to initiate the re-authorization redirect.

```
POST https://state.api.openbridge.io/state/oauth
```

**Amazon Advertising reauth example:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 14,
        "user_id": "{user_id}",
        "region": "na",
        "return_url": "https://yourapp.com/oauth/complete",
        "remote_identity_id": "{existing_remote_identity_id}"
      }
    }
  }
}
```

**Selling Partner / Vendor Central reauth example:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 17,
        "user_id": "{user_id}",
        "region": "US",
        "return_url": "https://yourapp.com/oauth/complete",
        "remote_identity_id": "{existing_remote_identity_id}"
      }
    }
  }
}
```

If the identity was created via Path 2 (BYOA), also include the `oauth_id` in the state payload to use your registered OAuth credentials for the re-authorization flow.

Then redirect to `https://oauth.api.openbridge.io/oauth/initialize?state={token}` as before. On completion, Openbridge updates the existing identity record and returns `reauth=true` in the redirect.

See [Identity Configuration — Reauthorizing an existing identity](./identity-configuration.md#reauthorizing-an-existing-identity) for the full flow.

---

## Querying Identities

After creating an identity via any path, use the [Remote Identity API](../api-usage-docs/remote-identity-api.md) to retrieve and inspect it.

**List all identities accessible to your account:**

```
GET https://remote-identity.api.openbridge.io/sri
```

**Get a specific identity:**

```
GET https://remote-identity.api.openbridge.io/ri/{remote_identity_id}
```

**Filter by identity type:**

```
GET https://remote-identity.api.openbridge.io/sri?remote_identity_type=14
GET https://remote-identity.api.openbridge.io/sri?remote_identity_type=17
GET https://remote-identity.api.openbridge.io/sri?remote_identity_type=18
```

**Check for invalid identities:**

```
GET https://remote-identity.api.openbridge.io/sri?invalid_identity=1
```

**Get identity meta data (for Private App identities):**

```
GET https://remote-identity.api.openbridge.io/rim?remote_identity={remote_identity_id}
```

If an identity becomes invalid, all subscriptions attached to it will fail to process data. For OAuth identities (all three types), re-authorize through the flow described in [Reauthorizing an OAuth Identity](#reauthorizing-an-oauth-identity). For Private App identities (Selling Partner and Vendor Central only), update the credentials using the flow described in [Updating a Private App Identity](#updating-a-private-app-identity).

**Next steps by identity type:**

- **Amazon Advertising (type `14`)**: Use the identity to look up advertising profiles and brands. See [Service API: Amazon Advertising](../api-usage-docs/service-amazon-advertising-api.md).
- **Amazon Selling Partner (type `17`) / Vendor Central (type `18`)**: Use the identity to look up marketplaces. See [Service API: Amazon SP-API](../api-usage-docs/service-amazon-sp-api.md).
- **All types**: Create a subscription using the identity. See [Subscription Configuration](./subscription-configuration.md).
