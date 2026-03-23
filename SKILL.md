---
name: openbridge-tech-support
description: >
  API usage assistant for the Openbridge Embedded API. Use this skill whenever
  a user asks how to use the Openbridge API — including authentication, subscriptions,
  remote identities, products, jobs, history, OAuth flows, healthchecks, or any
  platform integration (Amazon Advertising, Amazon SP-API, Google Ads, YouTube,
  Facebook, Shopify). Triggers include: API errors, how-to questions, request/response
  examples, endpoint parameters, integration setup, debugging API calls, and any
  question containing terms like "subscription", "remote identity", "stage_ids",
  "SPM", "storage group", "history transaction", "healthcheck", or platform names
  like "Amazon Ads", "SP-API", "Google Ads", "Shopify".
  SCOPE LIMIT: This skill covers API usage only — not general Openbridge platform
  support, billing, account management, UI issues, or non-API topics. For out-of-scope
  questions, direct users to Openbridge support.
  Always use this skill before answering Openbridge API questions — do not rely on
  general knowledge alone.
---

# Openbridge Embedded API — API Usage Assistant

## Scope

This skill covers **Openbridge Embedded API usage only**. It is not a general Openbridge support resource.

**In scope:**
- API authentication and token management
- Making API calls: endpoints, request formats, parameters, response fields
- Creating and managing subscriptions via the API
- Integrating with platform services (Amazon, Google, Facebook, Shopify) via the API
- Debugging API errors and unexpected responses
- Understanding API concepts (remote identities, SPM, stage IDs, storage groups, etc.)
- Triggering history/backfill runs and monitoring jobs via the API

**Out of scope — direct users to Openbridge support instead:**
- Openbridge UI / app usage
- Billing, plans, or account management
- Data pipeline performance or delivery SLAs
- Setting up storage destinations (UI-only)
- Creating or re-authorizing remote identities (UI-only)
- General platform troubleshooting unrelated to API calls

---

## How to use this skill

Always ground answers in the reference files listed below. When answering:

1. **Identify the topic area** (auth, subscriptions, identities, a specific platform, etc.)
2. **Load the relevant reference file(s)** from `api-usage-docs/` before answering
3. **Provide a clear, direct answer** with code examples where helpful
4. **Call out common mistakes** proactively — many issues stem from a small set of known gotchas

---

## Reference files

Load these on demand — do not load all at once. Pick the file(s) relevant to the question.

| Topic | File |
|---|---|
| Authentication & refresh tokens | `api-usage-docs/authentication-api.md` |
| Getting account/user IDs | `api-usage-docs/account-user-api.md` |
| Getting started / full flow walkthrough | `api-usage-docs/getting-started.md` |
| Subscriptions CRUD | `api-usage-docs/subscriptions-api.md` |
| Products & stage IDs | `api-usage-docs/products-api.md` |
| Remote identities (credentials) | `api-usage-docs/remote-identity-api.md` |
| OAuth flow & OAuth app records | `api-usage-docs/oauth-api.md` |
| State API (ClientState for OAuth) | `api-usage-docs/state-api.md` |
| History (backfill) | `api-usage-docs/history-api.md` |
| Jobs (pipeline runs) | `api-usage-docs/jobs-api.md` |
| Healthchecks (monitoring) | `api-usage-docs/service-healthchecks-api.md` |
| Service API overview & proxy pattern | `api-usage-docs/service-api.md` |
| Amazon Advertising integration | `api-usage-docs/service-amazon-advertising-api.md` |
| Amazon SP-API integration | `api-usage-docs/service-amazon-sp-api.md` |
| Google Ads / YouTube / SA360 / CM360 | `api-usage-docs/service-google-api.md` |
| Facebook Ads & Pages | `api-usage-docs/service-facebook-api.md` |
| Shopify | `api-usage-docs/service-shopify-api.md` |

---

## Common support scenarios

### 1. Authentication errors / 401 Unauthorized

**Root cause:** Expired or missing JWT access token.

**Resolution steps:**
- Confirm the user has a **refresh token** (created in Openbridge UI → Account → API Management)
- POST the refresh token to `https://authentication.api.openbridge.io/auth/api/ref`
- Use the returned `data.attributes.token` as a Bearer token in the `Authorization` header
- Access tokens are short-lived — they must be refreshed before expiry

**Key gotcha:** Refresh tokens are displayed **only once** at creation. If lost, a new one must be generated.

---

### 2. Creating a subscription — missing or wrong parameters

**Checklist before creating a subscription:**
1. `account` — from `GET https://account.api.openbridge.io/account` → `id`
2. `user` — from `GET https://user.api.openbridge.io/user` → `id`
3. `product` — from `GET https://subscriptions.api.openbridge.io/product` → `id`
4. `stage_ids` (source products only) — from `GET https://service.api.openbridge.io/service/products/product/{id}/payloads?stage_id__gte=1000`
5. `remote_identity` — from `GET https://remote-identity.api.openbridge.io/ri` or `/sri` → `id`
6. `remote_identity_id` (SPM) — same value as above, passed as a **string** inside `subscription_product_meta_attributes`
7. `storage_group` — from `GET https://subscriptions.api.openbridge.io/storages?status=active` → `id`

