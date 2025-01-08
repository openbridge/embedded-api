# Amazon Advertising DSP
The Amazon Advertising DSP v3 pipeline subscription creation path is unique in that you can configure one of 2 different types of Ads acounts.  The first are DSP Ads accounts that are manage by the account holder.  We call these `Self-serve Ads Acccounts`.  The second are accounts that are managed entirely by Amazon.  We call these `Managed Ads Accounts`.  Their subscription payloads are similar, but the way to obtain the values for them require different calls to our Service API.


## Table of contents

- [Self-serve Ads Account](#self-serve-ads-accounts)
  - [Self-serve example payload](#self-serve-example-payload)
- [Managed Ads Account](#managed-ads-accounts)
  - [Managed example payload](#managed-example-payload)
- [Subscription Product Meta Attributes definitions](#subscription-product-meta-attributes-definitions)

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
          "unique_hash": "[]"
      }
  }
}
```

## Managed Ads Accounts

The Managed Ads accounts require the following subscription_product_meta_attributes:

|data_key|format|summary|
|-|-|-|
|remote_identity_id|string|The remote identity associated with the DSP account|
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
          "data_key": "account_id",
          "data_value": "ENTITY00000000000",
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
          "data_value": "[\"0000000000000\"]",
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
      "unique_hash": "[]"
    }
  }
}
```
## Subscription Product Meta Attributes definitions

`remote_identity_id`: The remote identity associated with the DSP profile and accounts.

`profile_id`: This field is only required for `self-served` DSP accounts, this will be the Amazon advertising profile associated with the DSP ads account. To retrieve this value a request to the [Amazon Advertising Profile endpoint](https://github.com/openbridge/embedded-api/blob/main/service-api.md#amazon-advertising-profiles) of the Serive API must be made. With profile_types parameter set to `dsp`. 

`account_id`: The DSP account ID. This value required for both types.
  * For Managed accounts a call a request to the [Amazon Advertising Profile endpoint](https://github.com/openbridge/embedded-api/blob/main/service-api.md#amazon-advertising-profiles) of the Serive API must be made. With `profile_types` parameter set to `dsp` and the `managed` parameter set to `true`. The `account_id` in the response is is labled `dsp_advertiser_id`.  In this response the ID is the `account_id` and the `dsp_advertiser_id` will need to be placed in the `advertiser_ids` JSON array.

  ```
  [
    {
        "id": "ENTITYXXXXXXXX",
        "type": "AmazonAdvertisingAccount",
        "attributes": {
            "marketplace_id": "YYYYYYYYYYYY",
            "name": "Advertiser Name",
            "type": "DSP_ADVERTISING_ACCOUNT",
            "profile_id": "",
            "dsp_advertiser_id": "XXXXXXXXXXXXX"
        }
    },
    ...
  ]
  ```

  * For `self served` accounts, a call to the [Amazon Advertising Profile endpoint](https://github.com/openbridge/embedded-api/blob/main/service-api.md#amazon-advertising-profiles) of the Serive API must be made. With `profile_types` parameter set to `dsp`.  The output response will provide both the `profile_id` as the `id` and the `account_id` as  the `account_info.id`.s

  ```
  {
      "data": [
          {
              "id": XXXXXXXXXXXXX,
              "type": "AmazonAdvertisingProfile",
              "attributes": {
                  "country_code": "US",
                  "currency_code": "USD",
                  "daily_budget": "",
                  "timezone": "America/Los_Angeles",
                  "account_info": {
                      "id": "ENTITYXXXXXXXXXXX",
                      "type": "AmazonAdvertisingProfileAccountInfo",
                      "attributes": {
                          "marketplace_country": "US",
                          "marketplace_string_id": "XXXXXXXXXXXXX",
                          "name": "Profile name",
                          "type": "agency",
                          "subType": "",
                          "valid_payment_method": ""
                      }
                  }
              }
          }
      ]
  }
  ```

`managed`: This is a boolean value in string format.  For `managed` accounts the value should be `true`.  For `self-serve` it should be `false`.

`advertiser_ids`: A list of advertiser IDS to collect data for.  The value is a stringified JSON array.  A `self-serve` account can collect data for multiple advertiser IDS.  However a `managed` account can only collect data for that managed account.

  * For `self-served` accounts, a call to the [Amazon Advertising DSP Advertisers](../service-api.md#amazon-advertising-dsp-advertisers) endpoint on the service API will provide a list of available `advertiser_ids` associated with the given profile.

  * For `managed` accounts, please read the above section on `account_id` for `managed` accounts which describes where the adveritiser ID can be found.

`stage_ids`: Stage IDs define what metrics will be collected with the pipeline.  For Amazon Advertising DSP there are over 500 different combinations.  For this reason we provide two endpoints to sort out what data to collect.

  * The [first service api endpoint](../service-api.md#amazon-advertising-dsp-category-to-metrics-map) contains a map of the metric categories and their associated metrics.  You can use this map to build out interfaces to let your customers choose the metrics they desire.

  * The [second service api endpoint](../service-api.md#amazon-advertising-dsp-metric-map-reports) contains a map of of catagory metrics to stage IDS.  Based on the desired metrics for a given category you can find the stage ID that is associated with that report. 