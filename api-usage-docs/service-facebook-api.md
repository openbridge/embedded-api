# Service API: Facebook

> **Facebook Graph API reference**: [https://developers.facebook.com/docs/graph-api](https://developers.facebook.com/docs/graph-api)

## When to use

Use these endpoints before creating a Facebook subscription to look up the ad account IDs or page IDs associated with the connected Facebook identity.

- **Ad accounts** are needed for Facebook Ads subscriptions (e.g., Ads Insights reports).
- **Page profiles** are needed for Facebook Page and Instagram Business subscriptions.

---

## Prerequisites

- A `remote_identity_id` of type **Facebook** (the OAuth identity connected via Facebook Login). See [Remote Identity API](./remote-identity-api.md).
- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### List ad accounts

Returns the Facebook ad accounts accessible to the connected identity.

```
GET /service/facebook/ads-profiles/{remote_identity_id}
```

**Query parameters**

| Parameter | Type | Description |
|---|---|---|
| `next` | string | Pagination cursor from the previous response (`includes.next`) |

**Example request**

```http
GET https://service.api.openbridge.io/service/facebook/ads-profiles/21
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "data": [
    {
      "type": "FacebookMarketing",
      "id": "123456789012345",
      "attributes": {
        "name": "My Ad Account",
        "account_id": "123456789012345",
        "account_status": 1,
        "business_name": "My Business",
        "business_city": "New York",
        "business_state": "NY",
        "end_advertiser_name": "My Brand"
      }
    }
  ],
  "includes": {
    "next": "cursor_token_abc123"
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Ad account ID (numeric string, `act_` prefix stripped) | Use as `account_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.name` | Ad account display name | Display in UI |
| `attributes.account_status` | Account status code (`1` = active) | Filter for active accounts |
| `attributes.business_name` | Associated business name | Display in UI |
| `includes.next` | Pagination cursor | Pass as `next` query param for next page |

> The `act_` prefix is stripped from the Facebook account ID in the response. The `id` field contains the bare numeric ID.

**Pagination**

If `includes.next` is non-null, there are additional pages. Pass the cursor value as the `next` query parameter:

```http
GET /service/facebook/ads-profiles/21?next=cursor_token_abc123
Authorization: Bearer <jwt>
```

---

### List page profiles

Returns the Facebook Pages managed by the connected identity, including associated Instagram Business account links.

```
GET /service/facebook/page-profiles/{remote_identity_id}
```

**Query parameters**

| Parameter | Type | Description |
|---|---|---|
| `next` | string | Pagination cursor from the previous response (`includes.next`) |

**Example request**

```http
GET https://service.api.openbridge.io/service/facebook/page-profiles/2115
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "data": [
    {
      "type": "FacebookPages",
      "id": "987654321098765",
      "attributes": {
        "name": "My Facebook Page",
        "instagram_business_account": {
          "id": "17841400000000000"
        },
        "country_page_likes": 5200,
        "name_with_location_descriptor": "My Facebook Page",
        "location": {
          "city": "San Francisco",
          "state": "CA",
          "country": "US"
        },
        "engagement": {
          "count": 5200,
          "social_sentence": "5,200 people like this."
        },
        "description": "Page description text",
        "about": "About text"
      }
    }
  ],
  "includes": {
    "next": null
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `id` | Facebook Page ID | Use as `page_id` in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `attributes.name` | Page display name | Display in UI |
| `attributes.instagram_business_account.id` | Linked Instagram Business Account ID | Use as `instagram_account_id` for Instagram subscriptions |
| `attributes.country_page_likes` | Total page likes | — |
| `includes.next` | Pagination cursor | Pass as `next` query param for next page |

**Pagination** — same pattern as ad accounts.
