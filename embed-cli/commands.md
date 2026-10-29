# Command Reference

<!-- GENERATED FILE - do not edit by hand. Run `npm run docs` to regenerate. -->

Generated from `obcmd describe --json` at version 0.7.1.

Grammar: `obcmd <resource> <verb> [flags]`

## Exit codes

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | failure (API, network or internal); check retryable in the error body |
| 2 | usage error (bad or missing flags, invalid input) |
| 3 | not found |
| 4 | permission denied or not authenticated |
| 5 | conflict; read current state before retrying |

## Global flags

| Flag | Type | Description |
|---|---|---|
| `--json` | boolean | Force JSON output regardless of TTY detection. |
| `--output` | enum | Output mode: json or text. Overrides --json. |
| `--fields` | string | Comma-separated field mask. Dot notation reaches nested keys. Use * for all fields. |
| `--all` | boolean | Auto-paginate and stream every page as NDJSON. List commands only. |
| `--dry-run` | boolean | Resolve and preview the request without sending it. Mutating commands only. |
| `--yes` | boolean | Skip the confirmation guard on destructive commands. |
| `--payload` | string | Raw API-shaped JSON body. Accepts inline JSON, @file, or - for stdin. |
| `--filter` | string | Additional API-native query filter as key=value. Repeatable. |
| `--color` | boolean | Colorize human output. Negate with --no-color. |
| `--help` | boolean | Show help for the command. Combine with --json for machine-readable help. |
| `--version` | boolean | Print the obcmd version. |

## Resources

### Openbridge

#### `account`

##### `obcmd account get`

Get the account record for the authenticated token.

`GET /account` · account API · read-only

> The returned id is the account_id required by subscription and healthcheck calls.

#### `destination`

##### `obcmd destination create`

Provision a new Openbridge destination. Asynchronous.

`POST /service/ob/destination` · service API · mutating

> Returns 202 with a co_id. Poll with `obcmd destination get --co_id <id>` until it returns 200 (ready) or 400 (failed).

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--name` | string | yes | body | Display name for the destination. |
| `--storage_parameters` | json | yes | body | Storage connection object, e.g. {"storage":"redshift","remote_identity_id":0}. |

##### `obcmd destination get`

Poll the status of a destination provisioning operation.

`GET /service/ob/destination/{co_id}` · service API · read-only

> 202 means still processing; 200 returns the created subscription; 400 means validation failed.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--co_id` | integer | yes | path | Operation ID from the create response. |

#### `generic-state`

##### `obcmd generic-state create`

Create a ClientState record for a non-OAuth flow.

`POST /state` · state API · mutating

> Unauthenticated endpoint. No account context is injected, and no credential is acquired or sent.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--state` | json | yes | body | Arbitrary JSON payload carrying flow context. |

#### `healthcheck`

##### `obcmd healthcheck list`

List healthcheck records for an account.

`GET /service/healthchecks/{environment}/healthchecks/account/{account_id}` · service API · read-only · paginated

> Supports Django lookup suffixes via --filter, e.g. --filter modified_at__gte=2026-01-01. Requesting another account returns 403.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--account_id` | integer | yes | path | Account ID. Must match the account in your token; defaults to the configured account. |
| `--status` | string |  | query | Filter by status, e.g. OK or ERROR. |
| `--subscription_id` | integer |  | query | Filter by subscription ID. |
| `--product_id` | integer |  | query | Filter by product ID. |
| `--job_id` | integer |  | query | Filter by job ID. |
| `--order_by` | string |  | query | Sort fields, comma-separated. Prefix with - for descending, attached with =, as in --order_by=-modified_at. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

#### `history`

##### `obcmd history trigger`

Trigger a historical data retrieval run for a subscription.

`POST /service/history/{environment}/history/{subscription_id}` · service API · mutating

