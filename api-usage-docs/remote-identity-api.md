# Remote Identity API

Remote identities represent the third-party authorization credentials (OAuth tokens, service account keys, etc.) that allow Openbridge to pull data on your behalf. The Remote Identity API lets you list, retrieve, and inspect identities and their associated metadata. Identity creation is handled through the Openbridge UI and OAuth flow — it is not available via this API.

---

## Base URL

```
https://remote-identity.api.openbridge.io
```

---

## Authentication

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

---

## Endpoints

### List Remote Identity Types

Returns all remote identity types — the catalog of third-party providers Openbridge supports. Use this endpoint to look up the `remote_identity_type_id` values required when creating state records for the OAuth flow.

```
GET https://remote-identity.api.openbridge.io/rit
```

**Query filters:**

- `name={value}` — filter by exact name
- `name__icontains={value}` — filter by name (case-insensitive substring)
- `auth_service={value}` — filter by exact auth service identifier
- `auth_service__icontains={value}` — filter by auth service (case-insensitive substring)

**Example response:**

```json
{
  "links": {
    "first": "https://remote-identity.api.openbridge.io/rit?page=1",
    "last": "https://remote-identity.api.openbridge.io/rit?page=1",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "RemoteIdentityType",
      "id": "1",
      "attributes": {
        "name": "Google",
        "auth_service": "google-api-oauth2",
        "created_at": "2014-05-01T00:00:00",
        "modified_at": "2014-05-01T00:00:00"
      }
    },
    {
      "type": "RemoteIdentityType",
      "id": "2",
      "attributes": {
        "name": "Facebook",
        "auth_service": "facebook-api-oauth2",
        "created_at": "2014-05-01T00:00:00",
        "modified_at": "2014-05-01T00:00:00"
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 1,
      "count": 19
    }
  }
}
```

---

### Get Remote Identity Type

Returns a single remote identity type by ID.

```
GET https://remote-identity.api.openbridge.io/rit/{rit_id}
```

**Example response:**

```json
{
  "type": "RemoteIdentityType",
  "id": "17",
  "attributes": {
    "name": "Amazon Seller Central",
    "auth_service": "sp-api-oauth",
    "created_at": "2021-06-21T00:00:00",
    "modified_at": "2021-06-21T00:00:00"
  }
}
```

---

### List Remote Identities

Returns remote identities created by your account.

```
GET https://remote-identity.api.openbridge.io/ri
```

Common query filters:

- `remote_identity_type={id}` — filter by identity type

---

### Get Remote Identity

Returns a single remote identity record by ID.

```
GET https://remote-identity.api.openbridge.io/ri/{remote_identity_id}
```

**Note:** Identity credentials (OAuth tokens, keys) are not returned by this API.

**Example response:**

```json
{
  "data": {
    "type": "RemoteIdentity",
    "id": "362",
    "attributes": {
      "name": "James Andrews",
      "created_at": "2018-02-13T18:49:51",
      "modified_at": "2022-10-26T20:43:21",
      "remote_unique_id": "526589612",
      "account_id": 1,
      "user_id": 1,
      "invalid_identity": 0,
      "invalidated_at": "2019-05-11T00:05:01",
      "notified_at": null,
      "notification_counter": 0,
      "region": "global",
      "email": "user@example.com",
      "oauth_id": null
    },
    "relationships": {
      "remote_identity_type": {
        "data": { "type": "RemoteIdentityType", "id": "2" }
      },
      "account": {
        "data": { "type": "Account", "id": "1" }
      },
      "user": {
        "data": { "type": "User", "id": "1" }
      },
      "remote_identity_type_application": {
        "data": { "type": "RemoteIdentityTypeApplication", "id": "8" }
      },
      "oauth": { "data": null }
    }
  }
}
```

---

### List Shared Remote Identities

`/sri` stands for **shared remote identities**. An identity can be shared between multiple Openbridge accounts. This endpoint returns all identities your account has permission to use, including those originally created by another account.

Use this endpoint (rather than `/ri`) when looking up identities to attach to a subscription.

```
GET https://remote-identity.api.openbridge.io/sri
```

Common query filters:

- `remote_identity_type={id}` — filter by identity type
- `invalid_identity=0` — only valid identities
- `invalid_identity=1` — only invalid identities
- `page={n}` — page number
- `page_size={n}` — results per page
- `ordering=-id` — sort by most recently created