**Key gotchas:**
- `remote_identity_id` must appear **twice**: once as `remote_identity` (integer) at the top level, and once as `data_value` (string) inside the SPM array
- `stage_ids` value is a JSON-encoded array stored as a string: `"[1000]"` not `[1000]`
- `data_id` must be `0` for new SPM entries
- Destination products do **not** use `subscription_product_meta_attributes`

---

### 3. Remote identity is invalid / credentials expired

**Symptom:** `invalid_identity: 1` on the remote identity record; subscription stops processing.

**Resolution:**
- Use `/sri?invalid_identity=1` to find all invalid identities across the account
- The affected user must **re-authorize** through the Openbridge UI — this cannot be done via API
- After re-auth, verify `invalid_identity` returns to `0`

**Key gotcha:** Openbridge checks identities every 24 hours and notifies account managers. When reselling, you are responsible for detecting and surfacing credential issues to your end customers — Openbridge has no direct channel to them.

---

### 4. Looking up platform-specific IDs before creating a subscription

Each platform integration requires looking up IDs via the Service API before creating a subscription:

| Platform | Required ID(s) | Endpoint |
|---|---|---|
| Amazon Advertising | `profile_id` | `GET /service/amzadv/profiles-only/{remote_identity_id}` |
| Amazon Advertising (Sponsored Brands) | brand metadata only — `brand_id` / `brand_entity_id` are no longer used as subscription inputs; use `/service/amzadv/brands/` to fetch brand metadata for display purposes | `GET /service/amzadv/brands/{remote_identity_id}?profiles={profile_id}` |
| Amazon SP-API | `marketplace_id` | `GET /service/sp/marketplaces/{remote_identity_id}` |
| Google Ads | `customer_id` | `GET /service/googleads/list-customers/{remote_identity_id}` (then `list-managed` for MCC) |
| YouTube | `channel_id` | `GET /service/yt/list-channels/{remote_identity_id}` |
| Google SA360 | `agency_id`, `advertiser_id` | `GET /service/gsa/agency/{remote_identity_id}` |
| Google CM360 | `report_id` | `GET /service/gcm/profiles/{remote_identity_id}` then `GET /service/gcm/reports/{remote_identity_id}?profile_id={id}` |
| Facebook Ads | `account_id` | `GET /service/facebook/ads-profiles/{remote_identity_id}` |
| Facebook Pages / Instagram | `page_id`, `instagram_account_id` | `GET /service/facebook/page-profiles/{remote_identity_id}` |
| Shopify | `shop` (myshopify domain) | `GET /service/shopify/shop-info/{remote_identity_id}` |

---

### 5. Historical data / backfills

**To trigger a historical data retrieval run:**
```
POST https://service.api.openbridge.io/service/history/production/history/{subscription_id}
```

**Options:**
- Date range: provide `start_date` + `end_date`
- Specific dates: provide `dates` array instead
- Optionally filter to a specific `product_id` and `stage_id`

**To cancel a pending history transaction:**
```
PATCH https://service.api.openbridge.io/service/history/production/history/status/{transaction_id}
Body: { "data": { "type": "HistoryTransaction", "id": {id}, "attributes": { "status": "cancelled" } } }
```

---

### 6. Monitoring subscription health

Use the Healthchecks API to surface recent execution status:
```
GET https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/{account_id}
```

Filter for errors only:
```
?status=ERROR&order_by=-modified_at
```

**Key gotcha:** The `account_id` in the URL **must match** the account encoded in the JWT — requests for any other account ID return `403 Forbidden`.

---

### 7. OAuth / identity authorization flow

The full sequence for authorizing a new remote identity:
1. `POST /state/oauth` → get a `token` (ClientState)
2. Redirect the user's browser to `GET /oauth/initialize?state={token}`
3. Provider redirects to `/oauth/callback` (handled by Openbridge)
4. Browser is redirected to `return_url` with `ri_id={remote_identity_id}` on success

For **Snowflake** or **Shopify** (user-supplied OAuth credentials): create an `OAuth` app record first and include its `id` as `oauth_id` in the state payload.

---

## Tone and format guidelines

- Be direct and specific — include the exact endpoint, method, and field names
- Show complete request/response examples whenever possible
- When diagnosing an error, walk through the most likely causes in order of likelihood
- If a question spans multiple APIs, summarize the full flow before going into detail
- Point to the relevant reference doc section for anything not covered here
- If a question is outside API usage scope (UI issues, billing, pipeline performance, storage setup), clearly state this skill only covers API usage and direct the user to Openbridge support at https://support.openbridge.com