> Either --dates, or both --start_date and --end_date, must be supplied. start_date is the more recent date and end_date the older one; reversing them fails with "do you have start_date and end_date backwards?". The subscription must already have a job, which the backend creates within about ten seconds of the subscription being created, and its product must have historical meta for its (product, subproduct, stage) triple. Returns a HistoryTransaction carrying the job_ids it queued.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |
| `--start_date` | date |  | body | Range start, YYYY-MM-DD. The MORE RECENT date: the API converts both to days back from today and requires start < end, so start_date must be nearer to today than end_date. Required unless --dates is given. |
| `--end_date` | date |  | body | Range end, YYYY-MM-DD. The OLDER date. Required unless --dates is given. |
| `--dates` | json |  | body | JSON array of specific dates, e.g. ["2026-01-01","2026-01-05"]. Use instead of a range. |
| `--product_id` | integer |  | body | Restrict the run to one product. |
| `--stage_id` | integer |  | body | Restrict the run to one pipeline stage. Requires --start_time. |
| `--start_time` | string |  | body | When processing should begin, YYYY-MM-DD HH:MM:SS. Must be in the FUTURE -- this schedules the run, it is not the start of the date range. |
| `--primary_run` | boolean |  | body | Whether this is a primary run. |

##### `obcmd history get`

Get a history transaction by its own ID.

`GET /service/history/{environment}/history/{transaction_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--transaction_id` | integer | yes | path | History transaction ID. |

##### `obcmd history list`

List history transaction status records for a subscription.

`GET /service/history/{environment}/history/status/{subscription_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |

##### `obcmd history cancel`

Cancel one history transaction.

`PATCH /service/history/{environment}/history/{transaction_id}` · service API · mutating · **destructive**

> Cancels the jobs the transaction queued. The response reports how many were updated.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--transaction_id` | integer | yes | path | History transaction ID. |
| `--status` | cancelled |  | body | Always cancelled. (default: `cancelled`) |

##### `obcmd history delete`

Cancel every history transaction attached to a subscription.

`PATCH /service/history/{environment}/history/status/{subscription_id}` · service API · mutating · **destructive**

> Bulk cancellation. Preview with --dry-run before confirming with --yes.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |
| `--status` | cancelled |  | body | Always cancelled. (default: `cancelled`) |

#### `history-limit`

##### `obcmd history-limit get`

Get the maximum number of permitted history requests.

`GET /service/history/{environment}/history/meta/max-request` · service API · read-only

> Returns every limit row: one per (product, subproduct, stage). Always an array.

#### `identity-meta`

##### `obcmd identity-meta list`

List remote identity metadata records.

`GET /rim` · remoteIdentity API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity` | integer |  | query | Filter by remote identity ID. |
| `--meta_format` | STRING \| JSON \| ENCRYPTED_STRING \| ENCRYPTED_JSON |  | query | Filter by storage format. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd identity-meta get`

Read every metadata record for one remote identity.

`GET /ri/{remote_identity_id}/rim-overview` · remoteIdentity API · read-only

> Returns the full metadata record for every key on the identity, including meta_value. Narrow it with --fields when the payload is not wanted. Always returns an array, one row per key.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID. |
| `--key_name` | string |  | query | Filter to a single meta key. |

#### `identity-type`

##### `obcmd identity-type list`

List the catalog of supported third-party providers.

`GET /rit` · remoteIdentity API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--name` | string |  | query | Exact name match. |
| `--name_contains` | string |  | query | Case-insensitive name substring. |
| `--auth_service` | string |  | query | Exact auth service identifier. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd identity-type get`

Get a remote identity type by ID.

`GET /rit/{rit_id}` · remoteIdentity API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--rit_id` | integer | yes | path | Remote identity type ID. |

#### `job`

##### `obcmd job list`

List pipeline job runs for a subscription.

`GET /service/jobs/jobs` · service API · read-only · paginated

> Requires --subscription_ids. Without it the API returns 403 "No subscription IDs provided", which is an argument error reported as a permission error -- --id and --ids do not satisfy it.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_ids` | string | yes | query | Comma-separated subscription IDs. Required; the plural spelling is the only one the API reads. |
| `--id` | integer |  | query | Narrow to a single job ID. Not a substitute for --subscription_ids. |
| `--ids` | string |  | query | Comma-separated job IDs. Appears to be ignored by the API -- use --id to filter. |
| `--order_by` | string |  | query | Sort field, e.g. id or -modified_at. A leading - needs the = form: --order_by=-modified_at. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd job get`

Get a job by ID.

`GET /service/jobs/jobs/{job_id}` · service API · read-only

> Requires --subscription_ids alongside --job_id; the jobs backend authorizes by subscription.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--job_id` | integer | yes | path | Job ID. |
| `--subscription_ids` | string | yes | query | The job's subscription ID. Required: the path ID alone returns 403. |

