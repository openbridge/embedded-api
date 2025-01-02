# Pipeline Subscription Configuration

## Table of contents
- [Create Piepline Subscription](#create-pipeline-subscription)
- [Limiting collected datasets in subscription](#limiting-collected-datasets-in-subscription)
- [Pausing/Cancelling Pipeline Subscription](#pausing--cancelling-subscription-pipeline)
- [Deleting Pipeline Subscription](#deleting-pipeline-subscription)
- [Updating Pipeline Subscriptions](#updating-pipeline-subscriptions)

<br>
<br>
<br>
<br>

## Create Pipeline Subscription

The process for creating a pipeline subscription is similar for every openbridge product.  Most products require an asscociated identity record.  Most products also require some information from third party APIs such as Amazon or Facebook.  This is why our wizards will always ask for them in that order.

The first step is to decide which product you want to create a pipeline subscription for.  We provide [Comprehensive List](./product-information.md) of products and their associated attributes for this reason.

Some products require information from a third-party API, and others do not.  This needs to be taken into consideration when building a system to create pipeline subscriptions.

An example of a product that doesn't require third-party API calls is the [Amazon Orders API](./product-information.md#amazon-orders-api) product. The reason for this is that Seller Central Identities are a one-to-one relationship with the Amazon Seller account.  

An example of a product that does require a third-party API call would be [Amazon Sponsored Brands](./product-information.md#amazon-advertizing-sbsd).  The reason for this is that Amazon Advertising identities are a one-to-many relationship.  You can have many profiles for one Amazon Advertising Account authentication.  Which means that in order for Openbridge to process data we'd need to know what account profiles to process the data.

Let's build out the payloads for the 2 above products to see how it's done.  We'll need the [Subscription API](./README.md#subscription-api) documentation for reference and grab the base payload.

```json
{
  "data": {
    "type": "string",
    "attributes": {
      "account": "integer",
      "user": "integer",
      "product": "integer",
      "name": "string",
      "status": "string",
      "subscription_product_meta_attributes": "array",
      "remote_identity_id": "integer",
      "unique_hash": "string",
      "storage_group": "integer",
      "quantity": "integer",
      "price": "double",
      "auto_renew": "integer",
      "date_start": "DatetimeString",
      "date_end": "DatetimeString",
      "invalid_subscription": "integer",
      "rabbit_payload_successful": "integer",
      "stripe_subscription_id": "string"
    }
  }
}
```

**Note**: Some of the parameters are depricated but require, please reference the API documentation on what default values to set for these fields.

For the 2 examples we will set both `account` and `user` to the value of `1`. This is the `user id` and `account id` the pipeline subscription will be associated with.  Please make sure to use the `user id` and `account id` associated with your account and user, and we'll also set `storage_group` to `1` as that is going to be the `storage group id` for our subscriptions.  The storage group is a reference destination that your data will be stored in.  In order to get the `storage_group_id` associated with your destinatino you should first query the [subscription API](https://github.com/openbridge/embedded-api/blob/main/README.md#subscription-api) with the subscription ID of the subscription of your destination.

If the subscription ID for your destination was `1000`, then you would do an HTTP get request for that subscription.  Inside the payload is the `storage_group_id`.  Use that for all sources that you want to go to this particular destination. 

### Example 1

We will create a payload to create a `Orders API` source pipeline.  Referencing [Amazon Orders API](./product-information.md#amazon-orders-api) in the documentation we see this is product id `53`.  

We can also see that the `Remote Identity Type ID` is `17`.  Use the [Remote Identity API](./README.md#remote-identity-api) to search for the identity you want to associate with your pipeline subscription.  For this example we'll use identity id `1`.  You should use one assocated with your account.

We need to give it a unique `name`.  The `status` must be defined as `active` (all lowercase characters).

Unique Hash should always be a string with the value of `[]`.

Fields after `unique_hash` are deprecated fields.  Reference the [Payload Attribute Fields](./README.md#payload-attribute-fields) for their defaults.


```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 53,
      "name": "My Orders API Subscription",
      "status": "active",
      "subscription_product_meta_attributes": [],
      "remote_identity_id": 1,
      "unique_hash": "[]",
      "storage_group": 1,
      "quantity": 1,
      "price": 0,
      "auto_renew": 1,
      "date_start": "2024-06-01 00:00:00",
      "date_end":  "2024-06-01 00:00:00",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": ""
    }
  }
}
```

`subscription_product_meta_attributes` is an array of meta attributes required for the subscription to be processed. It will contain an array of objects that with the below schema

```json
{
  "data_key": string,
  "data_value": string,
  "data_format": string,
  "data_id": number,
}
```

Each product will have a different number of objects needed in this array, containing the different information required for them.  In this case we can see from [Amazon Orders API](./product-information.md#amazon-orders-api) that we only need one with the remote identity ID.


```json
{
  "data_key": "remote_identity_id",
  "data_value": "1",
  "data_format": "STRING",
  "data_id": "0",
}
```

**Note**: `data_id` will always be `0` as it is a deprecated field.

The final payload would look like this.

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 53,
      "name": "My Orders API Subscription",
      "status": "active",
      "subscription_product_meta_attributes": [
        {
          "data_key": "remote_identity_id",
          "data_value": "1",
          "data_format": "STRING",
          "data_id": "0",
        }        
      ],
      "remote_identity_id": 1,
      "unique_hash": "[]",
      "storage_group": 1,
      "quantity": 1,
      "price": 0,
      "auto_renew": 1,
      "date_start": "2024-06-01 00:00:00",
      "date_end":  "2024-06-01 00:00:00",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": ""
    }
  }
}
```

### Example 2

We will create a payload to create a `Amazon Advertising Sponsored Ads (v3)` source pipeline.  Referencing [Amazon Orders API](./product-information.md#amazon-orders-api) in the documentation we see this is product id `70`.  

We can also see that the `Remote Identity Type ID` is `14`.  Use the [Remote Identity API](./README.md#remote-identity-api) to search for the identity you want to associate with your pipeline subscription.  For this example we'll use identity id `2`.  You should use one assocated with your account.

Following what we did for `Example 1` will give us the following base payload.


```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 70,
      "name": "My Sponsored Ads V3 Subscription",
      "status": "active",
      "subscription_product_meta_attributes": [
        {
          "data_key": "remote_identity_id",
          "data_value": "1",
          "data_format": "STRING",
          "data_id": "0",
        }
        {
          "data_key": "profile",
          "data_value": "XXXXXXX",
          "data_format": "STRING",
          "data_id": "0",
        }       
      ],
      "remote_identity_id": 2,
      "unique_hash": "[]",
      "storage_group": 1,
      "quantity": 1,
      "price": 0,
      "auto_renew": 1,
      "date_start": "2024-06-01 00:00:00",
      "date_end":  "2024-06-01 00:00:00",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": ""
    }
  }
}
```

Now to build out the meta attributes in [Sponsored Ads (v3)](./product-information.md#amazon-sponsored-ads-v3) section.  You will see that we need a `remote_identity_id` and a `profile_id` which is an `Amazon Advertising` profile id.

[Sponsored Ads (v3)](./product-information.md#amazon-sponsored-ads-v3) has instructions and links to the API documentation on what endpoint to use to get this value.

## Limiting collected datasets in subscription.

You might find a need to limit what datasets you are collecting.  You may only need the data in one dataset, or you may be hitting API rate limits from one of the third party APIs used to collect data.  The method to limit what data is collected you must first use the service API to find out what `stages` are available for products from the [Service API Product Stage ID endpoint](https://github.com/openbridge/embedded-api/blob/main/service-api.md#product-stage-id).

Once you know the stage IDs that you want to limit your subscription too you must create a stringified JSON array and pass it along in the SPM for the subscription. 

Let's revisit example 1 from the creation process.  To limit the stages we add it to the SPM, setting the data_format to JSON and creating a stringified array.

```json
{
  "data": {
    "type": "Subscription",
    "attributes": {
      "account": 1,
      "user": 1,
      "product": 53,
      "name": "My Orders API Subscription",
      "status": "active",
      "subscription_product_meta_attributes": [
        {
          "data_key": "remote_identity_id",
          "data_value": "1",
          "data_format": "STRING",
          "data_id": "0",
        },
        {
          "data_key": "stage_ids",
          "data_value": "[XXXXX,YYYY,ZZZZZ]",
          "data_format": "JSON",
          "data_id": "0",
        }                    
      ],
      "remote_identity_id": 1,
      "unique_hash": "[]",
      "storage_group": 1,
      "quantity": 1,
      "price": 0,
      "auto_renew": 1,
      "date_start": "2024-06-01 00:00:00",
      "date_end":  "2024-06-01 00:00:00",
      "invalid_subscription": 0,
      "rabbit_payload_successful": 0,
      "stripe_subscription_id": ""
    }
  }
}
```

This tells the task manager what datasets to collect. If you have older subscriptions that don't have stage_ids in the SPM, you can retroactively go back and edit them and add the stage_ids you want to collect for.

## Pausing/Cancelling Pipeline Subscription

If you want to turn off a pipeline either permentantly or temporarily you need change the status of the record on file.  This is done with a patch request. Through the [Subscription API](#subscription-api) and is described in our API documentation.

## Deleting Pipeline Subscription.

Pipeline Subscriptions are not deletable through the API.  Nor are they deletable through the Openbridge App.  Instead you must use the `PATCH` functionality to mark their status as `invalid`.  Once they are marked as `invalid` you will no longer see them in the Openbridge app interface. Pipeline subscriptions marked as `invalid` can be set to `active` or `cancelled` as long as there are no duplicate subscriptions that are in an `active` or `cancelled` status.

## Updating Pipeline Subscriptions
If you want to update an attribute of a pipeline subscription, you can use a PATCH request using the [Subscription API](#subscription-api) as described in our API documentation.  It is important to note that when sending a PATCH request to the subscription API update that you always include the `status` field as part of the PATCH request.  Even if the `status` isn't changing.

For example if you want to update the `stage_ids` subscription_product_meta attribute to limit or increase the data you are receiving the payload would be as below.

Make sure the XX is the product ID of the product used in the subscription.

```
{
  "data": {
     "id": "XXXX"
     "type": "Subscription",
     "attributes": {
       "status": "active",
       "subscription_product_meta_attributes": [
        {
          "data_key": "stage_ids",
          "product_id": "XX"
          "data_value": "\[\"XXXX\",\"YYYY\",\"ZZZZZ\"\]",
          "data_format": "STRING",
          "data_id": "0",
        }
       ]
     }
  }
}
```