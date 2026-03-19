# Service API: Google Platform Integrations

This document covers the Service API endpoints for four Google platform integrations: Google Ads, YouTube, Google Search Ads 360, and Google Campaign Manager 360.

| Integration | First-party documentation |
|---|---|
| Google Ads | [https://developers.google.com/google-ads/api/docs/start](https://developers.google.com/google-ads/api/docs/start) |
| YouTube Data API | [https://developers.google.com/youtube/v3](https://developers.google.com/youtube/v3) |
| Google Search Ads 360 | [https://developers.google.com/search-ads](https://developers.google.com/search-ads) |
| Google Campaign Manager 360 | [https://developers.google.com/doubleclick-advertisers/rest/v4](https://developers.google.com/doubleclick-advertisers/rest/v4) |

---

## Prerequisites

- A `remote_identity_id` of type **Google** (the OAuth identity connected via Google OAuth). See [Remote Identity API](./remote-identity-api.md).
- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Google Ads

### When to use

Use these endpoints before creating a Google Ads subscription to look up the customer IDs available under the connected identity. Google Ads accounts have a manager (MCC) / client hierarchy; use `list-customers` to find top-level accessible accounts, then `list-managed` to drill into sub-accounts under a manager.

---

### List accessible customers

Returns the Google Ads accounts directly accessible to the connected identity.

```
GET /service/googleads/list-customers/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/googleads/list-customers/3146
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": 4156813945,
    "descriptive_name": "My Ads Account",
    "currency_code": "USD",
    "time_zone": "America/New_York",
    "auto_tagging_enabled": true,
    "has_partners_badge": false,
    "manager": false,
    "test_account": false
  },
  {
    "id": 9876543210,
    "descriptive_name": "My MCC Account",
    "currency_code": "USD",
    "time_zone": "America/Chicago",
    "auto_tagging_enabled": false,
    "has_partners_badge": false,
    "manager": true,
    "test_account": false
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Google Ads customer ID (numeric) | Use as `customer_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `descriptive_name` | Human-readable account name | Display in UI |
| `manager` | `true` if this is a manager (MCC) account | If `true`, call `list-managed` to get client accounts |
| `currency_code` | Account currency | — |
| `time_zone` | Account timezone | — |
| `test_account` | `true` if this is a test account | Exclude test accounts from production subscriptions |

---

### List managed customers

Returns the client accounts managed under a given manager (MCC) customer ID.

```
GET /service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}
```

| Path parameter | Description |
|---|---|
| `remote_identity_id` | Remote identity ID |
| `google_ads_customer_id` | The manager account customer ID (from `list-customers`) |

**Example request**

```http
GET https://service.api.openbridge.io/service/googleads/list-managed/178/4156813945
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "manager": {
    "id": 4156813945,
    "name": "My MCC Account"
  },
  "attributes": [
    {
      "id": 1234567890,
      "descriptive_name": "Client Account A",
      "currency_code": "USD",
      "time_zone": "America/Los_Angeles",
      "test_account": false,
      "level": 1,
      "resource_name": "customers/1234567890"
    }
  ]
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `attributes[].id` | Client account customer ID | Use as `customer_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes[].descriptive_name` | Human-readable client account name | Display in UI |
| `attributes[].level` | Depth in the MCC hierarchy | — |
| `manager.id` | The manager account's customer ID | — |

---

## YouTube

### When to use

Use these endpoints before creating a YouTube subscription to identify the channel IDs accessible to the connected identity, and to validate a channel URL or handle before storing it.

---

### List channels

Returns the YouTube channels owned by the connected identity.

```
GET /service/yt/list-channels/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/yt/list-channels/4801
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "kind": "youtube#channel",
    "etag": "...",
    "id": "UCxxxxxxxxxxxxxxxxxxxxxx",
    "snippet": {
      "title": "My YouTube Channel",
      "description": "Channel description",
      "customUrl": "@mychannel",
      "country": "US",
      "thumbnails": { ... }
    },
    "contentDetails": { ... },
    "brandingSettings": { ... },
    "status": { ... }
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | YouTube channel ID | Use as `channel_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `snippet.title` | Channel display name | Display in UI |
| `snippet.customUrl` | Channel handle (e.g. `@mychannel`) | — |
| `snippet.country` | Channel country | — |

---

### Get channel metadata

Resolves a YouTube channel URL or handle to its channel ID and metadata. Accepts several URL formats including `/channel/`, `/c/`, `/user/`, and `/@handle` forms.

```
GET /service/yt/get-channel-meta/{remote_identity_id}?channel_id={channel_url}
```

**Query parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `channel_id` | string | Yes | Full YouTube channel URL (e.g. `https://www.youtube.com/@channelname`) |

**Example request**

```http
GET https://service.api.openbridge.io/service/yt/get-channel-meta/892?channel_id=https://www.youtube.com/@thenetimp
Authorization: Bearer <jwt>
```

**Supported URL formats**

- `https://www.youtube.com/channel/UCxxxxxxxx`
- `https://www.youtube.com/c/ChannelName`
- `https://www.youtube.com/user/Username`
- `https://www.youtube.com/@handle`

**Example response**

```json
{
  "id": "UCxxxxxxxxxxxxxxxxxxxxxx",
  "type": "YoutubeChannelMetadata",
  "attributes": {
    "statistics": {
      "viewCount": "12345678",
      "subscriberCount": "100000",
      "videoCount": "500"
    },
    "country": "US",
    "customUrl": "@thenetimp",
    "title": "The Channel Name",
    "description": "Channel description text",
    "thumbnails": { ... }
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | YouTube channel ID | Use as `channel_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.title` | Channel display name | Display in UI |
| `attributes.customUrl` | Channel handle | — |
| `attributes.statistics.subscriberCount` | Subscriber count | — |

**Error responses**

| Status | Meaning |
|---|---|
| `400 Bad Request` | Invalid channel identifier format |
| `404 Not Found` | Channel not found |

---

## Google Search Ads 360

### When to use

Use this endpoint before creating a Google Search Ads 360 (SA360) subscription to look up the agency and advertiser IDs accessible to the connected identity.

---

### List agencies and advertisers

Returns the SA360 agencies and advertisers accessible to the connected Google identity.

```
GET /service/gsa/agency/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/gsa/agency/2
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": "20700000001234567:21700000001234567",
    "attributes": {
      "agency": "My Agency",
      "agencyId": "20700000001234567",
      "advertiser": "My Advertiser",
      "advertiserId": "21700000001234567"
    }
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Composite `agencyId:advertiserId` | — |
| `attributes.agencyId` | SA360 agency ID | Use as `agency_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.advertiserId` | SA360 advertiser ID | Use as `advertiser_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.agency` | Agency display name | Display in UI |
| `attributes.advertiser` | Advertiser display name | Display in UI |

---

## Google Campaign Manager 360

### When to use

Use these endpoints before creating a Campaign Manager 360 (CM360) subscription to look up the user profile ID and then enumerate the reports accessible to that profile.

---

### List user profiles

Returns the Campaign Manager 360 user profiles accessible to the connected identity.

```
GET /service/gcm/profiles/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/gcm/profiles/892
Authorization: Bearer <jwt>
```

**Example response**

```json
[
  {
    "id": "5905858",
    "attributes": {
      "kind": "dfareporting#userProfile",
      "username": "user@example.com",
      "accountId": "12345678",
      "accountName": "My CM360 Network",
      "etag": "..."
    }
  }
]
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | CM360 user profile ID | Pass to `/gcm/reports/` as `profile_id` query param |
| `attributes.accountId` | CM360 network account ID | — |
| `attributes.accountName` | CM360 network display name | Display in UI |
| `attributes.username` | Google account email | — |

---

### List reports

Returns the Campaign Manager 360 reports accessible to the specified user profile.

```
GET /service/gcm/reports/{remote_identity_id}?profile_id={profile_id}
```

**Query parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `profile_id` | string | Yes | CM360 user profile ID (from `list profiles`) |
| `next` | string | No | Pagination token from the previous response |

**Example request**

```http
GET https://service.api.openbridge.io/service/gcm/reports/825?profile_id=5905858
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "data": [
    {
      "id": "199403538",
      "attributes": {
        "kind": "dfareporting#report",
        "name": "My Campaign Report",
        "type": "STANDARD",
        "accountId": "12345678",
        "ownerProfileId": "5905858",
        "lastModifiedTime": "1234567890000",
        "criteria": { ... },
        "schedule": { ... }
      }
    }
  ],
  "includes": {
    "next": "CjT4uXb7..."
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | CM360 report ID | Use as `report_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.name` | Report display name | Display in UI |
| `attributes.type` | Report type (e.g. `STANDARD`, `FLOODLIGHT`) | — |
| `includes.next` | Pagination token | Pass as `next` query param for next page |

> Results are paginated at 10 reports per page. Pass `includes.next` as the `next` query parameter to fetch additional pages.
