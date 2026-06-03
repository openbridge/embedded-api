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

## Tutorials

Step-by-step guides for common integration workflows. These walk through the API calls directly, with equivalent CLI commands at the end of each tutorial.

| Tutorial | Description |
|---|---|
| [Identity Configuration](./tutorials/identity-configuration.md) | Create and authorize remote identities through the OAuth flow |
| [Subscription Configuration](./tutorials/subscription-configuration.md) | Create, update, pause, and delete pipeline subscriptions |
| [Requesting Historical Data](./tutorials/history-backfill.md) | Backfill data for past date ranges, including batch processing via CSV |
| [Monitoring Pipeline Health](./tutorials/monitoring-healthchecks.md) | Detect errors, diagnose failures, and respond to invalid identities |
| [Amazon Order Product Jobs](./tutorials/amazon-order-product-jobs.md) | Create product jobs for specific Amazon order IDs with batching and staggered scheduling |

## Repository Resources

- Openbridge MCP for AI agents and chat clients: [openbridge/openbridge-mcp](https://github.com/openbridge/openbridge-mcp)
- CLI workflow: [embed-cli/README.md](./embed-cli/README.md)
- Product overview: [products/product-overview.md](./products/product-overview.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

## AI Agents and MCP

If you are integrating Openbridge with AI agents or chat clients that support MCP, use the Openbridge MCP server:

- Repository: [openbridge/openbridge-mcp](https://github.com/openbridge/openbridge-mcp)
- Intended use: connect Openbridge tools to MCP-capable clients such as ChatGPT, Claude, and other agent frameworks
- Deployment options: local Python runtime, Docker, or a remote hosted deployment

The MCP server is maintained in its own repository and includes setup instructions, environment variables, and client configuration examples.

## Support

If you have a documentation problem, an API question, or a reproducible issue:

- Open a GitHub issue in this repository
- Contact Openbridge through the official support channel

### Usage Notes

Openbridge APIs enforce rate limiting. For guidance on handling API rate limiting errors:

- [Rate Limiting](./api-usage-docs/rate-limiting.md)

Additional product and platform documentation:

- [Openbridge Documentation](https://docs.openbridge.com/)
- [Openbridge Website](https://www.openbridge.com)
- [Openbridge Blog](https://blog.openbridge.com)

## Contributing

Contributions are welcome. For significant changes, open an issue first so the approach and scope can be aligned before implementation.
