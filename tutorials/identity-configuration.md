# Identity Configuration

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Look up your account and user IDs](#step-1--look-up-your-account-and-user-ids)
- [Step 2 — Find the required identity type for your product](#step-2--find-the-required-identity-type-for-your-product)
  - [Look up the product](#look-up-the-product)
  - [Get identity type details](#get-identity-type-details)
  - [Regions](#regions)
  - [Amazon Advertising regions](#amazon-advertising-regions)
  - [Amazon Selling Partner and Vendor Central regions](#amazon-selling-partner-and-vendor-central-regions)
- [Step 3 — (Shopify / Snowflake only) Create an OAuth App record](#step-3--shopify--snowflake-only-create-an-oauth-app-record)
- [Step 4 — Create a state record](#step-4--create-a-state-record)
  - [State payload fields](#state-payload-fields)
  - [Return URL](#return-url)
- [Step 5 — Initialize the authorization flow](#step-5--initialize-the-authorization-flow)
  - [Security note (must read)](#security-note-must-read)
- [Step 6 — Handle the return redirect](#step-6--handle-the-return-redirect)
  - [Return URL parameters](#return-url-parameters)
- [Reauthorizing an existing identity](#reauthorizing-an-existing-identity)
- [Querying identities after creation](#querying-identities-after-creation)

---

## Overview

Creating an identity authorizes Openbridge to pull data from a third-party source on your behalf. The process is an OAuth browser redirect flow:

```
1. Create a ClientState record  →  POST /state/oauth
2. Direct user's browser to     →  GET /oauth/initialize?state={token}
3. Provider redirects browser   →  GET /oauth/callback (handled by Openbridge)
4. Openbridge redirects to      →  {return_url}?state={token}&ri_id={id}&reauth={true|false}
```

The state record carries all context for the flow. The browser redirect to `/oauth/initialize` starts it. After the user authorizes with the third party, Openbridge creates a `RemoteIdentity` record and sends the browser back to your `return_url`.

---

## Prerequisites

All API calls require a JWT access token. Obtain one by exchanging your refresh token with the [Authentication API](../api-usage-docs/authentication-api.md).

---

## Step 1 — Look up your account and user IDs

You will need both IDs when creating the state record.

**Account ID:**

```
GET https://account.api.openbridge.io/account
```

Use the `id` field from the response.

**User ID:**

```
GET https://user.api.openbridge.io/user
```

Use the `id` field from the response.

See the [Account and User API](../api-usage-docs/account-user-api.md) for details.

---

## Step 2 — Find the required identity type for your product

Each Openbridge product that connects to a third-party data source requires a specific identity type. The `remote_identity_type_id` you need is determined by the product you intend to subscribe to — do not guess or hardcode it. Look it up from the product record.

### Look up the product

Fetch the product you want to use from the Subscriptions API:

```
GET https://subscriptions.api.openbridge.io/product/{product_id}
```

The response includes a `remote_identity_type` relationship:

```json
{
  "type": "Product",
  "id": "53",
  "attributes": {
    "active": 1,
    "name": "Orders",
    "is_storage_product": 0,
    "required_meta_fields": ["remote_identity_id"]
  },
  "relationships": {
    "remote_identity_type": {
      "data": {
        "type": "RemoteIdentityType",
        "id": "17"
      }
    }
  }
}
```

The `id` in `relationships.remote_identity_type.data` is your `remote_identity_type_id`. If `remote_identity_type.data` is `null`, the product does not require an identity.

Use `GET https://subscriptions.api.openbridge.io/product` to list all products if you need to find a product ID first. See the [Products API](../api-usage-docs/products-api.md) for query filters.

### Get identity type details

To look up additional details about an identity type (such as its name and `auth_service` identifier), use the Remote Identity API:

```
GET https://remote-identity.api.openbridge.io/rit/{remote_identity_type_id}
```

You can also list all identity types to browse what is available:

```
GET https://remote-identity.api.openbridge.io/rit
```

See the [Remote Identity API](../api-usage-docs/remote-identity-api.md) for query filters and field reference.

### Regions

Most identity types use the region value `global`. Amazon Advertising, Amazon Selling Partner, and Amazon Vendor Central are region-specific — use the tables below to find the correct region identifier for your target marketplace.

### Amazon Advertising regions

| Region identifier | Region name |
|---|---|
| `na` | North America |
| `eu` | Europe |
| `fe` | Far East |

### Amazon Selling Partner and Vendor Central regions

| Region identifier | Region name |
|---|---|
| `AU` | Australia |
| `BR` | Brazil |
| `CA` | Canada |
| `EG` | Egypt |
| `FR` | France |
| `DE` | Germany |
| `IN` | India |
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

---

## Step 3 — Create an OAuth App record if needed

Some products may require you to supply your own OAuth application credentials rather than using Openbridge's built-in credentials. Shopify (`remote_identity_type_id=16`) and Snowflake (`remote_identity_type_id=19`) are two examples of this. If you will not be authenticating with your own OAuth app credentials, you can skip this step.

Create an `OAuth` app record and store the returned `id` — you will pass it as `oauth_id` in the state payload.

```
POST https://oauth.api.openbridge.io/oauth/apps
```

**Snowflake example:**

```json
{
  "data": {
    "type": "OAuth",
    "attributes": {
      "remote_identity_type": 19,
      "account": "{account_id}",
      "user": "{user_id}",
      "client_id": "{your_client_id}",
      "client_secret": "{your_client_secret}",
      "extra_params": "{\"account_authorization_url\": \"https://{account}.snowflakecomputing.com\"}"
    }
  }
}
```

**Shopify example:**

```json
{
  "data": {
    "type": "OAuth",
    "attributes": {
      "remote_identity_type": 16,
      "account": "{account_id}",
      "user": "{user_id}",
      "client_id": "{your_client_id}",
      "client_secret": "{your_client_secret}",
      "extra_params": "{\"shop_url\": \"https://{shop}.myshopify.com\"}"
    }
  }
}
```

`client_secret` is encrypted at rest and never returned in responses. See the [OAuth API](../api-usage-docs/oauth-api.md) for the full reference.

---

## Step 4 — Create a state record

Use `POST /state/oauth` to create a `ClientState` record. This endpoint requires a Bearer token. The server automatically injects `account_id` from your JWT — do not include it in the payload.

```
POST https://state.api.openbridge.io/state/oauth
```

**Example — Amazon Selling Partner (US region):**

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

The `id` and `token` values are always identical. Use the `token` value as the `state` parameter in Step 5.

### State payload fields

| Field | Required | Description |
|---|---|---|
| `remote_identity_type_id` | Yes | The identity type to authorize — look this up from the product's `remote_identity_type` relationship (see [Step 2](#step-2--find-the-required-identity-type-for-your-product)) |
| `user_id` | Yes | Your Openbridge user ID |
| `region` | Yes | Region for the identity; use `global` for non-regional providers |
| `return_url` | Yes | URL to redirect the browser to after the flow completes |
| `account_id` | Auto | Injected from your JWT by the server — do not supply |
| `oauth_id` | Conditional | ID of the OAuth App record; required for Shopify and Snowflake |
| `remote_identity_id` | No | ID of an existing identity to re-authorize (see [Reauthorizing](#reauthorizing-an-existing-identity)) |
| `query_params` | No | Additional key/value pairs to append to `return_url` on completion |

See the [State API](../api-usage-docs/state-api.md) for the full reference.

### Return URL

The `return_url` tells Openbridge where to send the user after the OAuth flow completes (success or error). Openbridge appends result parameters to this URL — see [Step 6](#step-6--handle-the-return-redirect) for the full list.

---

## Step 5 — Initialize the authorization flow

Redirect the user's browser to the OAuth initialize endpoint with the state token:

```
https://oauth.api.openbridge.io/oauth/initialize?state={token}
```

This triggers a `303` redirect to the provider's authorization page.

### Security note (must read)

**Never call this URL inside a `<frame>` or `<iframe>` element.** OAuth providers disable authorization in frames as a [clickjacking protection](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-23#section-10.13). All providers Openbridge integrates with enforce this restriction. Popups may work with some providers but are not officially supported by Openbridge. Use a full-page redirect.

See the [OAuth API](../api-usage-docs/oauth-api.md) for details on the callback flow.

---

## Step 6 — Handle the return redirect

After the user authorizes (or declines), Openbridge redirects the browser to your `return_url` with query parameters appended.

### Return URL parameters

| Parameter | Type | Description |
|---|---|---|
| `state` | string | The original state token |
| `ri_id` | integer | ID of the created or re-authorized `RemoteIdentity` |
| `reauth` | boolean | `true` if an existing identity was re-authorized; `false` if a new identity was created |
| `status` | string | Present on error; value is always `error` — check for this value rather than presence alone, as the field may be expanded in the future |
| `status_type` | string | Error category, when `status=error` |
| `status_message` | string | Human-readable error description, when `status=error` |

**Success example:**

```
https://yourapp.com/oauth/complete?state=a3f1c9e2b74d8051fd62a9e0bc3d7f14&ri_id=362&reauth=false
```

**Error example:**

```
https://yourapp.com/oauth/complete?state=a3f1c9e2b74d8051fd62a9e0bc3d7f14&status=error&status_type=access_denied&status_message=The+user+denied+access
```

---

## Reauthorizing an existing identity

The process is identical to creating a new identity, except you include `remote_identity_id` in the state payload pointing to the existing `RemoteIdentity`. On completion, Openbridge updates the existing record rather than creating a new one, and `reauth=true` is returned in the redirect.

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

---

## Querying identities after creation

Once an identity is created, use the [Remote Identity API](../api-usage-docs/remote-identity-api.md) to retrieve and inspect it.

**List all identities accessible to your account** (use this when looking up an identity to attach to a subscription):

```
GET https://remote-identity.api.openbridge.io/sri
```

**Get a specific identity:**

```
GET https://remote-identity.api.openbridge.io/ri/{remote_identity_id}
```

**Check for invalid identities** (credentials revoked or expired):

```
GET https://remote-identity.api.openbridge.io/sri?invalid_identity=1
```

Identities are checked every 24 hours. If an identity becomes invalid, all subscriptions attached to it will stop processing data. The affected user must re-authorize using the flow described in [Reauthorizing an existing identity](#reauthorizing-an-existing-identity). If you are reselling Openbridge to end customers, detection and re-authorization notification is your responsibility — Openbridge has no direct channel to your customers.
