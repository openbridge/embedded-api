# OAuth API

The OAuth API serves two related purposes:

1. **OAuth app records** — store and manage custom OAuth client credentials (client ID and secret) for products that support user-supplied OAuth applications (e.g., Snowflake, Shopify).
2. **OAuth authorization flow** — browser-redirect endpoints that drive the authorization flow and create or update `RemoteIdentity` records upon completion.

---

## Base URL

```
https://oauth.api.openbridge.io
```

---

## Authentication

All `/oauth/apps` requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

The `/oauth/initialize` and `/oauth/callback` endpoints are browser-redirect flows and are not called with a Bearer token. Access is controlled through the `ClientState` token passed as the `state` query parameter.

---

## Overview: The Authorization Flow

The authorization flow connects a user's third-party account to Openbridge by creating a `RemoteIdentity` record. The sequence is:

```
1. Create a ClientState record  →  POST /state/oauth
2. Direct user's browser to     →  GET /oauth/initialize?state={token}
3. Provider redirects browser   →  GET /oauth/callback?state={token}&code={code}
4. Openbridge redirects to      →  {return_url}?state={token}&ri_id={id}&reauth={true|false}
```

Before starting the flow, create a state record with the required context using the State API. See [State API](./state-api.md) for the full reference, including how to use `POST /state/oauth` and what fields the state payload must contain.

For products that require user-supplied OAuth credentials (Snowflake, Shopify), create an `OAuth` app record first and include its `id` as `oauth_id` in the state payload.

---

## OAuth Authorization Flow

### Initialize

Begins the OAuth flow. Redirects the browser (`303 See Other`) to the provider's authorization page.

```
GET https://oauth.api.openbridge.io/oauth/initialize?state={state_token}
```

**Parameters:**

| Parameter | Description |
|---|---|
| `state` | The `ClientState` token returned by `POST /state/oauth` |

---

### Callback

Receives the authorization response from the provider. This endpoint is called by the provider's redirect — your application does not call it directly.

```
GET https://oauth.api.openbridge.io/oauth/callback?state={state_token}&code={authorization_code}
```

Openbridge exchanges the authorization code for tokens, then creates a new `RemoteIdentity` or updates the existing one. The browser is then redirected (`302 Found`) to the `return_url` from the state record.

**Return URL parameters on success:**

| Parameter | Description |
|---|---|
| `state` | The original state token |
| `reauth` | `true` if an existing identity was re-authorized; `false` if a new identity was created |
| `ri_id` | The ID of the created or updated `RemoteIdentity` |

On error, `status=error`, `status_type`, and `status_message` parameters are appended instead.

---

## OAuth App Records

Some products require you to supply your own OAuth application credentials rather than using Openbridge's built-in credentials. Create an `OAuth` record to store these, then reference its `id` as `oauth_id` in the `ClientState` before starting the flow.

Products that require user-supplied OAuth apps:
- **Snowflake** (`remote_identity_type_id=19`) — requires `extra_params.account_authorization_url`
- **Shopify** (`remote_identity_type_id=16`) — requires `extra_params.shop_url`

---

### List OAuth Apps

Returns all OAuth app records for the authenticated account.

```
GET https://oauth.api.openbridge.io/oauth/apps
```

**Query filters:**

- `remote_identity_type_id={id}` — filter by remote identity type

---

### Get OAuth App

```
GET https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

`client_secret` is never returned in responses.

---

### Create OAuth App

```
POST https://oauth.api.openbridge.io/oauth/apps
```

If a record already exists for the same `account` and `client_id`, the existing record is updated and `200 OK` is returned. Otherwise a new record is created and `201 Created` is returned.

**Request body:**

```json
{
  "data": {
    "type": "OAuth",
    "attributes": {
      "remote_identity_type": 19,
      "account": 342,
      "user": 309,
      "client_id": "{your_client_id}",
      "client_secret": "{your_client_secret}",
      "extra_params": "{\"account_authorization_url\": \"https://{account}.snowflakecomputing.com\"}"
    }
  }
}
```

`client_id` and `client_secret` are encrypted at rest. `client_secret` is write-only and is never returned in responses. If `name` is not provided it is auto-generated as `{remote_identity_type_id}:{client_id}`.

---

### Update OAuth App

Partial update. All fields are optional.

```
PATCH https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

---

### Delete OAuth App

```
DELETE https://oauth.api.openbridge.io/oauth/apps/{oauth_id}
```

Returns `204 No Content` on success.

---

## Field Reference

### OAuth App Fields

| Field | Type | Description |
|---|---|---|
| `remote_identity_type` | integer | The remote identity type this app applies to |
| `account` / `account_id` | integer | The account that owns this record |
| `user` / `user_id` | integer | The user that created this record |
| `name` | string | Label; auto-generated as `{remote_identity_type_id}:{client_id}` if not provided |
| `client_id` | string | OAuth client ID (encrypted at rest) |
| `client_secret` | string | OAuth client secret (write-only; encrypted at rest; never returned) |
| `extra_params` | string | JSON-encoded provider-specific parameters |

### `extra_params` by Provider

| Provider | Key | Description |
|---|---|---|
| Snowflake | `account_authorization_url` | Base URL of the Snowflake account (e.g., `https://{account}.snowflakecomputing.com`) |
| Shopify | `shop_url` | Shopify store URL (e.g., `https://{shop}.myshopify.com`) |
