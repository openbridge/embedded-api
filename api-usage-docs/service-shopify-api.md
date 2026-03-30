# Service API: Shopify

> **Shopify REST Admin API reference**: [https://shopify.dev/docs/api/admin-rest](https://shopify.dev/docs/api/admin-rest)
> **Shopify GraphQL Admin API reference**: [https://shopify.dev/docs/api/admin-graphql](https://shopify.dev/docs/api/admin-graphql)

## When to use

Use these endpoints to verify a connected Shopify store and retrieve shop metadata before creating a Shopify subscription. Both endpoints return shop information; the GraphQL variant provides a subset of fields via the newer GraphQL Admin API.

---

## Prerequisites

- A `remote_identity_id` of type **Shopify** (the OAuth identity connected via Shopify OAuth). See [Remote Identity API](./remote-identity-api.md).
- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### Get shop info (REST)

Returns shop metadata using the Shopify REST Admin API.

```
GET /service/shopify/shop-info/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/shopify/shop-info/3307
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "shop": {
    "id": 12345678,
    "name": "My Shopify Store",
    "email": "owner@example.com",
    "domain": "mystore.com",
    "myshopify_domain": "mystore.myshopify.com",
    "province": "California",
    "country": "US",
    "address1": "123 Main St",
    "zip": "90210",
    "city": "Beverly Hills",
    "source": null,
    "phone": "+11234567890",
    "latitude": 34.0736,
    "longitude": -118.4004,
    "primary_locale": "en",
    "currency": "USD",
    "timezone": "America/Los_Angeles",
    "iana_timezone": "America/Los_Angeles",
    "shop_owner": "Jane Smith",
    "money_format": "${{amount}}",
    "money_with_currency_format": "${{amount}} USD",
    "weight_unit": "lb",
    "plan_name": "shopify",
    "plan_display_name": "Basic Shopify",
    "has_storefront": true,
    "created_at": "2020-01-15T10:00:00-05:00",
    "updated_at": "2024-03-01T08:00:00-05:00"
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `shop.id` | Numeric Shopify shop ID | — |
| `shop.name` | Store display name | Display in UI |
| `shop.myshopify_domain` | Permanent `.myshopify.com` subdomain | Use as `shop` identifier in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `shop.domain` | Custom domain (if configured) | Display in UI |
| `shop.currency` | Store's default currency | — |
| `shop.timezone` / `shop.iana_timezone` | Store timezone | — |
| `shop.plan_name` | Shopify plan identifier | — |
| `shop.created_at` | Store creation date | — |

---

### Get shop info (GraphQL)

Returns a reduced set of shop metadata using the Shopify GraphQL Admin API. Useful when you only need core identifiers.

```
GET /service/shopify/shop-graphql-info/{remote_identity_id}
```

**Example request**

```http
GET https://service.api.openbridge.io/service/shopify/shop-graphql-info/3307
Authorization: Bearer <jwt>
```

**Example response**

```json
{
  "shop": {
    "id": "gid://shopify/Shop/12345678",
    "name": "My Shopify Store",
    "email": "owner@example.com",
    "myshopifyDomain": "mystore.myshopify.com",
    "currencyCode": "USD",
    "createdAt": "2020-01-15T15:00:00Z"
  }
}
```

**Field reference**

| Field | Description | Use in subscription |
|---|---|---|
| `shop.id` | GraphQL global ID (GID format) | — |
| `shop.name` | Store display name | Display in UI |
| `shop.myshopifyDomain` | Permanent `.myshopify.com` subdomain | Use as `shop` identifier in subscription [`subscription_product_meta_attributes`](./subscriptions-api.md) |
| `shop.currencyCode` | Store's default currency code | — |
| `shop.createdAt` | Store creation timestamp (ISO 8601) | — |

---

## Choosing between REST and GraphQL

Both endpoints verify the same connected identity and return the shop's `myshopify.com` domain, which is the key identifier for subscription configuration. Use:

- **REST** (`/shop-info/`) when you need the full shop record including address, locale, plan, and formatting preferences.
- **GraphQL** (`/shop-graphql-info/`) when you only need the core identifiers and want a lighter response.
