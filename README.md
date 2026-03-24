# Openbridge Embedded API

This repository is the main entry point for integrating with the Openbridge Embedded API. Use it to understand the integration model, authenticate API access, create subscriptions, inspect identities, and work with service-specific integration endpoints.

The root README is intentionally brief. Detailed request and response examples now live in [`api-usage-docs`](./api-usage-docs).

## What This API Does

Openbridge subscriptions connect three things:

1. A source product
2. A storage destination
3. A remote identity that authorizes Openbridge to access a third-party platform on your behalf

In practice, most integrations follow this sequence:

1. Create a refresh token in the Openbridge UI
2. Exchange that refresh token for a JWT access token
3. Look up your account, user, product, destination, and remote identity IDs
4. Create a subscription
5. Optionally trigger historical data retrieval

If you want the end-to-end sequence first, start with [Getting Started](./api-usage-docs/getting-started.md).

## Before You Begin

There are a few prerequisites that still matter at the repository level:

- API access must be enabled for your Openbridge account by the Openbridge team.
- The account owner must have the `api-user` role.
- Refresh tokens are created in the Openbridge UI under `Account -> API Management`.
- Refresh tokens are shown only once. Store them securely.
- Destinations are managed in the Openbridge UI, not through the API.
- Remote identities are typically created and authorized through the Openbridge UI and OAuth flow, then referenced by ID when creating subscriptions.

For the authentication flow, see [Authentication API](./api-usage-docs/authentication-api.md).

## Quick Start Path

Use these docs in order if you are building a new integration:

1. [Authentication API](./api-usage-docs/authentication-api.md)
   Create a refresh token in the UI and exchange it for a JWT access token.
2. [Getting Started](./api-usage-docs/getting-started.md)
   Follow the normal sequence for building a subscription-backed integration.
3. [Products API](./api-usage-docs/products-api.md)
   Find products and product payload definitions, including valid `stage_id` values.
4. [Remote Identity API](./api-usage-docs/remote-identity-api.md)
   Find the identities your account can use and inspect identity health.
5. [Subscriptions API](./api-usage-docs/subscriptions-api.md)
   Create, inspect, and update subscriptions.
6. [History API](./api-usage-docs/history-api.md)
   Request historical backfills after a subscription is active.

## API Documentation Index

### Core Docs

| Topic | Doc |
|---|---|
| Getting started | [api-usage-docs/getting-started.md](./api-usage-docs/getting-started.md) |
| Authentication | [api-usage-docs/authentication-api.md](./api-usage-docs/authentication-api.md) |
| Account and user lookup | [api-usage-docs/account-user-api.md](./api-usage-docs/account-user-api.md) |
| Products | [api-usage-docs/products-api.md](./api-usage-docs/products-api.md) |
| Remote identities | [api-usage-docs/remote-identity-api.md](./api-usage-docs/remote-identity-api.md) |
| Subscriptions | [api-usage-docs/subscriptions-api.md](./api-usage-docs/subscriptions-api.md) |
| History | [api-usage-docs/history-api.md](./api-usage-docs/history-api.md) |
| OAuth flow and app records | [api-usage-docs/oauth-api.md](./api-usage-docs/oauth-api.md) |
| State records | [api-usage-docs/state-api.md](./api-usage-docs/state-api.md) |
| Jobs | [api-usage-docs/jobs-api.md](./api-usage-docs/jobs-api.md) |
| Service API overview | [api-usage-docs/service-api.md](./api-usage-docs/service-api.md) |

### Service Integration Docs

Use these when you need provider-specific metadata to configure subscriptions:

| Integration | Doc |
|---|---|
| Amazon Advertising | [api-usage-docs/service-amazon-advertising-api.md](./api-usage-docs/service-amazon-advertising-api.md) |
| Amazon SP-API | [api-usage-docs/service-amazon-sp-api.md](./api-usage-docs/service-amazon-sp-api.md) |
| Google Ads, YouTube, Search Ads 360, Campaign Manager 360 | [api-usage-docs/service-google-api.md](./api-usage-docs/service-google-api.md) |
| Facebook | [api-usage-docs/service-facebook-api.md](./api-usage-docs/service-facebook-api.md) |
| Shopify | [api-usage-docs/service-shopify-api.md](./api-usage-docs/service-shopify-api.md) |
| Healthchecks | [api-usage-docs/service-healthchecks-api.md](./api-usage-docs/service-healthchecks-api.md) |

## Repository Resources

- CLI workflow: [embed-cli/README.md](./embed-cli/README.md)
- Tutorials: [tutorials/identity-configuration.md](./tutorials/identity-configuration.md), [tutorials/subscription-configuration.md](./tutorials/subscription-configuration.md)
- Product overview: [products/product-overview.md](./products/product-overview.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

## Support

If you have a documentation problem, an API question, or a reproducible issue:

- Open a GitHub issue in this repository
- Contact Openbridge through the official support channel

Additional product and platform documentation:

- [Openbridge Documentation](https://docs.openbridge.com/)
- [Openbridge Website](https://www.openbridge.com)
- [Openbridge Blog](https://blog.openbridge.com)

## Contributing

Contributions are welcome. For significant changes, open an issue first so the approach and scope can be aligned before implementation.
