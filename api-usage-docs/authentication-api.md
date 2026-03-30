# Authentication API

All Openbridge API calls require a JWT access token passed as a Bearer token in the `Authorization` header. That token is short-lived and must be obtained by posting a long-lived refresh token to the Authentication API — the refresh token itself is created once in the Openbridge UI.

---

## Base URL

| API | Base URL |
|---|---|
| Authentication | `https://authentication.api.openbridge.io` |

---

## Step 1 — Create a Refresh Token

Refresh tokens are created in the Openbridge UI, not via the API.

1. Navigate to **Account → API Management** and click **Create Refresh Token**.
2. Choose a name and click **Create**. The token is displayed once — copy and store it securely. It cannot be retrieved again; if lost, a new token must be generated.

---

## Step 2 — Exchange Refresh Token for an Access Token

Post your refresh token to receive a short-lived JWT access token.

```
POST https://authentication.api.openbridge.io/auth/api/ref
```

**Request body:**

```json
{
  "data": {
    "type": "APIAuth",
    "attributes": {
      "refresh_token": "{your_refresh_token}"
    }
  }
}
```

The JWT access token is returned in `data.attributes.token`. Use it as a Bearer token in the `Authorization` header of all subsequent API calls:

```
Authorization: Bearer {your_access_token}
```

---

## Field Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `refresh_token` | string | Yes | The refresh token generated in the Openbridge UI |
