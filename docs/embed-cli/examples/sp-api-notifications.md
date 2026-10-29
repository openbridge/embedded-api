# SP-API Notification Subscriptions

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — Pick the identity](#step-1--pick-the-identity)
- [Step 2 — List the available notification types](#step-2--list-the-available-notification-types)
- [Step 3 — Create a notification subscription](#step-3--create-a-notification-subscription)
- [Step 4 — Update one](#step-4--update-one)
- [Step 5 — Delete one](#step-5--delete-one)
- [Not the same thing as an Openbridge subscription](#not-the-same-thing-as-an-openbridge-subscription)
- [See also](#see-also)

---

## Overview

Amazon SP-API can push notifications — order changes, report readiness, listing
updates — rather than waiting to be polled. These commands manage those
notification subscriptions on the Amazon side, per remote identity.

---

## When to use this

- Enabling SP-API push notifications for a seller or vendor identity
- Auditing or removing notification subscriptions you created

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)
- A valid SP-API remote identity (type 17 for seller, 18 for vendor)

---

## Step 1 — Pick the identity

```bash
obcmd identity-type list --name_contains "sp api"
obcmd remote-identity-shared list --remote_identity_type 17 --invalid_identity 0 \
  --fields id,name,remote_unique_id
```

`remote_unique_id` on a type 17 identity is the selling partner ID, which is
how you confirm you have the right seller account.

---

## Step 2 — List the available notification types

```bash
obcmd sp-notification-type list --account_type seller
obcmd sp-notification-type list --account_type vendor
```

`--account_type` is required and takes `seller` or `vendor`.

---

## Step 3 — Create a notification subscription

```bash
obcmd sp-notification create --remote_identity_id 9001 \
  --notification_type ANY_OFFER_CHANGED --dry-run

obcmd sp-notification create --remote_identity_id 9001 \
  --notification_type ANY_OFFER_CHANGED
```

Use a `notification_type` value from step 2 rather than one remembered from
Amazon's documentation — the accepted set is whatever that endpoint returns for
the account type.

---

## Step 4 — Update one

```bash
obcmd sp-notification update --remote_identity_id 9001 --subscription_id 44120
```

Here `--subscription_id` is the **notification** subscription ID on the Amazon
side, not an Openbridge subscription ID.

---

## Step 5 — Delete one

```bash
obcmd sp-notification delete --remote_identity_id 9001 --subscription_id 44120 --dry-run
obcmd sp-notification delete --remote_identity_id 9001 --subscription_id 44120 --yes
```

Destructive, so `--yes` is required once you drop `--dry-run`.

---

## Not the same thing as an Openbridge subscription

| Term | What it is | Commands |
|---|---|---|
| Openbridge subscription | A pipeline: product + identity + destination | `subscription *` |
| SP-API notification subscription | An Amazon-side push registration for one identity | `sp-notification *` |

Deleting a notification subscription does not affect any Openbridge pipeline,
and retiring a pipeline does not remove notification registrations.

---

## See also

- [Resolving platform IDs](resolving-platform-ids.md) — the rest of the SP-API lookups
- [Inspecting identities](inspecting-identities.md)