#### `oauth-app`

##### `obcmd oauth-app list`

List OAuth app records for the account.

`GET /oauth/apps` · oauth API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_type_id` | integer |  | query | Filter by remote identity type. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd oauth-app get`

Get an OAuth app record by ID.

`GET /oauth/apps/{oauth_id}` · oauth API · read-only

> client_secret is never returned.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--oauth_id` | integer | yes | path | OAuth app record ID. |

##### `obcmd oauth-app create`

Create or update an OAuth app record.

`POST /oauth/apps` · oauth API · mutating

> An existing record with the same account and client_id is updated and returns 200 rather than 201.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_type` | integer | yes | body | Remote identity type this app applies to. |
| `--account` | integer | yes | body | Account ID. |
| `--user` | integer | yes | body | User ID. |
| `--client_id` | string | yes | body | OAuth client ID. |
| `--client_secret` | string | yes | body | OAuth client secret. Write-only. |
| `--name` | string |  | body | Label. Auto-generated from type and client_id if omitted. |
| `--extra_params` | string |  | body | JSON-encoded string of provider extras: account_authorization_url for Snowflake, shop_url for Shopify. |

##### `obcmd oauth-app update`

Partially update an OAuth app record.

`PATCH /oauth/apps/{oauth_id}` · oauth API · mutating

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--oauth_id` | integer | yes | path | OAuth app record ID. |
| `--client_id` | string |  | body | OAuth client ID. |
| `--client_secret` | string |  | body | OAuth client secret. |
| `--name` | string |  | body | Label. |
| `--extra_params` | string |  | body | JSON-encoded provider extras. |

##### `obcmd oauth-app delete`

Delete an OAuth app record.

`DELETE /oauth/apps/{oauth_id}` · oauth API · mutating · **destructive**

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--oauth_id` | integer | yes | path | OAuth app record ID. |

#### `product`

##### `obcmd product list`

List available products.

`GET /v2/product` · subscriptions API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--active` | integer |  | query | Filter by active status. Defaults to 1 server-side. |
| `--is_storage_product` | integer |  | query | 1 for destination products, 0 for source products. |
| `--remote_identity_type` | integer |  | query | Filter by required remote identity type. |
| `--name` | string |  | query | Exact name match. |
| `--name_contains` | string |  | query | Case-insensitive name substring. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd product get`

Get a single product by ID.

