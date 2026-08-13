# Openbridge Embedded API

Integrate with the Openbridge Embedded API to authenticate, create subscriptions, inspect identities, and work with service-specific integration endpoints.

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

If you want the end-to-end sequence first, start with [Getting Started](api-usage-docs/getting-started.md).

## Before You Begin

- API access must be enabled for your Openbridge account by the Openbridge team.
- The account owner must have the `api-user` role.
- Refresh tokens are created in the Openbridge UI under `Account -> API Management`.
- Refresh tokens are shown only once. Store them securely.
- Destinations are managed in the Openbridge UI, not through the API.
- Remote identities are typically created and authorized through the Openbridge UI and OAuth flow, then referenced by ID when creating subscriptions.

For the authentication flow, see [Authentication API](api-usage-docs/authentication-api.md).

## Quick Start Path

Use these docs in order if you are building a new integration:

1. [Authentication API](api-usage-docs/authentication-api.md) — create a refresh token in the UI and exchange it for a JWT access token.
2. [Getting Started](api-usage-docs/getting-started.md) — follow the normal sequence for building a subscription-backed integration.
3. [Products API](api-usage-docs/products-api.md) — find products and product payload definitions, including valid `stage_id` values.
4. [Remote Identity API](api-usage-docs/remote-identity-api.md) — find the identities your account can use and inspect identity health.
5. [Subscriptions API (v2)](api-usage-docs/subscriptions-api.md) — create, inspect, and update subscriptions.
6. [History API](api-usage-docs/history-api.md) — request historical backfills after a subscription is active.

## Support

If you have a documentation problem, an API question, or a reproducible issue:

- Open a GitHub issue in the [embedded-api repository](https://github.com/openbridge/embedded-api)
- Contact Openbridge through the official support channel

Additional product and platform documentation:

- [Openbridge Documentation](https://docs.openbridge.com/)
- [Openbridge Website](https://www.openbridge.com)
- [Openbridge Blog](https://blog.openbridge.com)
