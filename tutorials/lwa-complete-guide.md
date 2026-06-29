# Login with Amazon (LWA) — Complete Integration Guide

## Table of Contents

1. [Overview](#1-overview)
   - [What LWA Requires](#what-lwa-actually-requires)
   - [Additional Requirements by Service](#additional-requirements-by-service)
   - [The Multi-Identity Problem](#the-multi-identity-problem)
   - [The Authorization Flow in Practice](#the-authorization-flow-in-practice)
   - [Where Things Break](#where-things-break)
   - [Openbridge Identity Management](#openbridge-identity-management)
2. [Amazon Advertising API](#2-amazon-advertising-api)
   - [Prerequisites](#advertising-prerequisites)
   - [Onboarding Steps](#advertising-onboarding-steps)
   - [OAuth Scopes](#oauth-scopes)
   - [Authorization Flow](#advertising-authorization-flow)
   - [Regional Endpoints](#advertising-regional-endpoints)
   - [Making API Requests](#advertising-making-api-requests)
   - [Rate Limits & Best Practices](#rate-limits--best-practices)
3. [Seller Central (Selling Partner API)](#3-seller-central-selling-partner-api)
   - [Prerequisites](#seller-prerequisites)
   - [Application Types](#seller-application-types)
   - [Onboarding Steps](#seller-onboarding-steps)
   - [Public App Authorization](#seller-public-app--website-authorization-workflow)
   - [Private App Authorization](#seller-private-app--self-authorization)
   - [Token Refresh](#seller-token-refresh)
   - [Making API Requests](#seller-making-api-requests)
   - [Key API Sections](#seller-key-api-sections)
4. [Vendor Central (Selling Partner API)](#4-vendor-central-selling-partner-api)
   - [Prerequisites](#vendor-prerequisites)
   - [Application Types](#vendor-application-types)
   - [Onboarding Steps](#vendor-onboarding-steps)
   - [Public App Authorization](#vendor-public-app--website-authorization-workflow)
   - [Private App Authorization](#vendor-private-app--self-authorization)
   - [Multi-Account Authorization](#multi-account-authorization)
   - [Token Refresh](#vendor-token-refresh)
   - [Making API Requests](#vendor-making-api-requests)
   - [Vendor-Specific APIs](#vendor-specific-api-sections)
   - [Key Differences from Seller Central](#key-differences-from-seller-central)
5. [Regional Endpoints Reference](#5-regional-endpoints-reference)
   - [Advertising API Endpoints](#advertising-api-endpoints)
   - [Seller Central Endpoints](#seller-central-authorization-consent-urls)
   - [Vendor Central Endpoints](#vendor-central-authorization-consent-urls)
   - [SP-API Endpoints](#sp-api-endpoints)
   - [Token Endpoints](#shared-token-endpoints)
   - [Marketplace IDs](#marketplace-ids)
   - [Key Differences Between Services](#key-differences-between-services)
6. [The OAuth `state` Parameter](#6-the-oauth-state-parameter)
   - [Dual Purpose](#dual-purpose)
   - [Implementation Patterns](#implementation-patterns)
   - [Real-World Use Cases](#real-world-use-cases)
   - [Security Requirements](#security-requirements)
   - [Amazon-Specific Notes](#amazon-specific-notes)
   - [Common Mistakes](#common-mistakes)
7. [Button Guidelines](#7-button-guidelines)
   - [Button Images](#button-images)
   - [Image URLs](#image-urls)
   - [Implementation](#button-implementation)
   - [Multilingual Buttons](#multilingual-buttons)
   - [Platform-Specific Assets](#platform-specific-assets)
8. [Security Best Practices](#8-security-best-practices)
9. [Sources](#9-sources)

---

## 1. Overview

Amazon requires OAuth 2.0 authentication — via Login with Amazon (LWA) — to access its APIs programmatically. Whether you're pulling advertising reports, syncing seller orders, or automating vendor purchase order confirmations, every API call starts with an LWA identity.

This guide covers what's involved in connecting to the three primary Amazon API surfaces:

- **Amazon Advertising API** — campaign management, reporting, bid optimization
- **Seller Central (Selling Partner API)** — orders, inventory, fulfillment, listings
- **Vendor Central (Selling Partner API)** — purchase orders, shipments, invoices, direct fulfillment

Each requires its own LWA authorization, its own credentials, and its own token lifecycle management.

### What LWA Actually Requires

#### For Every Connection You Need:

1. **An LWA Application** — registered through the Amazon Developer Console with a security profile, client ID, and client secret
2. **Authorization** — the account holder must consent via an Amazon-hosted page, producing an authorization code
3. **Token Exchange** — your system exchanges that code for an access token (expires hourly) and a refresh token (expires after 365 days)
4. **Ongoing Token Refresh** — every API call needs a valid access token, so your system must continuously refresh tokens before they expire

### Additional Requirements by Service

| Requirement | Advertising API | Seller Central | Vendor Central |
|-------------|:-:|:-:|:-:|
| LWA security profile | Yes | Yes | Yes |
| AWS IAM user + role | No | Yes | Yes |
| AWS request signing (SigV4) | No | Yes | Yes |
| API access application/approval | Yes | Yes | Yes |
| Regional endpoint management | Yes | Yes | Yes |
| Separate credentials per app type | N/A | Yes (public vs private) | Yes (public vs private) |

Seller Central and Vendor Central add significant infrastructure overhead — you need an AWS account, IAM policies, and every API request must be signed with AWS Signature Version 4 on top of the LWA token.

### The Multi-Identity Problem

Most real-world Amazon integrations aren't one account, one marketplace. They look more like:

- A brand selling via Seller Central in the US, UK, and Germany
- The same brand also running Sponsored Products campaigns via the Advertising API in all three regions
- A vendor relationship in Europe through Vendor Central
- An agency managing 15 seller accounts across 4 marketplaces

Each of these is a **separate LWA identity** with its own:
- Authorization consent flow
- Refresh token
- Access token lifecycle
- Regional endpoint routing
- Expiration timeline

At 5 accounts across 3 services, you're managing 15 token pairs. At agency scale, it's hundreds.

#### What You Need to Build

To manage this yourself, your system must:

- **Store tokens securely** — refresh tokens are long-lived credentials that grant API access. They need encryption at rest, access controls, and audit logging.
- **Track expiration** — refresh tokens expire after 365 days. Miss the window and the account holder must re-authorize manually. Amazon sends a reminder email 30 days before expiration, but that email goes to the account holder, not your system.
- **Handle reauthorization** — when tokens expire or are revoked, your system needs to detect the failure, notify the right user, present the correct regional authorization URL, and process the new tokens.
- **Route regionally** — authorization URLs, token endpoints, and API endpoints all vary by region. A US seller authorizes through `sellercentral.amazon.com`, a German seller through `sellercentral-europe.amazon.com`, a Japanese vendor through `vendorcentral.amazon.co.jp`. Your system must route each identity to the correct endpoints.
- **Map identities to users** — one user in your system may have multiple Amazon identities across services and regions. Your data model needs to support this relationship cleanly.

This is a database, a token management service, a notification system, a regional routing layer, and a reauthorization workflow — before you've made a single API call to get actual data.

### The Authorization Flow in Practice

#### Step 1: Redirect to Amazon

Your application sends the user to the correct Amazon consent page. **The URL resolution differs by service:**

- **Advertising API** — 3 regional URLs (NA, EU, FE). A single URL covers all marketplaces within that region.
- **Seller Central** — marketplace-specific URLs. Each marketplace has its own Seller Central URL, though 5 core EU markets (UK, DE, FR, IT, ES) share `sellercentral-europe.amazon.com`.
- **Vendor Central** — marketplace-specific URLs with a **unique URL per marketplace**. Unlike Seller Central, no EU markets share a URL.

| Service | URL Pattern | Example |
|---------|-------------|---------|
| Advertising (NA) | Regional | `https://www.amazon.com/ap/oa?client_id=...&scope=advertising::campaign_management&response_type=code&redirect_uri=...&state=...` |
| Advertising (EU) | Regional | `https://eu.account.amazon.com/ap/oa?client_id=...&scope=advertising::campaign_management&response_type=code&redirect_uri=...&state=...` |
| Seller Central (US) | Per marketplace | `https://sellercentral.amazon.com/apps/authorize/consent?application_id=...&state=...` |
| Seller Central (DE) | Per marketplace (shared EU) | `https://sellercentral-europe.amazon.com/apps/authorize/consent?application_id=...&state=...` |
| Seller Central (NL) | Per marketplace (own URL) | `https://sellercentral.amazon.nl/apps/authorize/consent?application_id=...&state=...` |
| Vendor Central (US) | Per marketplace | `https://vendorcentral.amazon.com/apps/authorize/consent?application_id=...&state=...` |
| Vendor Central (DE) | Per marketplace | `https://vendorcentral.amazon.de/apps/authorize/consent?application_id=...&state=...` |
| Vendor Central (JP) | Per marketplace | `https://vendorcentral.amazon.co.jp/apps/authorize/consent?application_id=...&state=...` |

See the [Regional Endpoints Reference](#5-regional-endpoints-reference) for the complete list of marketplace-specific URLs.

#### Step 2: Handle the Callback

Amazon redirects back with an authorization code. Your system must:

1. Validate the `state` parameter matches your session
2. Exchange the code for tokens within 5 minutes
3. Store the refresh token securely against the correct user and identity
4. Begin the access token refresh cycle

#### Step 3: Maintain the Connection

This is the part that never ends:

- Access tokens expire every **60 minutes** — refresh proactively
- Refresh tokens expire after **365 days** — track and trigger reauthorization before expiry
- Tokens can be **revoked** at any time by the account holder — detect `401` responses and initiate reauthorization
- **Regional endpoints change** — Amazon occasionally updates URL structures

### Where Things Break

| Failure Mode | Impact | Recovery |
|-------------|--------|----------|
| Missed refresh token expiration | Complete loss of API access for that identity | Manual reauthorization by account holder |
| Wrong regional endpoint | Auth failures, data from wrong marketplace | Correct endpoint routing per identity |
| Token storage breach | Unauthorized API access to Amazon accounts | Rotate credentials, revoke tokens, re-authorize |
| Rate limiting during token refresh | Cascading failures across identities | Backoff logic, staggered refresh schedules |
| Account holder revokes access | Silent failure until next API call | Detection, notification, reauthorization flow |

### Openbridge Identity Management

Openbridge handles all of this as a managed service. When you create an identity through Openbridge:

- **Authorization is guided** — users are routed to the correct regional consent page for their service and marketplace. No need to know which URL belongs to which region.
- **Tokens are managed** — storage, encryption, refresh cycling, and expiration tracking are handled automatically. No database to build or maintain.
- **Multiple identities per account** — connect Advertising, Seller Central, and Vendor Central identities across any combination of regions and marketplaces under a single Openbridge account.
- **Reauthorization is automated** — when tokens approach expiration or are revoked, Openbridge detects the issue and guides the account holder through reauthorization. No dropped connections because an email reminder went to spam.
- **No AWS infrastructure required** — even for Seller Central and Vendor Central APIs that normally require IAM users, roles, and SigV4 request signing, Openbridge abstracts the AWS layer entirely.

For developers building on Amazon data — whether for analytics dashboards, AI/ML pipelines, or automated campaign management — Openbridge eliminates the identity infrastructure so you can focus on what you do with the data, not how you authenticate to get it.

---

## 2. Amazon Advertising API

The Amazon Advertising API uses OAuth 2.0 via Login with Amazon (LWA) for authentication. It allows programmatic management of Sponsored Products, Sponsored Brands, Sponsored Display campaigns, reporting, and more.

The API is **free to use** with no per-call charges.

### Advertising Prerequisites

- An Amazon Ads account (via Seller Central or Vendor Central with a professional plan)
- A valid Privacy Policy URL
- Access to the [Amazon Developer Console](https://developer.amazon.com)

### Advertising Onboarding Steps

#### Step 1: Create a Login with Amazon (LWA) Application

1. Sign in to [developer.amazon.com](https://developer.amazon.com)
2. Navigate to **Developer Console > Login with Amazon**
3. Click **Create a New Security Profile**
4. Fill out:
   - Security Profile Name
   - Security Profile Description
   - Consent Privacy Notice URL
5. Save, then click **Show Client ID and Client Secret** — store these securely

#### Step 2: Apply for Amazon Ads API Access

1. Go to the [Amazon Ads API onboarding page](https://advertising.amazon.com/API/docs/en-us/guides/onboarding/apply-for-access)
2. Submit the **Direct Advertiser API access** application form
3. Select **"Advertising"** under Data and Access
4. Amazon typically approves within **72 hours**
5. For issues, contact: `ads-api-onboarding@amazon.com`

#### Step 3: Assign API Access to Your LWA Application

After approval, you must explicitly assign API access to your LWA application. Skipping this step will prevent your client ID from requesting the `advertising::campaign_management` scope.

Follow the instructions at: [Assign API access to a Login with Amazon application](https://advertising.amazon.com/API/docs/en-us/guides/onboarding/assign-api-access)

### OAuth Scopes

| Scope | Purpose |
|-------|---------|
| `advertising::campaign_management` | Required for all campaign management API calls |
| `advertising::test:create_account` | For creating test/sandbox accounts |

> **Common mistake:** Using `advertising:campaign_management` (single colon) instead of `advertising::campaign_management` (double colon).

### Advertising Authorization Flow

#### 1. Redirect User to Amazon Consent Page

```
GET https://www.amazon.com/ap/oa
  ?client_id=YOUR_CLIENT_ID
  &scope=advertising::campaign_management
  &response_type=code
  &redirect_uri=YOUR_REDIRECT_URI
  &state=YOUR_STATE_VALUE
```

> **Note:** The `state` parameter is not merely a random number — it preserves application context across the redirect round-trip. See the [state parameter](#6-the-oauth-state-parameter) section for full details.

#### 2. Receive Authorization Code

Amazon redirects back to your `redirect_uri` with:
- `code` — authorization code (valid for **5 minutes**)
- `state` — must match your original value (used for CSRF protection and application state management)

#### 3. Exchange Code for Tokens

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=AUTH_CODE
&redirect_uri=YOUR_REDIRECT_URI
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
```

**Response:**
```json
{
  "access_token": "Atza|...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "Atzr|..."
}
```

#### 4. Refresh Access Token

Access tokens expire after **1 hour**. Recommended: refresh every 55 minutes.

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=YOUR_REFRESH_TOKEN
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
```

### Advertising Regional Endpoints

#### Authorization URLs (LWA)

| Region | Authorization URL |
|--------|------------------|
| North America | `https://www.amazon.com/ap/oa` |
| Europe | `https://eu.account.amazon.com/ap/oa` |
| Far East | `https://apac.account.amazon.com/ap/oa` |

#### Token Endpoints

| Region | Token Endpoint |
|--------|---------------|
| North America | `https://api.amazon.com/auth/o2/token` |
| Europe | `https://api.amazon.co.uk/auth/o2/token` |
| Far East | `https://api.amazon.co.jp/auth/o2/token` |

#### API Base URLs

| Region | Base URL |
|--------|----------|
| North America | `https://advertising-api.amazon.com` |
| Europe | `https://advertising-api-eu.amazon.com` |
| Far East | `https://advertising-api-fe.amazon.com` |

### Advertising Making API Requests

#### Required Headers

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer {access_token}` |
| `Amazon-Advertising-API-ClientId` | Your LWA Client ID (static, does not expire) |
| `Amazon-Advertising-API-Scope` | A profile ID from the Profiles endpoint |

> **Important:** `ClientId` and `Scope` must be sent as **headers**, not query parameters.

#### Get Profile IDs

Before making campaign calls, retrieve your advertising profile IDs:

```
GET https://advertising-api.amazon.com/v2/profiles
Authorization: Bearer {access_token}
Amazon-Advertising-API-ClientId: {client_id}
```

Use the returned `profileId` as the `Amazon-Advertising-API-Scope` header value in subsequent requests.

### Rate Limits & Best Practices

- Batch multiple operations into single API calls where possible
- Distribute large data requests over time to avoid throttling
- Monitor HTTP status codes: `401` (auth expired), `429` (rate limited)
- Implement retry logic with exponential backoff (up to 3 retries)
- Design systems to handle 10x current data volume

---

## 3. Seller Central (Selling Partner API)

The Selling Partner API (SP-API) uses OAuth 2.0 via Login with Amazon (LWA) for authentication. It replaces the legacy MWS (Marketplace Web Service) API and provides access to seller operations including orders, inventory, fulfillment, reports, and more.

### Seller Prerequisites

- An active Amazon Seller Central account (Professional plan)
- An AWS account with IAM user and IAM role configured
- Access to the [Seller Central Developer Console](https://sellercentral.amazon.com)

### Seller Application Types

| Type | Use Case | Authorization | Credentials | Credential Cardinality |
|------|----------|---------------|-------------|----------------------|
| **Public** | Third-party apps serving multiple sellers | OAuth consent flow (website workflow) | Own LWA Client ID, Client Secret, Application ID | **One set per registered app** — your app owns these credentials |
| **Private** | Your own seller account(s) only | Self-authorization in Seller Central | Own LWA Client ID, Client Secret (separate from public) | **One set per authorized account/marketplace** — a single organization may have dozens |

> **Critical for implementation:** Public and private apps are **separate registered applications** in Amazon, each with their own LWA Client ID and Client Secret. If your application supports both public and private flows, you must store and use separate credentials for each. Do not share a single `client_id` / `client_secret` across both app types.

### Seller Onboarding Steps

#### Step 1: Register as a Developer

1. Sign in to [Seller Central](https://sellercentral.amazon.com)
2. Go to **Partner Network > Develop Apps**
3. Complete the developer registration form

#### Step 2: Create an AWS IAM User and Role

1. Create an IAM user with **programmatic access** in your AWS account
2. Create an IAM role with the **Selling Partner API** trust policy
3. Attach an IAM policy granting SP-API access
4. Save the **Access Key**, **Secret Key**, and **Role ARN**

#### Step 3: Register Your Application

1. In Seller Central, go to **Partner Network > Develop Apps**
2. Click **Add new app client**
3. Provide your IAM ARN from Step 2
4. Select the API sections/roles your app needs
5. After registration, you'll receive:
   - **LWA Client ID**
   - **LWA Client Secret**
   - **Application ID**

### Seller Public App — Website Authorization Workflow

#### 1. Initiate Authorization

Redirect the seller to the Amazon consent page. **The authorization URL is marketplace-specific** — each marketplace has its own Seller Central URL. This is different from the Advertising API, which uses only 3 regional URLs.

```
GET {SELLER_CENTRAL_URL}/apps/authorize/consent
  ?application_id=YOUR_APPLICATION_ID
  &state=YOUR_STATE_VALUE
  &redirect_uri=YOUR_REDIRECT_URI
```

Where `{SELLER_CENTRAL_URL}` is the marketplace-specific Seller Central base URL. For example:
- United States: `https://sellercentral.amazon.com`
- United Kingdom: `https://sellercentral-europe.amazon.com`
- Japan: `https://sellercentral.amazon.co.jp`

See the [Regional Endpoints Reference](#seller-central-authorization-consent-urls) for the complete list of marketplace-specific Seller Central URLs, or Amazon's official [Seller Central URLs](https://developer-docs.amazon.com/sp-api/docs/seller-central-urls) reference (which may be more current).

> **Important:** Unlike the Advertising API (which has 3 regional auth URLs), Seller Central has a different authorization URL per marketplace. In the EU region, the 5 core markets (UK, DE, FR, IT, ES) share `sellercentral-europe.amazon.com`, but other EU marketplaces (NL, SE, PL, BE, etc.) each have their own URL.

> For testing, add `&version=beta` to the URL.

#### 2. Handle the Redirect

Amazon redirects back to your `redirect_uri` with:

| Parameter | Description |
|-----------|-------------|
| `state` | Must match your original value (CSRF + application state) |
| `spapi_oauth_code` | Authorization code (valid **5 minutes**) |
| `selling_partner_id` | The authorizing seller's merchant ID |
| `mws_auth_token` | (Optional) For hybrid MWS/SP-API apps |

#### 3. Exchange Code for Tokens

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=SPAPI_OAUTH_CODE
&redirect_uri=YOUR_REDIRECT_URI
&client_id=YOUR_LWA_CLIENT_ID
&client_secret=YOUR_LWA_CLIENT_SECRET
```

**Response:**
```json
{
  "access_token": "Atza|...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "Atzr|..."
}
```

#### 4. Store the Refresh Token

- Refresh tokens are long-lived but **expire after 365 days**
- Amazon sends a reminder email 30 days before expiration
- The seller must re-authorize your app to get a new refresh token

### Seller Private App — Self-Authorization

Private apps are independently registered applications — the registration process is the same as for public apps (Step 3 above), but you select "Private" as the app type. Each private app receives its own set of credentials.

A single organization may operate many private apps across different seller accounts and regions. Each private app has its own LWA Client ID, Client Secret, and refresh token. At agency scale, this can mean dozens or hundreds of distinct credential sets.

1. In Seller Central, go to **Partner Network > Develop Apps**
2. Register your private app (if not already done) and collect its credentials:
   - **Application ID** (format: `amzn1.sp.solution.xxxxxxxxxxxxx`)
   - **LWA Client ID** (format: `amzn1.sp.solution.xxxxx`)
   - **LWA Client Secret** (format: `amzn1.oa2-cs.v1.xxxxx`)
3. On the **Manage Authorizations** page, click **Authorize app**
4. An LWA refresh token is generated immediately (format: `Atzr|...`)
5. If you sell in multiple regions, generate separate refresh tokens for each marketplace
6. Use these refresh tokens to obtain access tokens at runtime

> **Security:** Never share your Client Secret or Refresh Token publicly, commit them to version control, or include them in client-side code. LWA Client Secrets have rotation deadlines — rotate them before the displayed expiry date to prevent authentication failures.

> **Implementation note:** Unlike public apps (where your application owns a single set of credentials), private app credentials are **per-account and per-marketplace**. Applications must collect the Client ID, Client Secret, and Refresh Token from the user at runtime — not store them as static environment variables or application configuration.

See: [Creating Your Private SP-API App](https://docs.openbridge.com/en/articles/13169824-creating-your-private-sp-api-app) for a step-by-step walkthrough with screenshots.

Exchange the private app's refresh token for an access token:

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=PRIVATE_APP_REFRESH_TOKEN
&client_id=PRIVATE_APP_LWA_CLIENT_ID
&client_secret=PRIVATE_APP_LWA_CLIENT_SECRET
```

> Use the private app's own LWA Client ID and Client Secret here — not the public app's credentials.

### Seller Token Refresh

Access tokens expire after **1 hour**. Exchange refresh token for new access token:

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=YOUR_REFRESH_TOKEN
&client_id=YOUR_LWA_CLIENT_ID
&client_secret=YOUR_LWA_CLIENT_SECRET
```

### Seller Making API Requests

SP-API requests require **both** LWA access tokens and AWS Signature Version 4 signing.

#### Required Headers

| Header | Value |
|--------|-------|
| `x-amz-access-token` | LWA access token |
| `Authorization` | AWS Signature Version 4 |
| `x-amz-date` | Request timestamp |
| `host` | Regional SP-API endpoint |

#### Request Signing

1. Assume your IAM role using AWS STS `AssumeRole`
2. Use the temporary credentials to sign the request with SigV4
3. Include the LWA access token in `x-amz-access-token`

#### SP-API Endpoints by Region

| Region | Endpoint | Marketplaces |
|--------|----------|-------------|
| North America | `https://sellingpartnerapi-na.amazon.com` | US, CA, MX, BR |
| Europe | `https://sellingpartnerapi-eu.amazon.com` | UK, DE, FR, IT, ES, NL, SE, PL, BE, EG, TR, SA, AE, IN |
| Far East | `https://sellingpartnerapi-fe.amazon.com` | JP, AU, SG |

#### Token Endpoint by Region

| Region | Token Endpoint |
|--------|---------------|
| North America | `https://api.amazon.com/auth/o2/token` |
| Europe | `https://api.amazon.co.uk/auth/o2/token` |
| Far East | `https://api.amazon.co.jp/auth/o2/token` |

### Seller Key API Sections

| API | Purpose |
|-----|---------|
| Orders API | Retrieve and manage orders |
| Catalog Items API | Search and retrieve product catalog data |
| Reports API | Request and download reports |
| Feeds API | Submit data feeds (inventory, pricing) |
| Fulfillment Inbound API | Create FBA shipments |
| Fulfillment Outbound API | Multi-channel fulfillment |
| Notifications API | Subscribe to event notifications |
| Product Pricing API | Get competitive pricing data |
| Listings Items API | Manage product listings |

---

## 4. Vendor Central (Selling Partner API)

Vendor Central uses the same Selling Partner API (SP-API) as Seller Central, authenticated via OAuth 2.0 with Login with Amazon (LWA). Vendors are first-party suppliers who sell directly to Amazon (as opposed to sellers who sell on Amazon's marketplace).

The SP-API replaced the legacy EDI (Electronic Data Interchange) interface for vendor integrations, though both may operate simultaneously during transition.

### Vendor Prerequisites

- An active Amazon Vendor Central account
- An AWS account with IAM user and IAM role configured
- Access to the [Vendor Central Developer Console](https://vendorcentral.amazon.com/sellingpartner/developerconsole)

### Vendor Application Types

| Type | Use Case | Authorization | Credentials | Credential Cardinality |
|------|----------|---------------|-------------|----------------------|
| **Public** | Third-party apps serving multiple vendors | OAuth consent flow | Own LWA Client ID, Client Secret, Application ID | **One set per registered app** — your app owns these credentials |
| **Private** | Your own vendor account(s) only | Self-authorization in Vendor Central | Own LWA Client ID, Client Secret (separate from public) | **One set per authorized account/marketplace** — a single organization may have dozens |

> **Critical for implementation:** Public and private apps are **separate registered applications** in Amazon, each with their own LWA Client ID and Client Secret. If your application supports both public and private flows, you must store and use separate credentials for each. Do not share a single `client_id` / `client_secret` across both app types.

### Vendor Onboarding Steps

#### Step 1: Create an AWS IAM User and Role

1. Create an IAM user with **programmatic access**
2. Create an IAM role with the **Selling Partner API** trust policy
3. Attach an IAM policy granting SP-API access
4. Save the **Access Key**, **Secret Key**, and **Role ARN**

#### Step 2: Register via Vendor Central

1. Sign in to [Vendor Central](https://vendorcentral.amazon.com)
2. Go to **Integration > API Integration**
3. Submit an **"API Integration"** case with:
   - Application name
   - AWS user ARN
   - Selected API dimension/scope
4. After approval, access the Developer Console at:
   `vendorcentral.amazon.com/sellingpartner/developerconsole`
5. Retrieve your:
   - **LWA Client ID**
   - **LWA Client Secret**
   - **Application ID**

> **Key difference from Seller Central:** In Seller Central, you register apps via **Partner Network > Develop Apps**. In Vendor Central, it's **Integration > API Integration**.

### Vendor Public App — Website Authorization Workflow

#### 1. Initiate Authorization

Redirect the vendor to the Amazon consent page. **The authorization URL is marketplace-specific** — every marketplace has its own Vendor Central URL. This is different from both the Advertising API (which uses 3 regional URLs) and Seller Central (where 5 EU markets share one URL).

```
GET {VENDOR_CENTRAL_URL}/apps/authorize/consent
  ?application_id=YOUR_APPLICATION_ID
  &state=YOUR_STATE_VALUE
  &redirect_uri=YOUR_REDIRECT_URI
```

Where `{VENDOR_CENTRAL_URL}` is the marketplace-specific Vendor Central base URL. For example:
- United States: `https://vendorcentral.amazon.com`
- United Kingdom: `https://vendorcentral.amazon.co.uk`
- Germany: `https://vendorcentral.amazon.de`
- Japan: `https://vendorcentral.amazon.co.jp`

See the [Regional Endpoints Reference](#vendor-central-authorization-consent-urls) for the complete list of marketplace-specific Vendor Central URLs, or Amazon's official [Vendor Central URLs](https://developer-docs.amazon.com/sp-api/docs/vendor-central-urls) reference (which may be more current).

> **Important:** Unlike Seller Central (where 5 core EU markets share `sellercentral-europe.amazon.com`), Vendor Central has a **unique URL for every marketplace** — `vendorcentral.amazon.de` for Germany, `vendorcentral.amazon.fr` for France, etc.

#### 2. Handle the Redirect

Amazon redirects back with:

| Parameter | Description |
|-----------|-------------|
| `state` | Must match your original value (CSRF + application state) |
| `spapi_oauth_code` | Authorization code (valid **5 minutes**) |
| `selling_partner_id` | The authorizing vendor's ID |

#### 3. Exchange Code for Tokens

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=SPAPI_OAUTH_CODE
&redirect_uri=YOUR_REDIRECT_URI
&client_id=YOUR_LWA_CLIENT_ID
&client_secret=YOUR_LWA_CLIENT_SECRET
```

**Response:**
```json
{
  "access_token": "Atza|...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "Atzr|..."
}
```

### Vendor Private App — Self-Authorization

Private apps are independently registered applications — the registration process is the same as for public apps (Step 2 above), but you select "Private" as the app type. The interface differs slightly from Seller Central, but the process is equivalent. Each private app receives its own set of credentials.

A single organization may operate many private apps across different vendor accounts and regions. Each private app has its own LWA Client ID, Client Secret, and refresh token. At agency scale, this can mean dozens or hundreds of distinct credential sets.

1. In Vendor Central, go to **Integration > API Integration**
2. Register your private app (if not already done) and collect its credentials:
   - **Application ID** (format: `amzn1.sp.solution.xxxxxxxxxxxxx`)
   - **LWA Client ID** (format: `amzn1.sp.solution.xxxxx`)
   - **LWA Client Secret** (format: `amzn1.oa2-cs.v1.xxxxx`)
3. On the **Manage Authorizations** page, click **Authorize app**
4. An LWA refresh token is generated for each authorized Vendor Central account (format: `Atzr|...`)
5. If you operate in multiple regions, generate separate refresh tokens for each marketplace
6. Use these refresh tokens to obtain access tokens at runtime

> **Security:** Never share your Client Secret or Refresh Token publicly, commit them to version control, or include them in client-side code. LWA Client Secrets have rotation deadlines — rotate them before the displayed expiry date to prevent authentication failures.

> **Implementation note:** Unlike public apps (where your application owns a single set of credentials), private app credentials are **per-account and per-marketplace**. Applications must collect the Client ID, Client Secret, and Refresh Token from the user at runtime — not store them as static environment variables or application configuration.

See: [Creating Your Private SP-API App](https://docs.openbridge.com/en/articles/13169824-creating-your-private-sp-api-app) for a step-by-step walkthrough with screenshots.

Exchange the private app's refresh token for an access token:

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=PRIVATE_APP_REFRESH_TOKEN
&client_id=PRIVATE_APP_LWA_CLIENT_ID
&client_secret=PRIVATE_APP_LWA_CLIENT_SECRET
```

> Use the private app's own LWA Client ID and Client Secret here — not the public app's credentials.

### Multi-Account Authorization

For a single SP-API application accessing multiple Vendor Central accounts:

1. Register your application once
2. For each Vendor Central account, navigate to **Manage Authorizations**
3. Click **Authorize app** for each account
4. Each account generates its own LWA refresh token
5. Store and manage refresh tokens per account

See: [Tutorial: Authorize Multiple Vendor Central Accounts](https://developer-docs.amazon.com/sp-api/docs/tutorial-use-a-single-sp-api-application-to-authorize-multiple-vendor-central-accounts)

### Vendor Token Refresh

Access tokens expire after **1 hour**:

```
POST https://api.amazon.com/auth/o2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=YOUR_REFRESH_TOKEN
&client_id=YOUR_LWA_CLIENT_ID
&client_secret=YOUR_LWA_CLIENT_SECRET
```

### Vendor Making API Requests

Identical to Seller Central — requires both LWA access tokens and AWS Signature Version 4 signing.

#### Required Headers

| Header | Value |
|--------|-------|
| `x-amz-access-token` | LWA access token |
| `Authorization` | AWS Signature Version 4 |
| `x-amz-date` | Request timestamp |
| `host` | Regional SP-API endpoint |

### Vendor-Specific API Sections

| API | Endpoint Pattern | Purpose |
|-----|-----------------|---------|
| Vendor Orders API | `/vendor/orders/v1/purchaseOrders` | Retrieve and confirm purchase orders |
| Vendor Shipments API | `/vendor/shipping/v1/shipmentConfirmations` | Create shipping pre-announcements (ASN) |
| Vendor Payments API | `/vendor/payments/v1/invoices` | Submit invoices and credit notes |
| Vendor Transaction Status API | `/vendor/transactions/v1/transactions` | Verify API transaction status |
| Vendor Direct Fulfillment Orders | `/vendor/directFulfillment/orders/v1/` | Direct fulfillment order management |
| Vendor Direct Fulfillment Shipping | `/vendor/directFulfillment/shipping/v1/` | Direct fulfillment shipping labels |
| Vendor Direct Fulfillment Payments | `/vendor/directFulfillment/payments/v1/` | Direct fulfillment invoices |

### Key Differences from Seller Central

| Aspect | Seller Central | Vendor Central |
|--------|---------------|----------------|
| Navigation | Partner Network > Develop Apps | Integration > API Integration |
| Consent URL | `sellercentral.amazon.com/apps/authorize/consent` | `vendorcentral.amazon.com/apps/authorize/consent` |
| EU auth URLs | 5 core markets share `sellercentral-europe.amazon.com`; others have own URLs | Every marketplace has its own unique URL |
| Developer Console | Via Seller Central | `vendorcentral.amazon.com/sellingpartner/developerconsole` |
| API sections | Orders, Catalog, FBA, Listings, etc. | Vendor Orders, Shipments, Payments, Direct Fulfillment |
| Public app credentials | One set per registered app (app-level config) | One set per registered app (app-level config) |
| Private app credentials | One set per authorized account/marketplace (user-provided at runtime) | One set per authorized account/marketplace (user-provided at runtime) |
| OAuth/LWA flow | Identical | Identical |
| IAM requirements | Identical | Identical |
| Token management | Identical | Identical |

---

## 5. Regional Endpoints Reference

Amazon services are organized into three regions: **North America (NA)**, **Europe (EU)**, and **Far East (FE)**. Each region has its own authorization URLs, token endpoints, and API base URLs. Seller Central, Vendor Central, and the Advertising API each have distinct regional URL structures.

Authorizations are **regional** — authorizing in one marketplace grants access to all marketplaces within that region.

### Advertising API Endpoints

#### Authorization URLs (LWA)

| Region | Authorization URL |
|--------|------------------|
| North America | `https://www.amazon.com/ap/oa` |
| Europe | `https://eu.account.amazon.com/ap/oa` |
| Far East | `https://apac.account.amazon.com/ap/oa` |

#### Token Endpoints

| Region | Token URL |
|--------|----------|
| North America | `https://api.amazon.com/auth/o2/token` |
| Europe | `https://api.amazon.co.uk/auth/o2/token` |
| Far East | `https://api.amazon.co.jp/auth/o2/token` |

#### API Base URLs

| Region | API Endpoint |
|--------|-------------|
| North America | `https://advertising-api.amazon.com` |
| Europe | `https://advertising-api-eu.amazon.com` |
| Far East | `https://advertising-api-fe.amazon.com` |

> **Note:** An authorization code retrieved from any regional LWA URL can be used to access the Advertising API in any region. The API base URL determines which region's data you access.

### Seller Central Authorization Consent URLs

Construct by appending `/apps/authorize/consent?application_id={your_app_id}` to the Seller Central URL for the target marketplace.

> **Amazon reference:** [Seller Central URLs](https://developer-docs.amazon.com/sp-api/docs/seller-central-urls) — check this for the latest marketplace URLs as Amazon may add or change them.

#### North America

| Marketplace | Seller Central URL |
|-------------|-------------------|
| Canada | `https://sellercentral.amazon.ca` |
| United States | `https://sellercentral.amazon.com` |
| Mexico | `https://sellercentral.amazon.com.mx` |
| Brazil | `https://sellercentral.amazon.com.br` |

#### Europe

| Marketplace | Seller Central URL |
|-------------|-------------------|
| Spain | `https://sellercentral-europe.amazon.com` |
| United Kingdom | `https://sellercentral-europe.amazon.com` |
| France | `https://sellercentral-europe.amazon.com` |
| Germany | `https://sellercentral-europe.amazon.com` |
| Italy | `https://sellercentral-europe.amazon.com` |
| Netherlands | `https://sellercentral.amazon.nl` |
| Sweden | `https://sellercentral.amazon.se` |
| Poland | `https://sellercentral.amazon.pl` |
| Belgium | `https://sellercentral.amazon.com.be` |
| Egypt | `https://sellercentral.amazon.eg` |
| Turkey | `https://sellercentral.amazon.com.tr` |
| Saudi Arabia | `https://sellercentral.amazon.sa` |
| U.A.E. | `https://sellercentral.amazon.ae` |
| India | `https://sellercentral.amazon.in` |

#### Far East

| Marketplace | Seller Central URL |
|-------------|-------------------|
| Singapore | `https://sellercentral.amazon.sg` |
| Australia | `https://sellercentral.amazon.com.au` |
| Japan | `https://sellercentral.amazon.co.jp` |

### Vendor Central Authorization Consent URLs

Construct by appending `/apps/authorize/consent?application_id={your_app_id}` to the Vendor Central URL for the target marketplace.

> **Amazon reference:** [Vendor Central URLs](https://developer-docs.amazon.com/sp-api/docs/vendor-central-urls) — check this for the latest marketplace URLs as Amazon may add or change them.

#### North America

| Marketplace | Vendor Central URL |
|-------------|-------------------|
| Canada | `https://vendorcentral.amazon.ca` |
| United States | `https://vendorcentral.amazon.com` |
| Mexico | `https://vendorcentral.amazon.com.mx` |
| Brazil | `https://vendorcentral.amazon.com.br` |

#### Europe

| Marketplace | Vendor Central URL |
|-------------|-------------------|
| Spain | `https://vendorcentral.amazon.es` |
| United Kingdom | `https://vendorcentral.amazon.co.uk` |
| France | `https://vendorcentral.amazon.fr` |
| Germany | `https://vendorcentral.amazon.de` |
| Italy | `https://vendorcentral.amazon.it` |
| Netherlands | `https://vendorcentral.amazon.nl` |
| Sweden | `https://vendorcentral.amazon.se` |
| Poland | `https://vendorcentral.amazon.pl` |
| Belgium | `https://vendorcentral.amazon.com.be` |
| Egypt | `https://vendorcentral.amazon.me` |
| Turkey | `https://vendorcentral.amazon.com.tr` |
| U.A.E. | `https://vendorcentral.amazon.me` |
| India | `https://vendorcentral.amazon.in` |

#### Far East

| Marketplace | Vendor Central URL |
|-------------|-------------------|
| Singapore | `https://vendorcentral.amazon.com.sg` |
| Australia | `https://vendorcentral.amazon.com.au` |
| Japan | `https://vendorcentral.amazon.co.jp` |

### SP-API Endpoints

Shared by both Seller Central and Vendor Central:

| Region | SP-API Endpoint | AWS Region |
|--------|----------------|------------|
| North America | `https://sellingpartnerapi-na.amazon.com` | us-east-1 |
| Europe | `https://sellingpartnerapi-eu.amazon.com` | eu-west-1 |
| Far East | `https://sellingpartnerapi-fe.amazon.com` | us-west-2 |

### Shared Token Endpoints

Token endpoints are the same across all three services per region:

| Region | Token URL |
|--------|----------|
| North America | `https://api.amazon.com/auth/o2/token` |
| Europe | `https://api.amazon.co.uk/auth/o2/token` |
| Far East | `https://api.amazon.co.jp/auth/o2/token` |

### Marketplace IDs

| Country | Marketplace ID | Code | Region |
|---------|---------------|------|--------|
| Canada | A2EUQ1WTGCTBG2 | CA | NA |
| United States | ATVPDKIKX0DER | US | NA |
| Mexico | A1AM78C64UM0Y8 | MX | NA |
| Brazil | A2Q3Y263D00KWC | BR | NA |
| Spain | A1RKKUPIHCS9HS | ES | EU |
| United Kingdom | A1F83G8C2ARO7P | UK | EU |
| France | A13V1IB3VIYZZH | FR | EU |
| Netherlands | A1805IZSGTT6HS | NL | EU |
| Germany | A1PA6795UKMFR9 | DE | EU |
| Italy | APJ6JRA9NG5V4 | IT | EU |
| Sweden | A2NODRKZP88ZB9 | SE | EU |
| Poland | A1C3SOZRARQ6R3 | PL | EU |
| Belgium | AMEN7PMS3EDWL | BE | EU |
| Egypt | ARBP9OOSHTCHU | EG | EU |
| Turkey | A33AVAJ2PDY3EV | TR | EU |
| Saudi Arabia | A17E79C6D8DWNP | SA | EU |
| U.A.E. | A2VIGQ35RCS4UG | AE | EU |
| India | A21TJRUUN4KGV | IN | EU |
| Singapore | A19VAU5U5O7RUS | SG | FE |
| Australia | A39IBJ37TRP1C6 | AU | FE |
| Japan | A1VC38T7YXB528 | JP | FE |

### Key Differences Between Services

| Aspect | Advertising API | Seller Central | Vendor Central |
|--------|----------------|----------------|----------------|
| Auth URL pattern | Regional LWA (`amazon.com/ap/oa`, `eu.account.amazon.com/ap/oa`) | Marketplace-specific Seller Central URL + `/apps/authorize/consent` | Marketplace-specific Vendor Central URL + `/apps/authorize/consent` |
| EU auth URL | Single URL for all EU | `sellercentral-europe.amazon.com` for 5 core markets; separate URLs for others | Separate URL per marketplace |
| API endpoint | `advertising-api.amazon.com` / `-eu` / `-fe` | `sellingpartnerapi-na/eu/fe.amazon.com` | Same as Seller Central |
| Token endpoint | Same across all three services per region | Same | Same |
| Request signing | Bearer token + Client ID header | AWS SigV4 + LWA token | AWS SigV4 + LWA token |

---

## 6. The OAuth `state` Parameter

The `state` parameter in OAuth 2.0 is commonly described as "a random value for CSRF protection." While CSRF prevention is one function, this undersells its purpose. The `state` parameter is a **state management mechanism** — it preserves application context across the redirect round-trip to Amazon and back to your application.

When a user leaves your application to authorize on Amazon (Seller Central, Vendor Central, or the Ads console), your application loses context. The `state` parameter is how you recover that context when the user returns.

### Dual Purpose

#### 1. Application State Preservation

When Amazon redirects the user back to your application, you need to know:

- **Where were they?** Which page or workflow initiated the auth request
- **Who are they?** Which internal user/account triggered the flow
- **What were they doing?** Which action to resume after authorization completes
- **Which tenant?** In multi-tenant systems, which customer account to associate the tokens with

The `state` parameter carries this context through the redirect.

#### 2. CSRF Protection

A secondary (but critical) function: because `state` is set by your app before the redirect and validated on return, an attacker cannot forge a callback URL that your application will accept. Without state validation, an attacker could trick a user into linking their account to the attacker's Amazon credentials.

### What `state` Is NOT

- It is **not** just a random number
- It is **not** only for security
- It is **not** optional in production systems (even though the OAuth spec says "recommended")
- It is **not** something Amazon processes or interprets — it's opaque to Amazon and returned unchanged

### Implementation Patterns

#### Pattern 1: Opaque Key → Server-Side Session Store

Store context in your session/database, reference it with a key in `state`.

```
# Before redirect
session_data = {
    "user_id": 42,
    "return_url": "/settings/integrations",
    "tenant_id": "acme-corp",
    "marketplace": "US",
    "timestamp": 1716700000
}
state_key = generate_secure_random()  # e.g., "a7f3b9c2e1d4"
store_in_session(state_key, session_data)

# Redirect to Amazon with state=a7f3b9c2e1d4
```

```
# On callback
state_key = request.params["state"]
session_data = retrieve_from_session(state_key)

if not session_data:
    reject()  # CSRF or expired

if expired(session_data["timestamp"], max_age=1800):
    reject()  # Stale request

# Resume: we know user 42 from tenant acme-corp
# wants US marketplace, redirect them back to /settings/integrations
```

**Best for:** Most applications. Keeps sensitive data server-side.

#### Pattern 2: Encrypted/Signed Payload

Encode context directly in `state` (encrypted + base64).

```
payload = {
    "uid": 42,
    "tid": "acme-corp",
    "ret": "/settings/integrations",
    "ts": 1716700000,
    "nonce": "x9k2m"
}
state = base64url_encode(encrypt(json(payload), SECRET_KEY))
```

On callback, decrypt and validate. No session store needed.

**Best for:** Stateless architectures, serverless functions, distributed systems without shared session stores.

#### Pattern 3: Composite (Nonce + Context Key)

```
state = f"{csrf_nonce}:{context_identifier}"
# e.g., "a7f3b9c2e1d4:onboard-us-marketplace"
```

Split on callback: validate nonce for CSRF, use context identifier for routing.

**Best for:** Simple apps with few authorization flows.

### Real-World Use Cases

#### Multi-Tenant SaaS

Your app manages Amazon integrations for multiple customers. When Customer A clicks "Connect Amazon," you must ensure the resulting tokens get stored against Customer A's account — not whoever happens to be logged in when the callback fires.

```python
state_data = {
    "tenant_id": "customer-a",
    "connection_type": "seller_central",
    "initiated_by": "user@customer-a.com"
}
```

#### Multi-Marketplace Onboarding

A seller connecting US, UK, and DE marketplaces in sequence. State tracks which marketplace this particular redirect is for:

```python
state_data = {
    "marketplace": "UK",
    "onboarding_step": 2,
    "remaining": ["DE"]
}
```

#### Deep-Link Return

User was on `/campaigns/sp/123/keywords` when their token expired and re-auth was triggered. State preserves the return destination:

```python
state_data = {
    "return_to": "/campaigns/sp/123/keywords",
    "action": "token_refresh"
}
```

#### Vendor Central Multi-Account

Authorizing a single SP-API app across 5 Vendor Central accounts. State identifies which account this callback corresponds to:

```python
state_data = {
    "vendor_account": "VC-EU-WIDGET-CO",
    "account_index": 3,
    "total_accounts": 5
}
```

### Security Requirements

| Requirement | Why |
|-------------|-----|
| Include a cryptographic nonce | Prevents CSRF — attacker can't guess valid state |
| Validate on every callback | Reject requests with missing/mismatched state |
| Use timing-safe comparison | Prevents timing attacks on state validation |
| Set expiration (recommended: 30 min) | Prevents replay of old authorization flows |
| Single-use: delete after validation | Prevents replay attacks |
| Don't put secrets in state directly | State travels through browser URL bar — use encryption or opaque keys |
| Encrypt if embedding data | If state carries payload, encrypt before base64 encoding |

### Amazon-Specific Notes

#### Login with Amazon Behavior

Amazon preserves `state` exactly as provided — no modification, no interpretation. The parameter is returned as-is in the redirect back to your application.

#### SP-API (Seller Central / Vendor Central)

The `state` parameter is included in the redirect to:
- `sellercentral.amazon.com/apps/authorize/consent`
- `vendorcentral.amazon.com/apps/authorize/consent`

And returned in the callback alongside `spapi_oauth_code` and `selling_partner_id`.

#### Amazon Advertising API

Same behavior — `state` travels through the standard LWA authorization code grant flow via `amazon.com/ap/oa` and is returned with the authorization `code`.

### Common Mistakes

| Mistake | Consequence |
|---------|------------|
| Using a static value | No CSRF protection, no state management |
| Not validating state on callback | Vulnerable to CSRF attacks |
| Storing sensitive data unencrypted in state | Data visible in browser history, server logs, referrer headers |
| No expiration check | Stale auth flows can be replayed |
| Reusing state values | Replay attack vector |
| Treating state as "just random" | Missing the state management purpose entirely |

### State Parameter Summary

`state` is your application's memory across the OAuth redirect. It answers: "What was I doing before I sent this user to Amazon?" Use it to:

1. **Route** — direct the callback to the right handler/tenant/marketplace
2. **Resume** — put the user back where they were
3. **Protect** — reject forged callbacks via CSRF nonce
4. **Correlate** — tie the resulting tokens to the correct internal entity

---

## 7. Button Guidelines

Amazon provides official button assets for Login with Amazon (LWA) integrations. Applications must use these official buttons when initiating the LWA authorization flow.

### Button Images

Amazon hosts button assets on their CDN. Load directly from Amazon's servers rather than hosting your own copy.

#### CDN Base URL

```
https://images-na.ssl-images-amazon.com/images/G/01/lwa/
```

#### Available Styles

| Style | Use Case |
|-------|----------|
| **Gold** | Primary, recommended for most integrations |
| **Dark Grey** | High-contrast alternative |
| **Light Grey** | Subtle, lower-contrast option |

#### Desktop Sizes

| Size | Dimensions | 2x Retina |
|------|-----------|-----------|
| Small (icon) | 32x32 | 64x64 |
| Medium | 76x32 | 152x64 |
| Large | 156x32 | 312x64 |

#### Touch/Mobile Sizes

| Size | Dimensions | 2x Retina |
|------|-----------|-----------|
| Small (icon) | 46x46 | 92x92 |
| Medium | 101x46 | 202x92 |
| Large | 195x46 | 390x92 |

### Image URLs

#### Gold Buttons (Desktop)

| Size | URL |
|------|-----|
| Large | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_156x32.png` |
| Large 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_312x64.png` |
| Medium | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_76x32.png` |
| Medium 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_152x64.png` |

#### Dark Grey Buttons (Desktop)

| Size | URL |
|------|-----|
| Large | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_drkgry_156x32.png` |
| Large 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_drkgry_312x64.png` |
| Medium | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_drkgry_76x32.png` |
| Medium 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_drkgry_152x64.png` |

#### Light Grey Buttons (Desktop)

| Size | URL |
|------|-----|
| Large | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_ltgry_156x32.png` |
| Large 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_ltgry_312x64.png` |
| Medium | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_ltgry_76x32.png` |
| Medium 2x | `https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_ltgry_152x64.png` |

#### Pressed States

Append `_pressed` before the file extension for pressed/active states:

```
btnLWA_gold_312x64.png       → standard
btnLWA_gold_312x64_pressed.png → pressed
```

### Button Implementation

Use the 2x image with explicit `width` and `height` for retina display support:

```html
<button class="lwa-btn" onclick="startAuth()">
  <img src="https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_312x64.png"
       alt="Login with Amazon"
       width="156"
       height="32">
</button>
```

```css
.lwa-btn {
  display: inline-block;
  padding: 0;
  border: none;
  background: none;
  cursor: pointer;
}

.lwa-btn img {
  display: block;
}
```

### Multilingual Buttons

Button images are available in additional languages:

- Chinese
- French
- German
- Italian
- Japanese
- Portuguese
- Spanish

### Platform-Specific Assets

- **iOS**: Available in 32dp and 44dp sizes
- **Android**: Multiple density variants (hdpi, mdpi, tvdpi, xhdpi, xxhdpi)

Download packages:
- Android: `LWA_for_Android.zip`
- iOS: `LWA_for_iOS.zip`

---

## 8. Security Best Practices

- Validate `state` parameter matches your session value on every callback
- Set state token expiry (~30 minutes recommended)
- Exchange authorization codes within 5 minutes
- Never expose `client_secret` in client-side code
- Store refresh tokens encrypted at rest
- Use HTTPS exclusively
- Implement CSRF protection with `state` parameter
- Regularly rotate client secrets
- Refresh tokens expire after 365 days; plan for re-authorization
- Use timing-safe comparison for state validation
- Delete state tokens after single use to prevent replay

---

## 9. Sources

### Amazon Advertising API
- [Amazon Ads API authorization overview](https://advertising.amazon.com/API/docs/en-us/guides/account-management/authorization/overview)
- [Step 1: Create a Login with Amazon application](https://advertising.amazon.com/API/docs/en-us/guides/onboarding/create-lwa-app)
- [Step 2: Apply for Amazon Ads API access](https://advertising.amazon.com/API/docs/en-us/guides/onboarding/apply-for-access)
- [Assign API access to a Login with Amazon application](https://advertising.amazon.com/API/docs/en-us/guides/onboarding/assign-api-access)
- [Access Tokens](https://advertising.amazon.com/API/docs/en-us/guides/account-management/authorization/access-tokens)
- [Amazon Ads API Detailed Guide (Megaficus)](https://megaficus.com/en/blog/amazon-ads-api/)
- [Amazon Advertising API Request Format](https://ncoughlin.com/posts/amazon-advertising-api-request-format)

### Seller Central (SP-API)
- [Authorizing Selling Partner API Applications](https://developer-docs.amazon.com/sp-api/docs/authorizing-selling-partner-api-applications)
- [Self-Authorization for Private Apps](https://developer-docs.amazon.com/sp-api/docs/self-authorization)
- [Authorize Public Applications](https://developer-docs.amazon.com/sp-api/docs/authorize-public-applications)
- [Set up the Authorization Workflow](https://developer-docs.amazon.com/sp-api/docs/onboarding-step-6-set-up-the-authorization-workflow)
- [SP-API OAuth Flow (Jesse Evers)](https://www.jesseevers.com/spapi-oauth/)
- [SP-API Auth Demystified (Medium)](https://marco-tibaldeschi.medium.com/amazon-sp-api-auth-auth-demystified-ab3bc746729b)

### Vendor Central (SP-API)
- [Tutorial: Authorize Multiple Vendor Central Accounts](https://developer-docs.amazon.com/sp-api/docs/tutorial-use-a-single-sp-api-application-to-authorize-multiple-vendor-central-accounts)
- [How to Build a Vendor Central API Integration (Rollout)](https://rollout.com/integration-guides/amazon-vendor-central/how-to-build-a-public-amazon-vendor-central-integration-building-the-auth-flow)
- [Amazon Vendor API Guide (Amalytix)](https://www.amalytix.com/en/blog/amazon-vendor-api/)
- [Set up OAuth 2.0 for Vendor Central (Celigo)](https://docs.celigo.com/hc/en-us/articles/6202235192603-Set-up-an-OAuth-2-0-HTTP-connection-to-Amazon-Vendor-Central)

### Regional Endpoints
- [Seller Central URLs](https://developer-docs.amazon.com/sp-api/docs/seller-central-urls)
- [Vendor Central URLs](https://developer-docs.amazon.com/sp-api/docs/vendor-central-urls)
- [SP-API Endpoints](https://spapi.cyou/en/use-other/sp-api-endpoints.html)
- [Amazon Ads API Authorization (Nexla)](https://docs.nexla.com/user-guides/connectors/amzads_api/amzads_api_auth)
- [Openbridge SP-API Marketplaces](https://docs.openbridge.com/en/articles/3287682-amazon-seller-central-supported-selling-partner-api-marketplaces)
- [Marketplace IDs](https://spapi.cyou/en/use-other/marketplace-ids.html)

### OAuth & State Parameter
- [LWA Authorization Code Grant — Amazon Developer Docs](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html)
- [Auth0: Prevent Attacks and Redirect Users with State Parameters](https://auth0.com/docs/secure/attack-protection/state-parameters)
- [OAuth State Beyond CSRF (Medium)](https://ritou.medium.com/how-to-use-oauth-2-0-state-parameter-other-than-csrf-protection-ff64f91ebc8b)
- [OneUpTime: How to Handle OAuth2 State Parameter](https://oneuptime.com/blog/post/2026-01-24-oauth2-state-parameter/view)
- [SP-API Authorization Workflow](https://developer-docs.amazon.com/sp-api/docs/authorizing-selling-partner-api-applications)

### Button Guidelines
- [Login with Amazon Button Guidelines](https://developer.amazon.com/docs/login-with-amazon/button.html)
