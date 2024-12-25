
- [Amazon Advertising DSP](#amazon-advertising-dsp)
  - [Self-serve Ads Account](#self-serve-ads-accounts)
    - [Self-serve example payload](#self-serve-example-payload)
  - [Managed Ads Account](#managed-ads-accounts)
    - [Managed example payload](#managed-example-payload)
  - [Subscription Product Meta Attributes definitions](#subscription-product-meta-attributes-definitions)

# Amazon Advertising DSP

The Amazon Advertising DSP v3 pipeline subscription creation path is unique in that you can configure one of 2 different types of Ads acounts.  The first are DSP Ads accounts that are manage by the account holder.  We call these `Self-serve Ads Acccounts`.  The second are accounts that are managed entirely by Amazon.  We call these `Managed Ads Accounts`.  Their subscription payloads are similar, but the way to obtain the values for them require different calls to our Service API.

## Product Meta
|Name|Value|
|-|-|
|Product Id|85|
|Remote Identity Type ID|14|

## Self-serve Ads Accounts

The self-serve Ads accounts require the following subscription_product_meta_attributes:

|data_key|format|summary|
|-|-|-|
|remote_identity_id|string|The remote identity associated with the DSP account|
|profile_id|string|The DSP profile ID that is associated with the desired DSP account ID|
|account_id|string| The DSP account ID. |
|managed|string|This value should be `false` for self-serve ads accounts|
|advertiser_ids|JSON|There is only one advertiser id associated with a managed DSP account.  However this field still must be in the format of a stringified JSON array as in the self-service DSP pipelines. |
|stage_ids|JSON|The stage IDs associated with the desired metrics.|

### Self-serve example payload

```
{
  "data": {
      "type": "Subscription",
      "attributes": {
          "account": "XXX",
          "user": "XXX",
          "product": 85,
          "name": "My self-serve ads pipeline",
          "status": "active",
          "subscription_product_meta_attributes": [
              {
                  "data_id": 0,
                  "data_key": "remote_identity_id",
                  "data_value": "00",
                  "data_format": "STRING",
                  "product": 85
              },
              {
                  "data_id": 0,
                  "data_key": "profile_id",
                  "data_value": "00000000000000000",
                  "data_format": "STRING",
                  "product": 85
              },
              {
                  "data_id": 0,
                  "data_key": "account_id",
                  "data_value": "ENTITY000000000000",
                  "data_format": "STRING",
                  "product": 85
              },
              {
                  "data_id": 0,
                  "data_key": "managed",
                  "data_value": "false",
                  "data_format": "STRING",
                  "product": 85
              },
              {
                  "data_id": 0,
                  "data_key": "advertiser_ids",
                  "data_value": "[\"0000000000001\",\"0000000000002\",\"0000000000003\"]",
                  "data_format": "JSON",
                  "product": 85
              },
              {
                  "data_id": 0,
                  "data_key": "stage_ids",
                  "data_value": "[2]",
                  "data_format": "JSON",
                  "product": 85
              }
          ],
          "quantity": 1,
          "price": 0,
          "auto_renew": 1,
          "date_start": "2024-12-25T00:52:54+00:00",
          "date_end": "2024-12-25T00:52:54+00:00",
          "invalid_subscription": 0,
          "rabbit_payload_successful": 0,
          "stripe_subscription_id": "",
          "storage_group": 245,
          "remote_identity": "22",
          "unique_hash": "[\"e7a46b3eb718bfdac083faf2e5ec7025\"]"
      }
  }
}
```

## Managed Ads Accounts

The Managed Ads accounts require the following subscription_product_meta_attributes:

|data_key|format|summary|
|-|-|-|
|remote_identity_id|string|The remote identity associated with the DSP account|
|profile_id|string|Should always be set to `NOT APPLICABLE` for managed ads pipelines|
|account_id|string| The DSP account ID. |
|managed|string|This value should be `true` for managed ads accounts|
|advertiser_ids|JSON|There is only one advertiser id associated with a managed DSP account.  However this field still must be in the format of a stringified JSON array as in the self-service DSP pipelines. |
|stage_ids|JSON|The stage IDs associated with the desired metrics.|


### Managed example payload

```
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": "342",
      "user": "309",
      "product": 85,
      "name": "Amazon Managed Test",
      "status": "active",
      "subscription_product_meta_attributes": [
        {
          "data_id": 0,
          "data_key": "remote_identity_id",
          "data_value": "0",
          "data_format": "STRING",
          "product": 85
        },
        {
          "data_id": 0,
          "data_key": "profile_id",
          "data_value": "NOT_APPLICABLE",
          "data_format": "STRING",
          "product": 85
        },
        {
          "data_id": 0,
          "data_key": "account_id",
          "data_value": "00000000000",
          "data_format": "STRING",
          "product": 85
        },
        {
          "data_id": 0,
          "data_key": "managed",
          "data_value": "true",
          "data_format": "STRING",
          "product": 85
        },
        {
          "data_id": 0,
          "data_key": "advertiser_ids",
          "data_value": "[]",
          "data_format": "JSON",
          "product": 85
        },
        {
          "data_id": 0,
          "data_key": "stage_ids",
          "data_value": "[2]",
          "data_format": "JSON",
          "product": 85
        }
      ],
      "quantity": 1,
      "price": 0,
      "auto_renew": 1,
      "date_start": "2024-12-25T00:56:23+00:00",
      "date_end": "2024-12-25T00:56:23+00:00",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": "",
      "storage_group": 245,
      "remote_identity": "22",
      "unique_hash": "[\"f6a9d8501cc9eca5e46f38f3ff1a8238\"]"
    }
  }
}
```
## Subscription Product Meta Attributes definitions

`remote_identity_id`: The remote identity associated with the DSP profile and accounts.

`profile_id`: For `managed` DSP accounts this field should always be set to `NOT APPLICABLE`.  For `self-served` DSP accounts, this will be the Amazon advertising profile associated with the DSP ads account. To retrieve this value a request to the Serive API must be made.

`account_id`: The DSP account ID. This value requires

`managed`: This is a boolean value in string format.  For `managed` accounts the value should be `true`.  For `self-serve` it should be `false`.

`advertiser_ids`: A list of advertiser IDS to collect data for.  The value is a stringified JSON array.  A `self-serve` account can collect data for multiple advertiser IDS.  However a `managed` account can only collect data for that managed account.

`stage_ids`: Stage IDs define what metrics will be collected with the pipeline.  For Amazon Advertising DSP there are over 500 different combinations.  For this reason we provide two endpoints to sort out what data to collect.

  * The first endpoint contains a map of the metric categories and their associated metrics.  You can use this map to build out interfaces to let your customers choose the metrics they desire.

  * The second endpoint contains a map of of catagory metrics to stage IDS.  Based on the desired metrics for a given category you can find the stage ID that is associated with that report. 

# Below stuff...

### Remote Identity
The remote identity id, is a reference to the identity that has authentication credentials for the Amazon DSP account that the pipeline subscription is being created for.

### Managed
Amazon DSP is unique in that it can either be Amazon managed or not.  FOr self-managed the value should be `false`.

### Profile ID
For self managed advertiser accounts a profile ID must be provided.  To request a list of DSP profiles you need to make a call to an Openbridge Service API endpoint with the remote_identity_id as part of the endpoint request.

https://service.api.openbridge.io/service/amzadv/profiles-only/{remote_identity_id}?profile_types=dsp

FOr more information please check the information in the [Service API Documentation](https://github.com/openbridge/embedded-api/blob/main/service-api.md#amazon-advertising-profiles)

### Account ID

### Advertiser IDS
A stringified array of advertiser IDs.  Self managed acounts can have many advertiser IDs associated with it.  You can provide n number of advertiser IDs.  Amazon Managed IDs only have a single advertiser ID, but it still needs to be strigified array.

### Get Managed Advertiser profile
https://service.api.openbridge.io/service/amzadv/profiles-only/3175?profile_types=dsp&is_manager=true

### Get Non Managed Advertisers
https://service.api.openbridge.io/service/amzadv/list-adv/3175/693136736383016