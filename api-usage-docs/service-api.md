# Service API

## Overview

The Service API is the primary integration layer for the Openbridge embedded API. It serves two roles:

1. **Proxy**: Routes requests to backend APIs (jobs, history, rules, accmapping) with authentication and request signing applied automatically.
2. **Platform integrations**: Exposes endpoints that retrieve IDs and metadata needed to configure subscriptions — for example, looking up an Amazon Advertising profile ID before creating a subscription.

**Base URL**

```
https://service.api.openbridge.io/service
```

**Authentication**

All endpoints require a Bearer JWT in the `Authorization` header, the same token used across all Openbridge APIs:

```
Authorization: Bearer <jwt>
```

---

## The Proxy Pattern

The catch-all route at the bottom of the service router forwards any unmatched path to the corresponding backend API:

```
GET|POST|PUT|PATCH|DELETE /service/{backend}/{path}
```

The service API adds authentication and request signing before forwarding. The following backends are supported via proxy:

| Backend path prefix | Backend service | Reference docs |
|---|---|---|
| `history/` | History API | [history-api.md](./history-api.md) |
| `jobs/` | Jobs API | [jobs-api.md](./jobs-api.md) |
| `healthchecks/` | Healthchecks API | [service-healthchecks-api.md](./service-healthchecks-api.md) |
| `rules/` | Rules API | [service-rules-api.md](./service-rules-api.md) |
| `product-cards/` | Product Cards API | [service-product-cards-api.md](./service-product-cards-api.md) |

### Example: proxy to history API

```http
POST https://service.api.openbridge.io/service/history/production/history/113018
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "data": {
    "type": "HistoryTransaction",
    "attributes": {
      "primary_run": false,
      "product_id": 61,
      "start_date": "2023-03-10",
      "end_date": "2023-03-11"
    }
  }
}
```

---

## Platform Integration Endpoints

The platform integration endpoints follow a common pattern: pass a `remote_identity_id` in the URL path and receive structured metadata you need when creating a subscription.

All integration endpoints require a valid `remote_identity_id` — the numeric ID of the connected account (OAuth identity) stored in Openbridge. See [Remote Identity API](./remote-identity-api.md) for details. The correct identity type is noted in each integration doc.

### Integration directory

| Integration | Path prefix | Doc |
|---|---|---|
| Amazon Advertising | `/amzadv/` | [service-amazon-advertising-api.md](./service-amazon-advertising-api.md) |
| Amazon SP-API | `/sp/` | [service-amazon-sp-api.md](./service-amazon-sp-api.md) |
| Google Ads | `/googleads/` | [service-google-api.md](./service-google-api.md) |
| YouTube | `/yt/` | [service-google-api.md](./service-google-api.md) |
| Google Search Ads | `/gsa/` | [service-google-api.md](./service-google-api.md) |
| Google Campaign Manager | `/gcm/` | [service-google-api.md](./service-google-api.md) |
| Facebook | `/facebook/` | [service-facebook-api.md](./service-facebook-api.md) |
| Shopify | `/shopify/` | [service-shopify-api.md](./service-shopify-api.md) |
