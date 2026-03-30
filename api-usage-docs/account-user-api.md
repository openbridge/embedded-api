# Account and User API

The Account and User APIs return the account ID and user ID needed as parameters in other Openbridge API calls.

---

## Base URLs

| API | Base URL |
|---|---|
| Account | `https://account.api.openbridge.io` |
| User | `https://user.api.openbridge.io` |

---

## Authentication

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

---

## Endpoints

### Get Account

Returns the account record for the authenticated user. Use the `id` field as `account_id` in other API calls.

```
GET https://account.api.openbridge.io/account
```

---

### Get User

Returns the user record for the authenticated user. Use the `id` field as `user_id` in other API calls.

```
GET https://user.api.openbridge.io/user
```
