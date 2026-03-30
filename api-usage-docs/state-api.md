# State API

The State API creates and manages `ClientState` records — short-lived JSON objects that carry context for browser-based flows such as OAuth authorization. A state record is created before starting a flow, consumed during it, and can be deleted afterward.

---

## Base URL

```
https://state.api.openbridge.io
```

---

## Authentication

`POST /state/oauth` requires a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

`POST /state` and the detail endpoints (`GET`, `PATCH`, `DELETE`) do not require authentication.

---

## Endpoints

### Create State (OAuth flow)

Use this endpoint when creating state for an OAuth authorization flow. Requires a Bearer token. The server automatically injects `account_id` from the JWT and sets `oauth: true` — you do not need to include either field.

```
POST https://state.api.openbridge.io/state/oauth
```

**Request body:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "remote_identity_type_id": 19,
        "user_id": 309,
        "region": "global",
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
        "remote_identity_type_id": 19,
        "user_id": 309,
        "account_id": 342,
        "region": "global",
        "return_url": "https://yourapp.com/oauth/complete",
        "oauth": true
      },
      "created_at": "2024-01-01T00:00:00Z",
      "modified_at": "2024-01-01T00:00:00Z"
    }
  }
}
```

Use the `token` value as the `state` parameter when calling `/oauth/initialize`.

---

### Create State (generic)

Creates a state record without injecting account context. Used for non-OAuth flows.

```
POST https://state.api.openbridge.io/state
```

**Request body:**

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "key": "value"
      }
    }
  }
}
```

---

### Get State

Retrieve a state record by token.

```
GET https://state.api.openbridge.io/state/{token}
```

---

### Update State

Partial update of a state record.

```
PATCH https://state.api.openbridge.io/state/{token}
```

---

### Delete State

```
DELETE https://state.api.openbridge.io/state/{token}
```

Returns `204 No Content` on success.

---

## Field Reference

### ClientState Fields

| Field | Type | Description |
|---|---|---|
| `token` | string | MD5 token that uniquely identifies the state record. Generated server-side. |
| `state` | object | Arbitrary JSON payload carrying flow context |
| `created_at` | datetime | When the record was created |
| `modified_at` | datetime | When the record was last updated |

### State Payload Fields (OAuth flow)

The `state` object must contain the following fields when used with the OAuth authorization flow:

| Field | Required | Description |
|---|---|---|
| `remote_identity_type_id` | Yes | The remote identity type to authorize |
| `user_id` | Yes | The Openbridge user ID |
| `region` | Yes | Region for the identity (typically `global`) |
| `return_url` | Yes | URL to redirect the browser to after the flow completes |
| `account_id` | Auto | Injected from the JWT by `POST /state/oauth`; do not supply manually |
| `remote_identity_id` | No | ID of an existing `RemoteIdentity` to re-authorize |
| `oauth_id` | No | ID of an `OAuth` app record; required for products that use user-supplied credentials (e.g., Snowflake, Shopify) |
| `shop_url` | No | Shopify store URL (e.g., `https://{shop}.myshopify.com`); required for Shopify |
| `query_params` | No | Object of additional key/value pairs to append to `return_url` on completion |
