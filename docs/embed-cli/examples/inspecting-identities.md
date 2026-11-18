# Inspecting Identities

## Table of Contents

- [Overview](#overview)
- [When to use this](#when-to-use-this)
- [Prerequisites](#prerequisites)
- [Step 1 — List every identity you may use](#step-1--list-every-identity-you-may-use)
- [Step 2 — Narrow to one provider](#step-2--narrow-to-one-provider)
- [Step 3 — Find revoked credentials](#step-3--find-revoked-credentials)
- [Step 4 — Identify which third-party account an identity reads from](#step-4--identify-which-third-party-account-an-identity-reads-from)
- [Step 5 — Read one identity](#step-5--read-one-identity)
- [Step 6 — Read an identity's stored metadata](#step-6--read-an-identitys-stored-metadata)
- [Step 7 — Find the subscriptions an identity feeds](#step-7--find-the-subscriptions-an-identity-feeds)
- [`remote-identity` vs `remote-identity-shared`](#remote-identity-vs-remote-identity-shared)
- [See also](#see-also)

---

## Overview

A **remote identity** is a stored authorization against a third-party platform:
the Amazon, Google, Facebook or Shopify account whose data a pipeline reads.
Subscriptions reference one by `remote_identity_id`, and a pipeline whose
identity has been revoked stops producing data.

Credentials themselves are never returned by these endpoints.

---

## When to use this

- Finding the `remote_identity_id` a subscription needs
- Polling for revoked credentials before customers notice
- Correlating an Openbridge identity with the third-party account it reads from
- Checking what metadata an identity carries

---

## Prerequisites

- Authenticated session; see [Authenticating](authenticating.md)

---

## Step 1 — List every identity you may use

```bash
obcmd remote-identity-shared list
obcmd remote-identity-shared list --ordering=-id          # newest first
obcmd remote-identity-shared list --all --fields id,name,remote_identity_type_id,remote_unique_id
```

This is the list to use when attaching an identity to a subscription: it
includes identities shared with your account by other accounts, not only the
ones you created.

---

## Step 2 — Narrow to one provider

```bash
# Which type ID first
obcmd identity-type list --name_contains "sp api"

# Then the identities of that type
obcmd remote-identity-shared list --remote_identity_type 17 --invalid_identity 0
```

`--invalid_identity 0` restricts to identities whose credentials still work.

---

## Step 3 — Find revoked credentials

```bash
obcmd remote-identity-shared list --invalid_identity 1
```

Subscriptions attached to an invalid identity stop processing data. Openbridge
re-checks identities on active subscriptions every 24 hours, but if you resell
Openbridge, detection and customer notification are yours to handle —
Openbridge has no channel to your customers.

Re-authorizing is a browser flow; see
[Authorizing a third-party identity](authorizing-an-identity.md).

---

## Step 4 — Identify which third-party account an identity reads from

`remote_unique_id` is the identity's own identifier on the platform it
authenticates against, in that platform's format. It is not an internal key and
not an Openbridge ID.

```bash
obcmd remote-identity-shared list --fields id,name,remote_identity_type_id,remote_unique_id
```

| Type | Provider | Example `remote_unique_id` |
|---|---|---|
| 1 | Google Api Oauth2 | `101878852755606711695` |
| 2 | Facebook Api Oauth2 | `768816513` |
| 8 | Google Adwords | `114465804519577046993` |
| 12 | BigQuery Service | `eba4c56d018038be4a6375c4221f209eb1d011ob` |
| 14 | Amazon Oauth | `amzn1.account.AH4XMYTXT4TG5BZDYCBJMMUMPDOQ` |
| 16 | Shopify Oauth | `88393449745` |
| 17 | SP API Oauth | `A1AU2416LNDBIH` |
| 18 | Vendor Central OAuth | `amzn1.vg.387220` |

For a type 17 identity this is the **selling partner ID**. Reading it off the
list is the cheapest way to get that value — there is no need to resolve it from
raw credentials.

It is a default column on both list commands, so it appears in text output
without `--fields`.

---

## Step 5 — Read one identity

```bash
obcmd remote-identity get --remote_identity_id 9001
```

To audit only the identities your own account created, rather than everything it
may use:

```bash
obcmd remote-identity list
obcmd remote-identity list --remote_identity_type 17
obcmd remote-identity list --all --fields id,name,remote_unique_id
```

---

## Step 6 — Read an identity's stored metadata

```bash
# Every key on one identity, including values
obcmd identity-meta get --remote_identity_id 9001

# One key
obcmd identity-meta get --remote_identity_id 9001 --key_name region

# Just the key names
obcmd identity-meta get --remote_identity_id 9001 --fields key_name

# Metadata records across identities
obcmd identity-meta list --remote_identity 9001
obcmd identity-meta list --meta_format ENCRYPTED_JSON
```

`identity-meta get` always returns an array, one row per key, including for an
identity with a single key. It includes `meta_value`; narrow with `--fields`
when you do not want the payload in your scrollback.

---

## Step 7 — Find the subscriptions an identity feeds

```bash
obcmd subscription list --remote_identity 9001 --fields id,name,status
```

Use this before re-authorizing or retiring an identity — it is the blast radius.

> Pass `--remote_identity`, with an underscore. A hyphenated spelling is
> accepted by the API, filters nothing, and returns the full unfiltered page at
> exit 0. The CLI only ever sends the underscore form.

---

## `remote-identity` vs `remote-identity-shared`

| Command | Scope | Use for |
|---|---|---|
| `remote-identity list` | Identities **your account created** | Auditing what you own |
| `remote-identity-shared list` | Every identity your account **may use**, including shared ones | Choosing an identity for a subscription, polling for revocations |

`remote-identity-shared list` is the one with `--invalid_identity` and
`--ordering`. Prefer it unless you specifically want ownership.

---

## See also

- [Authorizing a third-party identity](authorizing-an-identity.md)
- [Resolving platform IDs](resolving-platform-ids.md) — turning an identity into platform-side IDs
- [Monitoring pipelines](monitoring-pipelines.md) — what a revoked identity looks like downstream