`GET /v2/product/{product_id}` · subscriptions API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--product_id` | integer | yes | path | Product ID. |

#### `product-card`

##### `obcmd product-card list`

List product definition cards for all active products.

`GET /service/product-cards/card` · service API · read-only

##### `obcmd product-card get`

Get the full product definition card for one product.

`GET /service/product-cards/card/{product_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--product_id` | integer | yes | path | Product ID. |

#### `product-payload`

##### `obcmd product-payload list`

List payload definitions for a product, including stage_id values.

`GET /service/products/product/{product_id}/payloads` · service API · read-only · paginated

> stage_id values feed the stage_ids product parameter and History API requests.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--product_id` | integer | yes | path | Product ID. |
| `--stage_id_gte` | integer |  | query | Minimum stage_id. Defaults to 1000, which excludes legacy records. (default: `1000`) |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

#### `remote-identity`

##### `obcmd remote-identity list`

List remote identities created by your account.

`GET /ri` · remoteIdentity API · read-only · paginated

> Prefer `remote-identity-shared list` when looking up identities to attach to a subscription. remote_unique_id is the identity's account ID on the third-party platform, in that platform's own format: a Shopify shop ID, a Facebook ad account ID, an Amazon SP-API selling partner ID such as A1AU2416LNDBIH, a Vendor Central group such as amzn1.vg.387220. Use it to correlate an Openbridge identity with the account it reads from.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_type` | integer |  | query | Filter by identity type ID. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd remote-identity get`

Get a remote identity by ID.

`GET /ri/{remote_identity_id}` · remoteIdentity API · read-only

> Credentials are never returned by this API. remote_unique_id is the identity's account ID on the third-party platform, in that platform's own format: a Shopify shop ID, a Facebook ad account ID, an Amazon SP-API selling partner ID such as A1AU2416LNDBIH, a Vendor Central group such as amzn1.vg.387220. Use it to correlate an Openbridge identity with the account it reads from.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID. |

#### `remote-identity-shared`

##### `obcmd remote-identity-shared list`

List all identities your account may use, including those shared by other accounts.

`GET /sri` · remoteIdentity API · read-only · paginated

> Use --invalid_identity 1 to poll for revoked credentials. Subscriptions attached to an invalid identity stop processing data. remote_unique_id is the identity's account ID on the third-party platform, in that platform's own format: a Shopify shop ID, a Facebook ad account ID, an Amazon SP-API selling partner ID such as A1AU2416LNDBIH, a Vendor Central group such as amzn1.vg.387220. Use it to correlate an Openbridge identity with the account it reads from.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_type` | integer |  | query | Filter by identity type ID. |
| `--invalid_identity` | integer |  | query | 0 for valid identities only, 1 for invalid identities only. |
| `--ordering` | string |  | query | Sort field, e.g. -id for newest first. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

#### `rule`

##### `obcmd rule list`

Search transformation rules by path.

`GET /service/rules/{rules_environment}/v1/rules/search` · service API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--path` | string |  | query | Exact rule path. |
| `--path_contains` | string |  | query | Case-insensitive path substring. |
| `--latest` | boolean |  | query | Return only the latest version of each rule. |
| `--version` | integer |  | query | Return a specific version. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

#### `state`

##### `obcmd state create`

Create a ClientState record for an OAuth authorization flow.

`POST /state/oauth` · state API · mutating

> account_id and oauth:true are injected server-side from the token. The returned token is the state parameter for the authorize URL.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_type_id` | integer | yes | body | Identity type to authorize, from `obcmd identity-type list`. |
| `--user_id` | integer | yes | body | Openbridge user ID. |
| `--region` | string | yes | body | Identity region. Typically global. (default: `global`) |
| `--return_url` | string | yes | body | URL the browser returns to after the flow completes. |
| `--remote_identity_id` | integer |  | body | Existing identity to re-authorize. |
| `--oauth_id` | integer |  | body | OAuth app record ID; required for Snowflake and Shopify. |
| `--shop_url` | string |  | body | Shopify store URL. |
| `--query_params` | json |  | body | Extra key/value pairs appended to return_url on completion. |

##### `obcmd state get`

Get a state record by token.

`GET /state/{token}` · state API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--token` | id | yes | path | State token. |

##### `obcmd state update`

Partially update a state record.

`PATCH /state/{token}` · state API · mutating

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--token` | id | yes | path | State token. |
| `--state` | json | yes | body | Replacement state object. |

##### `obcmd state delete`

Delete a state record.

`DELETE /state/{token}` · state API · mutating · **destructive**

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--token` | id | yes | path | State token. |

#### `storage`

##### `obcmd storage list`

List storage destinations.

`GET /v2/storages` · subscriptions API · read-only · paginated

> Destinations are read-only via the API; create and manage them in the Openbridge UI.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--status` | string |  | query | Filter by status. Defaults to active. (default: `active`) |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

#### `subscription`

##### `obcmd subscription list`

List subscriptions.

`GET /v2/sub` · subscriptions API · read-only · paginated

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--id` | integer |  | query | Filter by subscription ID. |
| `--name` | string |  | query | Filter by name. |
| `--status` | active \| cancelled \| paused \| invalid |  | query | Filter by status. |
| `--status_not` | string |  | query | Exclude a status, e.g. invalid. |
| `--account` | integer |  | query | Filter by account ID. |
| `--product` | integer |  | query | Filter by product ID. |
| `--user` | integer |  | query | Filter by user ID. |
| `--remote_identity` | integer |  | query | Filter by remote identity ID. |
| `--storage_group` | integer |  | query | Filter by storage group ID — the `storage_group_id` field from `obcmd storage list`, not the row `id`. |
| `--page` | integer |  | query | Page number (1-based). |
| `--page_size` | integer |  | query | Results per page. |

##### `obcmd subscription get`

Get a subscription by ID.

`GET /v2/sub/{subscription_id}` · subscriptions API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |

##### `obcmd subscription create`

Create a subscription.

`POST /v2/sub` · subscriptions API · mutating

> Creation is rejected for inactive products. stage_ids is required for source products that use pipeline stages.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--account` | integer | yes | body | Account ID from `obcmd account get`. |
| `--user` | integer | yes | body | User ID from `obcmd user get`. |
| `--product` | integer | yes | body | Product ID from `obcmd product list`. |
| `--status` | active \| cancelled \| paused \| invalid | yes | body | Initial status. |
| `--date_start` | string | yes | body | Start date, ISO 8601. A plain YYYY-MM-DD is accepted. Never returned. |
| `--name` | string |  | body | Human-readable label. |
| `--date_end` | string |  | body | End date, ISO 8601. Defaults to 2099-12-31 when omitted. |
| `--remote_identity` | integer |  | body | Remote identity ID. Canonical location; do not also set it in product_parameters. |
| `--storage_group` | integer |  | body | Storage group ID — the `storage_group_id` field from `obcmd storage list`, not the row `id`. |
| `--product_parameters` | json |  | body | Flat key/value object, e.g. {"stage_ids":"[1000]"}. Required for source products. |

##### `obcmd subscription update`

Partially update a subscription.

`PATCH /v2/sub/{subscription_id}` · subscriptions API · mutating

> product_parameters merges rather than replaces. The legacy subscription_product_meta_attributes attribute is rejected.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |
| `--name` | string |  | body | Human-readable label. |
| `--status` | active \| cancelled \| paused \| invalid |  | body | New status. cancelled and invalid require --yes. |
| `--date_start` | string |  | body | Start date, ISO 8601. Never returned. |
| `--remote_identity` | integer |  | body | Remote identity ID. |
| `--storage_group` | integer |  | body | Storage group ID — the `storage_group_id` field from `obcmd storage list`, not the row `id`. |
| `--product_parameters` | json |  | body | Partial merge: omitted keys keep their stored value; an empty object clears nothing. |

##### `obcmd subscription cancel`

Cancel a subscription by setting status to cancelled.

`PATCH /v2/sub/{subscription_id}` · subscriptions API · mutating · **destructive**

> The API exposes no subscription delete; cancellation is the terminal state.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | path | Subscription ID. |
| `--status` | cancelled |  | body | Always cancelled for this verb. (default: `cancelled`) |

#### `subscription-parameter`

##### `obcmd subscription-parameter list`

Read product parameters for one subscription.

`GET /v2/spp` · subscriptions API · read-only

> Returns one aggregate resource whose id is the subscription ID, not a list of rows.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | query | Subscription ID. Exact match only. |

##### `obcmd subscription-parameter get`

Read product parameters for up to 100 subscriptions at once.

`GET /v2/spp/bulk` · subscriptions API · read-only

> All-or-nothing: if any ID is missing or inaccessible the whole request returns 404. Always returns an array, one row per requested ID, including for a single ID.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_ids` | string | yes | query | Comma-separated subscription IDs, 1 to 100. Repeatable. |

##### `obcmd subscription-parameter create`

Create a single product parameter row.

`POST /v2/spp` · subscriptions API · mutating

> Rarely needed. Prefer product_parameters on `subscription create` or `subscription update`. A duplicate key returns 409.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--data_key` | string | yes | body | Parameter name. |
| `--data_value` | string | yes | body | Parameter value; may be empty. |
| `--subscription` | integer | yes | body | Subscription ID. |

#### `transaction`

##### `obcmd transaction list`

List pipeline processing transactions for a subscription.

`GET /service/transactions/tx` · service API · read-only · cursor-paginated

> Transactions are retained for three days. Retries reuse the same transaction ID and updates are merged, so a record is the current merged state, not an attempt history -- --status ERROR finds what is failing now, not everything that ever failed. Filters are exact-match and AND-combined; there is no substring or multi-value form. Pagination is cursor-based, not page-based: --all streams every page, or take them one at a time with the --cursor token reported on stderr. A short page, or even an empty one, can still have a next page.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--subscription_id` | integer | yes | query | Subscription ID. Required on every call, including cursor pages and tree queries; without it the Service API returns 403. |
| `--limit` | integer |  | query | Records evaluated per page, 1-200. Default 50. |
| `--cursor` | string |  | query | Opaque token from meta.next_cursor on the previous page. Keep every other filter unchanged. |
| `--timestamp_from` | integer |  | query | Inclusive lower bound on processing time, Unix seconds. |
| `--timestamp_to` | integer |  | query | Inclusive upper bound on processing time, Unix seconds. |
| `--modified_at_from` | string |  | query | Inclusive lower bound on the stored modified_at text. Compared lexicographically, so match the stored format exactly; prefer --timestamp_from. |
| `--modified_at_to` | string |  | query | Inclusive upper bound on the stored modified_at text. See --modified_at_from. |
| `--attribution_date` | string |  | query | Exact stored data date, e.g. 2026-01-01 or 2026-09-09T19:00. The data date requested upstream, not the processing time. A date-only value does not match one carrying a time. |
| `--job_id` | string |  | query | Exact job ID. Many records store an empty job_id and will not match any value. |
| `--sender` | scheduler \| supervisor \| ftpsync \| zeroadmin |  | query | Reporting pipeline component. Read alongside --status. |
| `--status` | UNPROCESSED \| PROCESSING \| IN_PROGRESS \| RETRY \| ERROR \| PROCESSED \| SUCCESS \| NO_DATA \| IGNORED |  | query | Processing state. Only PROCESSED from zeroadmin confirms a destination load. |
| `--parent` | string |  | query | Exact parent transaction ID. |
| `--payload_name` | string |  | query | Exact payload name. |
| `--product_name` | string |  | query | Exact product name. |
| `--subscription_name` | string |  | query | Exact subscription display name. |
| `--error_code` | string |  | query | Exact error code. |
| `--error_message` | string |  | query | Exact full error message; no substring match. |
| `--file_path` | string |  | query | Exact file path. |
| `--time_to_live` | integer |  | query | Exact expiry timestamp, Unix seconds. |
| `--tree` | boolean |  | query | Expand child references into merged root-to-descendant records, one per branch. Filters and the cursor apply before expansion, and --limit does not cap the expanded count. |
| `--tree_depth` | integer |  | query | Child levels to traverse, 1-4. Default 4. Only valid with --tree. |

#### `user`

##### `obcmd user get`

Get the user record for the authenticated token.

`GET /user` · user API · read-only

> The returned id is the user_id required when creating subscriptions.

### Amazon Advertising

#### `amzadv-advertiser`

##### `obcmd amzadv-advertiser list`

List DSP advertisers for a profile.

`GET /service/amzadv/list-adv/{remote_identity_id}/{profile_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profile_id` | id | yes | path | Amazon Advertising profile ID. |

#### `amzadv-attribution`

##### `obcmd amzadv-attribution validate`

Test whether attribution reporting works for a profile.

`GET /service/amzadv/attribution-report-test/{remote_identity_id}/{profile_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profile_id` | id | yes | path | Amazon Advertising profile ID. |

#### `amzadv-brand`

##### `obcmd amzadv-brand list`

List brands visible to an Amazon Advertising profile.

`GET /service/amzadv/brands/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profiles` | string |  | query | Comma-separated profile IDs. |

#### `amzadv-dsp-map`

##### `obcmd amzadv-dsp-map list`

List DSP report field maps.

`GET /service/amzadv/dsp/meta/maps` · service API · read-only

#### `amzadv-dsp-metric`

##### `obcmd amzadv-dsp-metric list`

List DSP report metrics.

`GET /service/amzadv/dsp/meta/metrics` · service API · read-only

#### `amzadv-kdp`

##### `obcmd amzadv-kdp get`

Check whether a profile is a Kindle Direct Publishing account.

`GET /service/amzadv/is-kdp/{remote_identity_id}/{profile_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profile_id` | id | yes | path | Amazon Advertising profile ID. |

#### `amzadv-profile`

##### `obcmd amzadv-profile list`

List Amazon Advertising profiles for an identity.

`GET /service/amzadv/profiles-only/{remote_identity_id}` · service API · read-only

> The returned profile ID is the profile_id product parameter for Amazon Advertising subscriptions.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profile_types` | string |  | query | Comma-separated profile types, e.g. seller,vendor. |
| `--is_manager` | boolean |  | query | Filter to manager accounts. |

### Facebook

#### `facebook-ad-account`

##### `obcmd facebook-ad-account list`

List Facebook ad accounts for an identity.

`GET /service/facebook/ads-profiles/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--next` | string |  | query | Cursor token from a previous response. This endpoint is cursor-paginated, not page-paginated. |

#### `facebook-page`

##### `obcmd facebook-page list`

List Facebook page profiles for an identity.

`GET /service/facebook/page-profiles/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

### Google

#### `gcm-profile`

##### `obcmd gcm-profile list`

List Campaign Manager 360 user profiles.

`GET /service/gcm/profiles/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

#### `gcm-report`

##### `obcmd gcm-report list`

List Campaign Manager 360 reports for a profile.

`GET /service/gcm/reports/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--profile_id` | id | yes | query | Campaign Manager user profile ID. |

#### `googleads-customer`

##### `obcmd googleads-customer list`

List Google Ads customers accessible to an identity.

`GET /service/googleads/list-customers/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

#### `googleads-managed-customer`

##### `obcmd googleads-managed-customer list`

List customers managed by a Google Ads manager account.

`GET /service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--google_ads_customer_id` | id | yes | path | Manager account customer ID. |

#### `gsa-agency`

##### `obcmd gsa-agency list`

List Search Ads 360 agencies and advertisers.

`GET /service/gsa/agency/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

#### `youtube-channel`

##### `obcmd youtube-channel list`

List YouTube channels for an identity.

`GET /service/yt/list-channels/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

##### `obcmd youtube-channel get`

Get metadata for a YouTube channel by URL.

`GET /service/yt/get-channel-meta/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--channel_id` | string | yes | query | Channel URL, e.g. https://www.youtube.com/@handle. |

### Shopify

#### `shopify-shop-graphql`

##### `obcmd shopify-shop-graphql get`

Get Shopify shop info via the GraphQL Admin API.

`GET /service/shopify/shop-graphql-info/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

### Amazon Seller and Vendor

#### `sp-asin`

##### `obcmd sp-asin validate`

Validate a list of ASINs against an identity.

`POST /service/sp/validate-asins/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--asins` | json | yes | body | JSON array of ASIN strings. |

#### `sp-credential`

##### `obcmd sp-credential validate`

Validate private SP-API application credentials.

`POST /service/sp/validate-creds` · service API · read-only

> Supply the full credential object with --payload.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--payload` | json |  | body | Credential object; see the SP-API integration docs. |

#### `sp-marketplace`

##### `obcmd sp-marketplace list`

List Amazon SP-API marketplaces for an identity.

`GET /service/sp/marketplaces/{remote_identity_id}` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |

#### `sp-notification`

##### `obcmd sp-notification create`

Create an SP-API notification subscription.

`POST /service/sp/notifications/{remote_identity_id}` · service API · mutating

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--notification_type` | string |  | body | Notification type from `sp-notification-type list`. |

##### `obcmd sp-notification update`

Update an SP-API notification subscription.

`PATCH /service/sp/notifications/{remote_identity_id}/{subscription_id}` · service API · mutating

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--subscription_id` | integer | yes | path | Notification subscription ID. |

##### `obcmd sp-notification delete`

Delete an SP-API notification subscription.

`DELETE /service/sp/notifications/{remote_identity_id}/{subscription_id}` · service API · mutating · **destructive**

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | path | Remote identity ID from `obcmd remote-identity-shared list`. |
| `--subscription_id` | integer | yes | path | Notification subscription ID. |

#### `sp-notification-type`

##### `obcmd sp-notification-type list`

List SP-API notification types.

`GET /service/sp/notifications/list-notification-types` · service API · read-only

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--account_type` | seller \| vendor | yes | query | Seller or vendor account. |

#### `sp-seller-id`

##### `obcmd sp-seller-id get`

Resolve the selling partner ID for an identity.

`POST /service/sp/sp-id` · service API · read-only

> A POST that reads rather than mutates; no --dry-run is offered because nothing changes.

| Flag | Type | Required | In | Description |
|---|---|---|---|---|
| `--remote_identity_id` | integer | yes | body | Remote identity ID. |

---

44 resources, 71 commands.
