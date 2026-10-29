# Browsing the Product Catalog

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — List source products](#step-1--list-source-products)
- [Step 2 — List destination products](#step-2--list-destination-products)
- [Step 3 — Read one product](#step-3--read-one-product)
- [Step 4 — Read the product definition card](#step-4--read-the-product-definition-card)
- [Step 5 — Find the stage IDs](#step-5--find-the-stage-ids)
- [Step 6 — List supported providers](#step-6--list-supported-providers)
- [Step 7 — Search transformation rules](#step-7--search-transformation-rules)
- [Catalog commands at a glance](#catalog-commands-at-a-glance)
- [See also](#see-also)

---

## Overview

A **product** is what data a pipeline moves: Amazon Attribution, Facebook Page
Insights, Shopify Orders, or on the other side of the pipeline a Redshift or
BigQuery destination. Everything else — identities, stages, parameters — hangs
off the product you pick, so the catalog is where most work starts.

---

## When to use this

- Choosing a source product before creating a subscription
- Finding the `stage_ids` a product requires
- Finding which identity type a product needs before authorizing one
- Checking whether a product is active; creation is rejected for inactive ones

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)

---

## Step 1 — List source products

```bash
obcmd product list --is_storage_product 0
obcmd product list --is_storage_product 0 --name_contains "amazon attribution"
```

| Flag | Effect |
|---|---|
| `--is_storage_product` | `0` for source products, `1` for destination products |
| `--active` | Filter by active status; the API defaults to `1` |
| `--remote_identity_type` | Only products requiring that identity type |
| `--name` | Exact name match |
| `--name_contains` | Case-insensitive substring |
| `--page`, `--page_size` | Pagination; or use `--all` |

```bash
# The whole catalog as a flat table of id and name
obcmd product list --all --fields id,name,is_storage_product
```

---

## Step 2 — List destination products

```bash
obcmd product list --is_storage_product 1 --fields id,name
```

This is the destination catalog. It does not report plan entitlement — there is
no plan-gate check in the CLI.

---

## Step 3 — Read one product

```bash
obcmd product get --product_id 50
obcmd product get --product_id 50 --fields remote_identity_type_id,active
```

`remote_identity_type_id` is the identity type this product requires. Feed it to
`obcmd remote-identity-shared list --remote_identity_type <id>` to find a
usable identity.

---

## Step 4 — Read the product definition card

```bash
obcmd product-card list
obcmd product-card get --product_id 95
obcmd product-card get --product_id 95 --fields 'id,stages.name'
```

Cards carry the full definition for a product, including its stages. `--fields`
with dot notation reaches nested keys, which matters here — a card is large.

---

## Step 5 — Find the stage IDs

```bash
obcmd product-payload list --product_id 50 --fields name,stage_id
```

Each payload definition has a `stage_id` and a `name` describing the dataset.
Those values feed two things:

- the `stage_ids` product parameter on `subscription create`
- the optional `--stage_id` on `history trigger`

`--stage_id_gte` defaults to `1000`, which excludes legacy records. Lower it
only if you need them.

> A `stage_id` listed here is **not** evidence that the product supports
> historical backfill. History requires historical meta for the (product,
> subproduct, stage) triple, which is a separate thing. See
> [Requesting historical data](history-backfill.md).

---

## Step 6 — List supported providers

```bash
obcmd identity-type list
obcmd identity-type list --name_contains snowflake
obcmd identity-type list --auth_service oauth2
obcmd identity-type get --rit_id 14
```

The identity type catalog is the list of third-party providers Openbridge can
authenticate against — Google, Facebook, Amazon, Shopify, BigQuery, Snowflake
and the rest. You need the type ID to authorize a new identity.

---

## Step 7 — Search transformation rules

```bash
obcmd rule list --path_contains amazon --latest
obcmd rule list --path "some/exact/path" --version 3
```

Rules are versioned by path. `--latest` collapses to the newest version of
each; `--version` pins one.

---

## Catalog commands at a glance

| Command | Returns |
|---|---|
| `product list` | Products, filterable by source/destination, identity type, name |
| `product get` | One product, including its required identity type |
| `product-card list` | Definition cards for all active products |
| `product-card get` | One product's full definition card |
| `product-payload list` | Payload definitions and `stage_id` values for a product |
| `identity-type list` | Supported third-party providers |
| `identity-type get` | One provider record |
| `rule list` | Transformation rules by path and version |
| `history-limit get` | Maximum concurrent history requests, one row per (product, subproduct, stage) |

---

## See also

- [Creating a subscription](creating-a-subscription.md) — where these IDs are used
- [Authorizing a third-party identity](authorizing-an-identity.md) — using an identity type ID
- [Command Reference](../commands.md)
