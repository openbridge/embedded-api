# Recipes

Complete flows, in the order the API actually requires them.

## Create a source subscription

A subscription connects three things: a **product** (what data), a **remote
identity** (whose credentials), and a **storage destination** (where it lands).
You need all three IDs before you can create one.

```bash
# 1. Your account and user IDs
obcmd account get --fields id
obcmd user get --fields id
obcmd config update --account_id <account_id> --user_id <user_id>   # stop passing them

# 2. Pick a source product
obcmd product list --is_storage_product 0 --name_contains "amazon attribution"

# 3. Its payload definitions give you the stage_ids
obcmd product-payload list --product_id 50 --fields name,stage_id

# 4. A valid identity of the type that product requires
obcmd product get --product_id 50 --fields remote_identity_type_id
obcmd remote-identity-shared list --remote_identity_type 14 --invalid_identity 0

# 5. A destination
obcmd storage list

# 6. Preview, then create
obcmd subscription create \
  --account <account_id> --user <user_id> --product 50 \
  --name "Amazon Attribution - Brand X" \
  --status active --date_start 2026-01-01T00:00:00Z \
  --remote_identity <remote_identity_id> --storage_group <storage_group_id> \
  --product_parameters '{"stage_ids":"[1000,1001,1002]","profile_id":"<profile_id>"}' \
  --dry-run

# drop --dry-run to execute
```

Notes that will bite you otherwise:

- `stage_ids` is a **string** containing a JSON array, not an array.
- Set the identity via `--remote_identity`, not inside `--product_parameters`.
  Supplying both is allowed only when they agree; conflicting values return 400.
- Creating a subscription against an inactive product is rejected.

## Update product parameters without clobbering the rest

`product_parameters` merges on update. Omitted keys keep their stored value.

```bash
obcmd subscription update --subscription_id <subscription_id> \
  --product_parameters '{"stage_ids":"[1000,1001]"}'

# Confirm what is stored
obcmd subscription-parameter list --subscription_id <subscription_id>
```

There is no general "replace all parameters" operation and no null-to-delete.

## Backfill historical data

```bash
# Date range
obcmd history trigger --subscription_id <subscription_id> \
  --start_date 2026-01-01 --end_date 2026-01-31 --dry-run

# Specific non-contiguous dates
obcmd history trigger --subscription_id <subscription_id> \
  --dates '["2026-01-05","2026-01-12"]' --stage_id 1000

# Watch it
obcmd history list --subscription_id <subscription_id>

# Stop it
obcmd history cancel --transaction_id 72418 --yes           # one transaction
obcmd history delete --subscription_id <subscription_id> --dry-run     # all of them, preview first
```

Either `--dates`, or both `--start_date` and `--end_date`, is required.

## Find what is broken

```bash
# Failing healthchecks in the last week
obcmd healthcheck list --account_id <account_id> --status ERROR \
  --filter modified_at__gte=2026-08-12 --order_by=-modified_at

# Revoked third-party credentials
obcmd remote-identity-shared list --invalid_identity 1

# Failed jobs for one subscription
obcmd job list --subscription_ids <subscription_id> --all | jq -c 'select(.status != "processed")'
```

`--filter` passes any Django-style lookup straight through:
`__gte`, `__lte`, `__contains`, `__icontains`, `__exact`.

## Resolve platform IDs before subscribing

Each integration has a lookup endpoint that turns a remote identity into the IDs
a subscription needs.

```bash
obcmd amzadv-profile list --remote_identity_id <remote_identity_id> --profile_types seller,vendor
obcmd sp-marketplace list --remote_identity_id <remote_identity_id>
obcmd googleads-customer list --remote_identity_id <remote_identity_id>
obcmd youtube-channel list --remote_identity_id <remote_identity_id>
obcmd facebook-ad-account list --remote_identity_id <remote_identity_id>
obcmd gcm-report list --remote_identity_id <remote_identity_id> --profile_id <profile_id>
obcmd shopify-shop-graphql get --remote_identity_id <remote_identity_id>
```

## Authorize a new third-party account

Identity creation is a browser flow; the CLI handles the parts that are not.

```bash
# 1. Which identity type
obcmd identity-type list --name_contains snowflake

# 2. For Snowflake and Shopify only: store your own OAuth app first
obcmd oauth-app create --remote_identity_type 19 --account <account_id> --user <user_id> \
  --client_id "$CLIENT_ID" --client_secret "$CLIENT_SECRET" \
  --extra_params '{"account_authorization_url":"https://acct.snowflakecomputing.com"}'

# 3. Create the state record
obcmd state create --remote_identity_type_id 19 --user_id <user_id> \
  --return_url https://yourapp.example/oauth/complete --oauth_id <oauth_id>

# 4. Open the returned token in a browser
#    https://oauth.api.openbridge.io/oauth/initialize?state=<token>
#    Openbridge redirects to return_url with ri_id=<new identity id>
```

## Provision a destination

Destination creation is asynchronous.

```bash
obcmd destination create --name "My Redshift Destination" \
  --storage_parameters '{"storage":"redshift","remote_identity_id":0}'

# Poll the co_id from the response until it stops returning 202
obcmd destination get --co_id <co_id>
```

## Agent-friendly patterns

```bash
# Discover everything in one call, no round trips
obcmd describe --json > obcmd-tree.json

# Branch on exit code rather than parsing prose
obcmd subscription get --subscription_id "$ID" --json > sub.json
case $? in
  0) echo "exists" ;;
  3) echo "missing; creating" ;;
  4) echo "re-authenticate"; exit 1 ;;
  5) echo "conflict; re-reading state" ;;
esac

# Full API control when the convenience flags are not enough
echo '{"data":{"type":"Subscription","attributes":{"status":"paused"}}}' \
  | obcmd subscription update --subscription_id <subscription_id> --payload -
```
