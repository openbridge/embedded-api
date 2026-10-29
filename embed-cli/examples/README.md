# obcmd Examples

Task-shaped walkthroughs for the Openbridge CLI. Each file is a complete flow
in the order the API actually requires it, using real commands and real flags.

For the generated flag-by-flag reference, see
[Command Reference](../commands.md). For short snippets rather than full
flows, see [Recipes](../recipes.md).

---

## Getting set up

| Example | What it covers |
|---|---|
| [Authenticating and setting defaults](authenticating.md) | `auth login`, `auth status`, `auth token get`, `auth logout`, `account get`, `user get`, `config get`, `config update` |
| [Discovering commands and scripting obcmd](discovering-commands.md) | `describe --json`, `--help`, exit codes, `--dry-run`, `--fields`, `--filter`, `--all`, `--payload` |

## Catalog and lookups

| Example | What it covers |
|---|---|
| [Browsing the product catalog](browsing-the-catalog.md) | `product list`, `product get`, `product-card list`, `product-card get`, `product-payload list`, `identity-type list`, `identity-type get`, `rule list` |
| [Resolving platform IDs](resolving-platform-ids.md) | `amzadv-profile`, `amzadv-advertiser`, `amzadv-brand`, `amzadv-kdp`, `amzadv-attribution`, `amzadv-dsp-map`, `amzadv-dsp-metric`, `googleads-customer`, `googleads-managed-customer`, `gcm-profile`, `gcm-report`, `gsa-agency`, `youtube-channel`, `facebook-ad-account`, `facebook-page`, `shopify-shop-graphql`, `sp-marketplace`, `sp-asin`, `sp-credential`, `sp-seller-id` |

## Identities

| Example | What it covers |
|---|---|
| [Authorizing a third-party identity](authorizing-an-identity.md) | `identity-type list`, `oauth-app create\|list\|get\|update\|delete`, `state create\|get\|update\|delete`, `generic-state create` |
| [Inspecting identities](inspecting-identities.md) | `remote-identity list\|get`, `remote-identity-shared list`, `identity-meta list\|get` |

## Destinations

| Example | What it covers |
|---|---|
| [Provisioning a destination](provisioning-a-destination.md) | `destination create`, `destination get`, `storage list` |

## Pipelines

| Example | What it covers |
|---|---|
| [Creating a subscription](creating-a-subscription.md) | `subscription create`, with the full ID resolution chain |
| [Managing subscriptions](managing-subscriptions.md) | `subscription list\|get\|update\|cancel`, `subscription-parameter list\|get\|create`, pausing, renaming, repointing, retiring, exporting |

## Operations

| Example | What it covers |
|---|---|
| [Requesting historical data](history-backfill.md) | `history trigger\|get\|list\|cancel\|delete`, `history-limit get` |
| [Monitoring pipelines](monitoring-pipelines.md) | `job list\|get`, `transaction list`, `healthcheck list` |
| [SP-API notification subscriptions](sp-api-notifications.md) | `sp-notification-type list`, `sp-notification create\|update\|delete` |

---

## What is not in the CLI

The CLI covers the data plane. Account administration is console-only, so
there are no examples for:

- Billing, credits, auto-recharge, plan selection or plan gating
- Team members, invitations and roles
- Notification preferences, profile edits, email changes
- Creating an organization, or proxying as another account
- Browsing S3 buckets and objects
- Changing a job's schedule (`job` is read-only)
- Inviting a third party to authorize an identity on your behalf

A few endpoints are also excluded deliberately rather than missing — a command
that would print a third-party credential to stdout is not shipped at all.
