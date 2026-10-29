# Resolving Platform IDs

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Start from an identity](#step-1--start-from-an-identity)
- [Amazon Advertising](#amazon-advertising)
- [Amazon Seller and Vendor (SP-API)](#amazon-seller-and-vendor-sp-api)
- [Google](#google)
- [Facebook](#facebook)
- [Shopify](#shopify)
- [Putting the values into product_parameters](#putting-the-values-into-product_parameters)
- [Lookup commands at a glance](#lookup-commands-at-a-glance)
- [See also](#see-also)

---

## Overview

A subscription's `product_parameters` carries identifiers that belong to the
third-party platform, not to Openbridge: an advertising profile, a Google Ads
customer, a marketplace, a shop. Each integration has a lookup command that
turns a `remote_identity_id` into the IDs that platform exposes.

Every command here is read-only and takes `--remote_identity_id`.

---

## When to use this

- Filling in `product_parameters` before `subscription create`
- Checking that an identity can actually see the account you expect
- Validating credentials or ASINs before building a pipeline

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- A valid remote identity; see [Inspecting identities](inspecting-identities.md)

---

## Step 1 — Start from an identity

```bash
obcmd remote-identity-shared list --invalid_identity 0 \
  --fields id,name,remote_identity_type_id,remote_unique_id
```

`remote_unique_id` is already the identity's own account ID on its platform —
for an SP-API identity, that is the selling partner ID. Read it here before
reaching for a lookup call.

---

## Amazon Advertising

```bash
# Profiles — the profile_id product parameter
obcmd amzadv-profile list --remote_identity_id 9001
obcmd amzadv-profile list --remote_identity_id 9001 --profile_types seller,vendor
obcmd amzadv-profile list --remote_identity_id 9001 --is_manager true

# Brands visible to a profile
obcmd amzadv-brand list --remote_identity_id 9001 --profiles 3281014538916,3281014538917

# DSP advertisers under one profile
obcmd amzadv-advertiser list --remote_identity_id 9001 --profile_id 3281014538916

# Is this profile a Kindle Direct Publishing account?
obcmd amzadv-kdp get --remote_identity_id 9001 --profile_id 3281014538916

# Does attribution reporting work for this profile?
obcmd amzadv-attribution validate --remote_identity_id 9001 --profile_id 3281014538916

# DSP report metadata — no identity needed
obcmd amzadv-dsp-map list
obcmd amzadv-dsp-metric list
```

The profile ID returned by `amzadv-profile list` is the `profile_id` product
parameter for Amazon Advertising subscriptions.

> There is no command that returns an Amazon Advertising access token. It was
> removed deliberately: a CLI that prints a third-party credential to stdout
> puts it in shell history, CI logs and scrollback.

---

## Amazon Seller and Vendor (SP-API)

```bash
# Marketplaces the identity can read
obcmd sp-marketplace list --remote_identity_id 9001

# Selling partner ID
obcmd sp-seller-id get --remote_identity_id 9001

# Validate ASINs against the identity
obcmd sp-asin validate --remote_identity_id 9001 --asins '["B000123456","B000654321"]'

# Validate a private SP-API application's credentials
obcmd sp-credential validate --payload @creds.json
```

`sp-credential validate` is a POST that reads rather than mutates, so it offers
no `--dry-run`. Supply the credential object with `--payload` from a file rather
than inline, so the values stay out of shell history.

For a type 17 identity, `remote_unique_id` on the identity record already holds
the selling partner ID — `sp-seller-id get` is the lookup when you do not have
the identity record in hand.

---

## Google

```bash
# Google Ads customers
obcmd googleads-customer list --remote_identity_id 9001

# Customers under a manager account
obcmd googleads-managed-customer list --remote_identity_id 9001 \
  --google_ads_customer_id 1234567890

# Campaign Manager 360 — profiles, then reports for a profile
obcmd gcm-profile list --remote_identity_id 9001
obcmd gcm-report list --remote_identity_id 9001 --profile_id 7654321

# Search Ads 360 agencies and advertisers
obcmd gsa-agency list --remote_identity_id 9001

# YouTube channels, and metadata for one by URL
obcmd youtube-channel list --remote_identity_id 9001
obcmd youtube-channel get --remote_identity_id 9001 \
  --channel_id https://www.youtube.com/@handle
```

`gcm-report list` needs a profile ID, so `gcm-profile list` comes first.
`youtube-channel get` takes a channel **URL** in `--channel_id`.

---

## Facebook

```bash
# Ad accounts — cursor-paginated
obcmd facebook-ad-account list --remote_identity_id 9001
obcmd facebook-ad-account list --remote_identity_id 9001 --next "<cursor>"

# Page profiles
obcmd facebook-page list --remote_identity_id 9001
```

`facebook-ad-account list` paginates by cursor, not by page. Take the token from
the previous response and pass it as `--next`; `--page` does not apply.

---

## Shopify

```bash
obcmd shopify-shop-graphql get --remote_identity_id 9001
```

Returns shop info via the GraphQL Admin API — the shop ID and settings you need
for a Shopify subscription.

---

## Putting the values into product_parameters

```bash
# Inspect the keys first — they are the vendor's names, not Openbridge's
obcmd amzadv-profile list --remote_identity_id 9001 --json | jq '.[0] | keys'

PROFILE=$(obcmd amzadv-profile list --remote_identity_id 9001 --json | jq -r '.[0].<profile key>')
STAGES=$(obcmd product-payload list --product_id 50 --json | jq -c '[.[].stage_id]' | tr -d ' ')

obcmd subscription create \
  --account 12345 --user 67890 --product 50 \
  --status active --date_start 2026-01-01 \
  --remote_identity 9001 --storage_group 4001 \
  --product_parameters "{\"stage_ids\":\"$STAGES\",\"profile_id\":\"$PROFILE\"}" \
  --dry-run
```

Two things to keep straight:

- `stage_ids` is a **string containing a JSON array**, not an array.
- Field names inside the lookup responses are the vendor's, not Openbridge's —
  check the actual keys with `--json | jq 'keys'` rather than assuming.

The safest approach for a new product is to copy `product_parameters` from a
working subscription and substitute only the IDs you resolved. See
[Creating a subscription](creating-a-subscription.md).

---

## Lookup commands at a glance

| Command | Takes | Returns |
|---|---|---|
| `amzadv-profile list` | identity, `--profile_types`, `--is_manager` | Advertising profiles (`profile_id`) |
| `amzadv-brand list` | identity, `--profiles` | Brands visible to those profiles |
| `amzadv-advertiser list` | identity, `--profile_id` | DSP advertisers |
| `amzadv-kdp get` | identity, `--profile_id` | Whether the profile is a KDP account |
| `amzadv-attribution validate` | identity, `--profile_id` | Whether attribution reporting works |
| `amzadv-dsp-map list` | — | DSP report field maps |
| `amzadv-dsp-metric list` | — | DSP report metrics |
| `sp-marketplace list` | identity | SP-API marketplaces |
| `sp-seller-id get` | identity | Selling partner ID |
| `sp-asin validate` | identity, `--asins` | Per-ASIN validity |
| `sp-credential validate` | `--payload` | Whether private SP-API credentials work |
| `googleads-customer list` | identity | Google Ads customers |
| `googleads-managed-customer list` | identity, `--google_ads_customer_id` | Customers under a manager |
| `gcm-profile list` | identity | Campaign Manager 360 user profiles |
| `gcm-report list` | identity, `--profile_id` | Campaign Manager 360 reports |
| `gsa-agency list` | identity | Search Ads 360 agencies and advertisers |
| `youtube-channel list` | identity | YouTube channels |
| `youtube-channel get` | identity, `--channel_id` (URL) | Channel metadata |
| `facebook-ad-account list` | identity, `--next` | Facebook ad accounts (cursor-paginated) |
| `facebook-page list` | identity | Facebook page profiles |
| `shopify-shop-graphql get` | identity | Shopify shop info |

---

## See also

- [Creating a subscription](creating-a-subscription.md)
- [Inspecting identities](inspecting-identities.md)
- [SP-API notification subscriptions](sp-api-notifications.md)