**Example response:**

```json
{
  "links": {
    "first": "https://remote-identity.api.openbridge.io/sri?page=1",
    "last": "https://remote-identity.api.openbridge.io/sri?page=3",
    "next": "https://remote-identity.api.openbridge.io/sri?page=2",
    "prev": ""
  },
  "data": [
    {
      "type": "RemoteIdentity",
      "id": "362",
      "attributes": {
        "name": "James Andrews",
        "created_at": "2018-02-13T18:49:51",
        "modified_at": "2022-10-26T20:43:21",
        "remote_unique_id": "526589612",
        "account_id": 1,
        "user_id": 1,
        "invalid_identity": 0,
        "region": "global",
        "email": "user@example.com",
        "oauth_id": null
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 3,
      "count": 42
    }
  }
}
```

---

### List Remote Identity Meta

Returns the metadata records (`RemoteIdentityMeta`) associated with remote identities. These records hold the encrypted credential payloads and other identity-level configuration.

```
GET https://remote-identity.api.openbridge.io/rim
```

Common query filters:

- `remote_identity={id}` — filter by remote identity ID
- `meta_format={format}` — one of `STRING`, `JSON`, `ENCRYPTED_STRING`, `ENCRYPTED_JSON`
- `page={n}`, `page_size={n}` — pagination

---

### Get Remote Identity Meta Overview

Returns a summary view of the metadata records for a specific remote identity. Useful for inspecting which meta keys are present without retrieving the full encrypted payloads.

```
GET https://remote-identity.api.openbridge.io/ri/{remote_identity_id}/rim-overview
```

Filter by meta key name:

```
GET https://remote-identity.api.openbridge.io/ri/{remote_identity_id}/rim-overview?remote_identity_type_meta_key_name={key_name}
```

---

## Response Field Reference

### RemoteIdentityType Attributes

| Field | Type | Description |
|---|---|---|
| `name` | string | Display name of the provider (e.g., `Google`, `Amazon Advertising`) |
| `auth_service` | string | Internal identifier for the authentication service used by this type |
| `created_at` | datetime | When this identity type was added to Openbridge |
| `modified_at` | datetime | When this identity type was last updated |

---

### RemoteIdentity Attributes

| Field | Type | Description |
|---|---|---|
| `name` | string | Display name of the identity |
| `created_at` | datetime | When the identity was first created |
| `modified_at` | datetime | When the identity was last updated |
| `remote_unique_id` | string | Identifying value returned by the third-party OAuth provider |
| `account_id` | integer | ID of the account that originally created the identity |
| `user_id` | integer | ID of the user that originally created the identity |
| `invalid_identity` | boolean | `0` if credentials are valid; `1` if they have been revoked or expired |
| `invalidated_at` | datetime | When the identity became invalid |
| `notified_at` | datetime | When the account was last notified of an invalid identity |
| `region` | string | Region associated with the identity (e.g., `global`, `US`) |
| `email` | string | Email address from the third-party profile, if available |
| `oauth_id` | string \| null | Association to an OAuth client ID/secret for products requiring user-provided apps (e.g., Shopify) |

### RemoteIdentity Relationships

| Field | Description |
|---|---|
| `remote_identity_type` | The type of third-party connection (e.g., Amazon, Facebook) |
| `account` | The account that owns the identity |
| `user` | The user who authorized the identity |
| `remote_identity_type_application` | Internal OAuth application used for this identity type |
| `oauth` | OAuth client credential record, if applicable |

---

## Identity Health

Identities are the authorization link between Openbridge and a third-party data source. If an identity's credentials are revoked, all subscriptions attached to it will stop processing data.

Openbridge checks identities connected to active subscriptions every 24 hours and notifies account managers when credentials become invalid. API users should also poll for invalid identities proactively, especially when reselling Openbridge to end customers — Openbridge has no direct channel to your customers, so detection and re-authorization notification is your responsibility.

### Check for invalid identities

```
GET https://remote-identity.api.openbridge.io/sri?invalid_identity=1
```

### Check for valid identities only

```
GET https://remote-identity.api.openbridge.io/sri?invalid_identity=0
```

When an invalid identity is detected, the affected user must re-authorize through the Openbridge UI to restore the OAuth connection.
