# Source Pipeline Subscription

- [Create Pipeline Subscription](#create-pipeline-subscription)
- [Pausing / Cancelling Subscription Pipeline](#pausing--cancelling-subscription-pipeline)
- [Deleting subscription pipeline](#deleting-subscription-pipeline)


## Create Pipeline Subscription

The process for creating a pipeline subscription is similar for every openbridge product.  Most products require an asscociated identity record.  Most products also require some information from third party APIs such as Amazon or Facebook.  This is why our wizards will always ask for them in that order.

The first step is to decide which product you want to create a pipeline subscription for.  We provide [Comprehensive List](./product-information.md) of products and their associated attributes for this reason.

Some products require information from a third-party API, and others do not.  This needs to be taken into consideration when building a system to create pipeline subscriptions.

An example of a product that doesn't require third-party API calls is the [Amazon Orders API](./product-information.md#amazon-orders-api) product. The reason for this is that Seller Central Identities are a one-to-one relationship with the Amazon Seller account.  

An example of a product that does require a third-party API call would be [Amazon Sponsored Brands](./product-information.md#amazon-advertizing-sbsd).  The reason for this is that Amazon Advertising identities are a one-to-many relationship.  You can have many profiles for one Amazon Advertising Account authentication.  Which means that in order for Openbridge to process data we'd need to know what account profiles to process the data.

Let's build out the payloads for the 2 above products to see how it's done.  We'll need the [Subscription API](./README.md#subscription-api) documentation for reference and grab the base payload.

```json
{
  data: {
    type: string,
    attributes: {
      account: integer,
      user: integer,
      product: integer,
      name: string,
      status: string,
      subscription_product_meta_attributes: array,
      remote_identity_id: integer,
      unique_hash: string,
      storage_group: integer,
      quantity: integer,
      price: double,
      auto_renew: integer,
      date_start: DatetimeString,
      date_end: DatetimeString,
      invalid_subscription: integer,
      rabbit_payload_successful: integer,
      stripe_subscription_id: string
    }
  }
}
```

**Note**: Some of the parameters are depricated but require, please reference the API documentation on what default values to set for these fields.

For the 2 examples we will set both `account` and `user` to the value of `1`. This is the `user id` and `account id` the pipeline subscription will be associated with.  Please make sure to use the `user id` and `account id` associated with your account and user, and we'll also set `storage_group` to `1` as that is going to be the `storage group id` for our subscriptions.  The storage group is a reference destination that your data will be stored in.

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


## Pausing / Cancelling Subscription Pipeline.

If you want to turn off a pipeline either permentantly or temporarily you need change the status of the record on file.  This is done with a patch request. Through the [Subscription API](#subscription-api) and is described in our API documentation.

## Deleting Subscription Pipeline.

Pipeline Subscriptions are not deletable through the API.  Nor are they deletable through the Openbridge App.  Instead you must use the `PATCH` functionality to mark their status as `invalid`.  Once they are marked as `invalid` you will no longer see them in the Openbridge app interface. Pipeline subscriptions marked as `invalid` can be set to `active` or `cancelled` as long as there are no duplicate subscriptions that are in an `active` or `cancelled` status.

