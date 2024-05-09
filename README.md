# Openbridge API Documentation

Welcome to the Openbridge API documentation. This guide is designed to help developers understand, integrate, and embedd the Openbridge API into their applications. Whether you're looking to access specific data, manage identities, or handle authorizations, you'll find detailed information and examples here.

- [Getting started](#getting-started)
  - [How do I get access to Openbridge APIs?](#how-do-i-get-access-to-openbridge-apis)
  - [API User Role](#api-user-role)
  - [Refresh Tokens](#refresh-tokens)
- [Identity Authorization](#identity-authorization)
  - [Creating your first identity](#creating-your-first-identity)
  - [Identity State](#identity-state)
    - [Account and User Ids](#account-and-user-ids)
    - [Identity Types](#identity-types)
    - [Region](#region)
      - [Amazon Advertising Regions](#amazon-advertising-regions)
      - [Amazon Selling Partner and Vendor Central Regions](#amazon-selling-partner--vendor-central-regions)
    - [Redirect URL](#redirect-url)
    - [Shop URL](#shop-url)
  - [Creating your first state object](#create-your-first-state-object)
  - [Starting the authorization process](#starting-the-authorization-process)
- [Requesting History](#history-requests)


- [APIs](#apis)
  - [Authorization API](#authorization-api)
  - [Account API](#account-api)
  - [Service API](./service-api.md)
  - [Remote Identity API](#remote-identity-api)
  - [Subscription API](#subscription-api)
  - [State API](#state-api)

 - [Product Information](./product-information.md)

 - [Best Practices](#best-practices)
  - [Identity Health](#identity-health)


# Getting Started

## How do I get access to Openbridge APIs?
To get access to use the Openbridge APIs requires a discussion with the Openbridge support.  Please contact us via the official support portal to request access.

## API User Role
Customers who have been granted access to use the Openbridge APIs will be given the `api-user` role to the owner of the account.  Once Openbridge support has said that this role has been added to your account you will need to log out of the Openbridge app and then log back in.  This updates any cached token in the browser with a new one with the required permissions to generate a refresh token for your account.

## Refresh Token
A refresh token is a long lived token that your application will use to generate a JWT using the openbridge authorization API.  To create a refresh token you must have been granted the `api-user` role on your account.  If you have this role, log into the Openbridge app. In the main menu and select `Account` and you will be presented with a `API Management` menu option to navigate you to the refresh token management page.  Click on the `"Create Refresh Token"` button.  A modal will present itself where you will need to choose a name for the token.  Click the `Create` button and your token will be generated, and presented to you.  It is **VERY IMPORTANT** that you copy this token and store it in a text file, or in your application preferences/settings.  As a security precaution we will not present this token to you again, as it is not stored in a way we can present it to you again.  If you lose your token you will be required to generate a new one.


# Identity Authorization

Openbridge call authorizations we have made to third party vendors identities.  In most cases these third party authorizations are created through the third party's Oauth service.  Openbridge has created our own API that manages redirecting a user to these APIs and on a successful authorization a return to a specific `return_url` with some included meta data stored in the query string.  In most cases on an error the user is also redirected back to the return_url with some meta data that specifies the error condition.  However due to the way some of the third party APIs handle errors, sometimes a user can result in being dead ended at on a page hosted by the third party.  There is unfortunately nothing that can be done in those cases, but to document it.

## Creating your first identity


### Identity State

The first step in creating an identity is to create a persistent state using the Openbridge [state api](#state-api).  The Oauth standard has us pass a state token at the beginning of their process.  This allows us to retain state from the beginning of the process through the end of the process as on the return the state token is given back to us.

The schema for the state to create an identity is:

> ```json
>  {
>     account_id: string;
>     user_id: string;,
>     region: string;
>     remote_identity_type_id: integer;
>     return_url: string;
>     shop_url: string | null;
>   }
> ```

#### Account and User IDs

The `account_id` and the `user_id` can be retrieved using the [Account API](#account-api). The `account_id` will be the `data.id` on the response tree, and the `user_id` will be `data.attributes.owner.id` on the response tree.

#### Region

Every Oauth API is different.  For example Amazon break up their authorizations by region.  This means they have different Oauth servers in various parts of the world.  However Facebook and Google, their authorizations are `global`.  The regions are indexed below for each identity type.  

#### Identity Types


Openbridge offers connections to several third parties. Internally we call these `remote identity types` and we have an id that we associate with each of them.

> | id              |  provider     | region |
> |-------------------|-----------|----------|
> | `1` |      Google (except for Adwords) | global |
> | `2` |      Facebook | global |
> | `8` |      Google Adwords | global |
> | `14` |      Amazon Advertising | [region index](#amazon-advertising-regions)  |
> | `17` |      Amazon Selling Partner | [region index](#amazon-selling-partner--vendor-central-regions) |
> | `18` |      Amazon Vendor Central | [region index](#amazon-selling-partner--vendor-central-regions) |


#### Amazon Advertising Regions
---
> | region identifier              |  region name |
> |-------------------|-----------|
> | `na` |      `North America` |
> | `eu` |      `Europe` |
> | `fe` |      `Far East` |


#### Amazon Selling Partner &amp; Vendor Central Regions
---
> | region identifier              |  region name |
> |-------------------|-----------|
> | `AU` | `Australia` |
> | `BR` | `Brazil` |
> | `CA` | `Canada'` |
> | `EG` | `Egypt` |
> | `FR` | `France` |
> | `DE` | `Germany` |
> | `IN` | `India` |
> | `IT` | `Italy` |
> | `JP` | `Japan` |
> | `MX` | `Mexico` |
> | `NL` | `Netherlands` |
> | `PL` | `Poland` |
> | `SA` | `Saudi Arabia` |
> | `SG` | `Singapore` |
> | `ES` | `Spain` |
> | `SE` | `Sweden` |
> | `TR` | `Turkey` |
> | `UK` | `United Kingdom` |
> | `AE` | `United Arab Emirates (U.A.E.)` |
> | `US` | `United States` |

#### Redirect URL
Whether the identity is created successfully, or an error happens in the process, the oauth API needs to know where to return the end user too.  We store this in the state, it allows for greater flexibility in app creation, since you aren't tied to returning a user to a single location. Openbridge for example redirects users to the wizard they started on.  We include a parameter to indicate what stage of the wizard the user was last on.


#### Shop URL
The `shop_url` is only used in conjunction with shopify identities.  Currently we do not support the creation of Shopify authenticated identities for our API users at this time.


### Create your first state object
With these in mind, let's create a state that can be used for gaining an authorization for Amazon Selling Partner API, We'll do it for account 1, that is owned by user 1.  (Don't really do this it is only for example, please use your own user and account id, you can use the [Account API](#account-api) to retrieve them.).  We will do it for the `US` region. We'll then return them to the Openbirdge wizard for the Selling Partners "Orders API" product, and we'll pass the stage parameter so we land on the identity selection page.

> ```json
>  {
>     "account_id": "1";
>     "user_id": "1";,
>     "remote_identity_type_id": 17;
>     "region": "US;
>     "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity"
>     "shop_url": null;
>   }
> ```


Now that we have the state object, we need to generate a payload for the [state API](#state-api) with it.  We add it to the payload as the `state` attribute.

> ```json
> {
> 	"data": {
> 		"type": "ClientState",
> 		"attributes": {
> 			"state": {
> 				"account_id": "1",
> 				"user_id": "1",
> 				"remote_identity_type_id": 17,
> 				"region": "US",
> 				"return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity",
> 				"shop_url": null
> 			}
> 		}
> 	}
> }
> }
> ```

Our curl request for testing looks like this.

>```
> curl -H "Content-Type: application/json" -X POST -d '{ "data": { "type": "ClientState", "attributes": { "state": { "account_id": "1", "user_id": "1", "remote_identity_type_id": 17, "region": "US", "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity", "shop_url": null } } } }' https://state.api.openbridge.io/state/oauth
>```

And upon execution our response is

> ```json
> {
>   "data": {
>     "type": "ClientState",
>     "id": "36613eebc2b09e4ec36663ebdf647658",
>     "attributes": {
>       "token": "36613eebc2b09e4ec36663ebdf647658",
>       "created_at": "2023-01-26T14:29:09.996295",
>       "modified_at": "2023-01-26T14:29:09.996327",
>       "state": {
>         "account_id": "1",
>         "user_id": "1",
>         "remote_identity_type_id": 17,
>         "region": "US",
>         "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity",
>         "shop_url": null
>       }
>     }
>   }
> }
> ```

You can see that the output is much like the input, except we have been given `created_at` and `modified_at` data, and the `id` and `token` which should always be the same thing.  What we really care about is the `id`/`token`.  This is the value that will represent our calls to the third party oauth APIs.

### Starting the authorization process

To start the authorization process simply redirect the user in the browser to the Oauth API's initialize URL along with the state token.

> ```bash
> https://oauth.api.openbridge.io/oauth/initialize?state=XXXXXXXXXXXXXXXXXXXXXXXXXXXX
> ```

#### Security Note (MUST READ).
The OAuth API is called via a redirect in the browser.  It should **NEVER** be called in a frame or iframe element withing HTML in the browser.  Many OAuth providers disable this as it is a [clickjacking security risk](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-23#section-10.13).  All of the providers Openbridge uses have disabled it.  Popups may work on some third parties, but it is **not** supported by Openbridge.

Once the user is directed to the Openbridge Oauth api, the state is read based on the passed in state token.  Based on the `remote_identity_type_id` in the state the end user will be redirected to the correct oauth provider.  In our example that is Amazon Selling Partner.  Once the user completes the process they are returned back to the Openbridge oauth api, where the identity information is stored in the openbridge database, and the end user is then redirected to the return_url that was created in the state.  In our case the blow URL along with some additional query string parameters.

> ```bash
> https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity&state=
> ```

#### Additional Oauth return parameters
---
> | key  |  datatype | description |
> |-------------------|-----------|-|
> | `state` | `string` | The state id/token we passed during the initialization process.
> | `ri_id` | `integer` | The id of the created/reauthorized identity.
> | `reauth` | `boolean` | Whether this is a new identity in the openbridge database or a reauthorization of an existing identity identity.  An identity can be new to a user/account but not to our database.  It is possible for 2 accounts to have the same identity associated with it.  We call these shared identities.
> | `status` | `string` | returned when an error is present, it's value should always be `error`.
> | `status_message` | `string` | The message related to the status, in this case it is an error message.

In the case of the `status` key, you should check for the value to be error, as in the future this field may be expanded on.  Don't rely simply on it's existence for error handling.

When an identity is successfully created you can use the [identities API](#remote-identity-api) to query it.

**Note** The process for reauthorizing an identity is exactly the same as creating one.  In the case of a reauth we return parameter `reauth` in the querystring.

# History Requests

After creating a pipeline subscription you may want to back fill past history into your database.  This can be done with using the history API endpoints.  There are 3 different endpoints that are linked to history requests.  The first two provide meta data used in making the actual request. Those are the [History Max Requests](https://github.com/openbridge/embedded-api/blob/main/service-api.md#history-max-requests) endpoint and the [Product Payloads](https://github.com/openbridge/embedded-api/blob/main/service-api.md#product-payloads) endpoint. Lastly there is the endpoint for making the request [History Request](https://github.com/openbridge/embedded-api/blob/main/service-api.md#history-create-request) endpoint.

## Basic History Request.

Making a basic history requests uses 2 of the 3 endpoints.  The [History Max Requests](https://github.com/openbridge/embedded-api/blob/main/service-api.md#history-max-requests) endpoint and the [History Request](https://github.com/openbridge/embedded-api/blob/main/service-api.md#history-create-request) endpoint.

The purpose of the History Max Request endpoint is to provide details reguarding how far back in the past you can go to request.  This data contains a list for all products, and is slow changing.  Since it is slow changing, this is an example of a request that the data could be cached locally for short periods of time.  We recommend not caching it for more than 24hrs at a time. 

Using the request below along with your authorizatino token you will be given a list of all Openbridge products that support history requests, along with meta data needed to make those history requests.

> ```curl
>  curl -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" -X GET  https://service.api.openbridge.io/service/history/production/history/meta/max-request
> ```

The response will be an array of product history meta data like below.

>```
>{
>  "data": [
>    {
>      "id": 57,
>        "attributes": {
>        "max_request_time": 90,
>        "max_days_per_request": 88,
>        "base_request_start": 2
>      }
>    },
>      ...
>  ]
>}
>```

Take the example above for product 57.  There are 3 meta attributes.  The first is **max_request_time**.  The value to this key is the maximum number of days you can request history for.  The second **max_days_per_request** is the maximum number of days you can request history for per request.  Lastly **base_request_start** is the offset in days from the time the request is being made that history can not be requested for.

Example.  You have a subscription for product 57.  Today is May 1st 2024.  Since this product has a `base_request_start` of `2` it means that `start_date` in the history request can be no sooner than `2 days in the past`.  Therefore, in this instance  The `start_date` can be no sooner than April 29, 2024.  With a `max_request_time` of 90 means that the `end_date` date in the history request can be no further back than 90 days.  In our case 90 days before May 1st 2024 is February 1st 2024.  This is the last date that we can request data for if requesting it on May 1st, 2024.  This means you can request a maximum of 88 days worth of data.

Once you have calculated your `start_date` and your `end_date` you can build a payload for your history requeset.  Using the above as our example our payload would look something like.

**Note:** all `date` should be calculated for UTC.

> ```json
> {
>   "data": {
>     "type": "HistoryTransaction",
>     "attributes": {
>       "start_date": "2024-04-29",
>       "end_date": "2024-02-01"
>      }
>   }
> }
> ```

The `start_date` is the date closest to the date you are making your request on, and the `end_date` is the calculated date in the past X number of days, in our case 88 days.

Posting this payload to  `https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}` with the subscription ID as a parameter will create the history request.


## Advanced History Request.

There is sometimes specific data that you may want to prioritize being loaded first.  The history request payload has 2 optional fields that must be used together when requesting these.  `stage_id` and `start_time`.

To get a list of `stage_id`s for a given product you need to use the **Product Payloads** endpoint.

> ```curl
>  curl -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" -X GET  https://service.api.dev.openbridge.io/service/products/production/product/{{product_id}}/payloads?stage_id__gte=1000
> ```

Making a request to this endpoint will give you a list of stages for for a given product.  Some products may have only 1 stage, some 10.  Using our example for product 57.

>```JSON
>{
>  "links": {
>    "first": "https://55anmbidzh.execute-api.us-east-1.amazonaws.com/product/57/payloads?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855&X-Amz-Credential=ASIAVIA2REQV3GMWZ76G%2F20240508%2Fus-east-1%2Fexecute-api%2Faws4_request&X-Amz-Date=20240508T132023Z&X-Amz-Expires=300&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJT%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJGMEQCIBaDZdHncY%2FxMZm1mUMmR2hxr4j9YepYeqb8EcTOXOM8AiAZc%2FdNPaXzuy5WQTxaqp5M5Tiaabg%2FpwKuHBMmsx787ir7Agjt%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAAaDDM2MDgzMjkwMjE4NyIMjGVeYVqEeH5RgvvtKs8CZKysCemifK0yFjaBQDoUB1vRwGfhV5qb9iCtQ2rF9ruoho%2FlViIZHIHeqd9uV%2BMEChB7kTa9%2Bi5UR%2B5xu4YQQL6el6dcz6%2Fn6mNtQIrtqZMVFWrB6c68u%2BYh3ggUKnx6UZSdU0zWkCQJ7%2BCWZI1q8Q3%2BUyMv6j4WdANf9tzfDGCQ7yxdbkBRS8JcrgQ8sfBOBXmhcIHGlHYma1dQRGPDOxAaxshEEgoQWgr3y6CZ3NKHJq0UssKqmsPO7cQIzvvrxZU2wiEApWx8ABNtRcv0cgNUqclvGKiCI0rknkv6jdCK%2BYk4Q%2BmPpxEPr8G0ZoqImD4QhkpPgtA1Iv17aFrwSZ0%2Fgm457yo5KY9zw1gqauEf1TErx3vJjSDyzT%2FUewT0wn%2BNbLtej2vdGBSEQubuooCFu8bBU1xk%2BPz8ePU3P0skVUBcvgUU%2FX44JQod4Nswqc3tsQY6nwFli4si8b1ZOl0Cnc9xMmGZYt8gytcPAir9890jXFAfoz4t4yPyNMZ0eJu%2BUOc1t7yHOGXFL2SvIsvgWA00bBLPIXyMb4IYqXygGWguni1nnr72Gn%2BmG7tMzZGYt4PIwNby%2FSAUCEzEDnpfpztvZ3Bls%2FeGHOmLx%2FcI%2FP0GR8zIk7MpocVvtNiKuv0AJwfZIUX69uZwmfc1320Yu4ZGh1E%3D&X-Amz-Signature=b6b1759feb329196244134b9acfb5bef944f951aa1771243a9ac989b6411d18d&X-Amz-SignedHeaders=host&page=1&stage_id__gte=1000",
>    "last": "https://55anmbidzh.execute-api.us-east-1.amazonaws.com/product/57/payloads?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855&X-Amz-Credential=ASIAVIA2REQV3GMWZ76G%2F20240508%2Fus-east-1%2Fexecute-api%2Faws4_request&X-Amz-Date=20240508T132023Z&X-Amz-Expires=300&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJT%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJGMEQCIBaDZdHncY%2FxMZm1mUMmR2hxr4j9YepYeqb8EcTOXOM8AiAZc%2FdNPaXzuy5WQTxaqp5M5Tiaabg%2FpwKuHBMmsx787ir7Agjt%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAAaDDM2MDgzMjkwMjE4NyIMjGVeYVqEeH5RgvvtKs8CZKysCemifK0yFjaBQDoUB1vRwGfhV5qb9iCtQ2rF9ruoho%2FlViIZHIHeqd9uV%2BMEChB7kTa9%2Bi5UR%2B5xu4YQQL6el6dcz6%2Fn6mNtQIrtqZMVFWrB6c68u%2BYh3ggUKnx6UZSdU0zWkCQJ7%2BCWZI1q8Q3%2BUyMv6j4WdANf9tzfDGCQ7yxdbkBRS8JcrgQ8sfBOBXmhcIHGlHYma1dQRGPDOxAaxshEEgoQWgr3y6CZ3NKHJq0UssKqmsPO7cQIzvvrxZU2wiEApWx8ABNtRcv0cgNUqclvGKiCI0rknkv6jdCK%2BYk4Q%2BmPpxEPr8G0ZoqImD4QhkpPgtA1Iv17aFrwSZ0%2Fgm457yo5KY9zw1gqauEf1TErx3vJjSDyzT%2FUewT0wn%2BNbLtej2vdGBSEQubuooCFu8bBU1xk%2BPz8ePU3P0skVUBcvgUU%2FX44JQod4Nswqc3tsQY6nwFli4si8b1ZOl0Cnc9xMmGZYt8gytcPAir9890jXFAfoz4t4yPyNMZ0eJu%2BUOc1t7yHOGXFL2SvIsvgWA00bBLPIXyMb4IYqXygGWguni1nnr72Gn%2BmG7tMzZGYt4PIwNby%2FSAUCEzEDnpfpztvZ3Bls%2FeGHOmLx%2FcI%2FP0GR8zIk7MpocVvtNiKuv0AJwfZIUX69uZwmfc1320Yu4ZGh1E%3D&X-Amz-Signature=b6b1759feb329196244134b9acfb5bef944f951aa1771243a9ac989b6411d18d&X-Amz-SignedHeaders=host&page=1&stage_id__gte=1000",
>    "next": "",
>    "prev": ""
>  },
>  "data": [
>    {
>      "type": "Product",
>      "id": "2958",
>      "attributes": {
>        "name": "sp_settlements",
>        "created_at": "2024-05-03T13:36:40.156426",
>        "modified_at": "2024-05-03T13:36:40.185841",
>        "stage_id": 1000
>      }
>    }
>  ],
>  "meta": {
>    "pagination": {
>      "page": 1,
>      "pages": 1,
>      "count": 1
>    }
>  }
>```

Product 57 only has one stage called sp_settlments. Generally it is not necessary to use make an advanced history request when the product only has one stage, but for example simplicity we will mock one for this product.  Taking our payload from the basic history request above we will add the 2 fields needed.  The datetime must be a date in the future at least 15 minutes after the time of submission for history reques.

> ```json
> {
>       "data": {
>         "type": "HistoryTransaction",
>         "attributes": {
>           "start_date": "2024-04-29",
>           "end_date": "2024-02-01",
>           "stage_id": 1000,
>           "start_time": "2024-04-29 00:00:00"
>         }
>       }
>     }
> ```

**Note:** All `date` and `datetime` fields should be calculated for UTC.


# APIs

### Deprecated key-value pairs in requests and response

In the API you will see note to items that are marked as deprecated.  You will be required to include many of them as inputs to `POST` functionality, and receive them as part of the output, but you should not rely on the output in the future, as they will be removed in the future.


## Authorization API

A prerequisite to most of the Openbridge APIs is to generate a JWT from a refresh token using the Openbridge Authorization API.

<details>
 <summary><code>POST</code> <code><b>https://authentication.api.openbridge.io/auth/api/ref</b></code></summary>

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `202`         | `application/json`        | `Accepted`                                |

##### Example cURL

> ```
> curl --request POST -d '{"data": {"type": "APIAuth","attributes": {"refresh_token": "REFRESH_TOKEN"}}}' https://authentication.api.openbridge.io/auth/api/ref
> ```

##### Example Response

> ```json
> {
>   "data": {
>     "attributes": {
>       "token": "eyXXXXXXXXXXXXXXXXXXXXX",
>       "expires_at": 1674576819.8652437
>     }
>   }
> }
> ```

</details>

## Account API

The openbridge Account API is a RESTFUL API, that supports.  `GET`, `POST` and `PATCH` methods.  However, while the API supports all of these methods, Openbridge customers with the `api-user` role are current restricted to only the `GET` method.  The reason is that their account and user IDs are  prerequisites for many other openbridge APIs therefore we provide `GET` functionality on the account API to fulfill those requisites.

A prerequisite to using the Account API is to create a Openbridge JWT using your account refresh token.

<details>
 <summary><code>GET</code> <code><b>https://account.api.openbridge.io/account</b></code></summary>

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The GET method does not require any parameters. Parameters are based on credentials supplied in the JWT.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Configuration created successfully`                                |

##### Example cURL

> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://account.api.openbridge.io/account
> ```

##### Example Response

> ```json
> {
>  "links": {
>    "first": "https://account.api.openbridge.io/account?page=1",
>    "last": "https://account.api.openbridge.io/account?page=1",
>    "next": "",
>    "prev": ""
>  },
>  "data": [
>    {
>      "type": "Account",
>      "id": "XXXXX",
>      "attributes": {
>        "account_status": 1,
>        "stripe_customer_id": "cus_XXXXXXXXXXXX",
>        "company": "",
>        "created_at": "20XX-XX-XXTXX:XX:XX",
>        "modified_at": "20XX-XX-XXTXX:XX:XX",
>        "free_subscription_limit": 0,
>        "free_subscriptions": 0,
>        "is_branded": 0,
>        "stripe_subscription_id": "sub_XXXXXXXXXXXX",
>        "in_trial": 1,
>        "renews_at_period_end": 0,
>        "period_ends_at": "20XX-XX-XXTXX:XX:XX",
>        "deactivate_at": "20XX-XX-XXTXX:XX:XX",
>        "account_type_id": 13,
>        "country_id": null,
>        "primary_account_address_id": null,
>        "primary_account_card_id": null,
>        "extended_trial": 0,
>        "organization_id": null,
>        "organization_allowed": false,
>        "owner": {
>          "id": "YYYY",
>          "auth0_user_id": "auth0|>636a4261738c1d3f4d57ae6f"
>        }
>      }
>    }
>  ],
>  "meta": {
>    "pagination": {
>      "page": 1,
>      "pages": 1,
>      "count": 1
>    }
>  }
>}
> ```

From the example response, the `accountId` is `data.id` and the `userId` is `data.attributes.owner.id` 

</details>  

## Remote Identity API
The openbridge Remote Identity API is a RESTFUL API, that supports.  `GET`, and `POST` methods.  However, while the API supports all of these methods, Openbridge customers with the `api-user` role are current restricted to only the `GET` method.  Allowing a means to look up state of an identity.  Identity creation is handled through the Oauth API.

<details>
 <summary><code>GET</code> <code><b>https://remote-identity.api.openbridge.io/ri</b><b>/{id}</b></code></summary>

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The GET method does not require any parameters. Parameters are based on credentials supplied in the JWT.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Configuration created successfully`                                |

##### Example cURL

> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://remote-identity.api.openbridge.io/ri/{remite_identity_id}
> ```

The /sri endpoint is used to return a list of all identities that your account has permissions to use.  `sri` stands for `shared remote identities`.  Since there is a chance that an identity can be shared between multiple Openbridge accounts we provide an endpoint to all identities associated to your account, even if it was created by another account previously.

##### Example Response

Returns an array of Remote Identities

> ```json
> [{
>   "data": {
>     "type": "RemoteIdentity",
>     "id": "362",
>     "attributes": {
>       "name": "James Andrews",
>       "created_at": "2018-02-13T18:49:51",
>       "modified_at": "2022-10-26T20:43:21",
>       "identity_hash": "b1e68ff9dca4539522c93f37ff3b9245",
>       "remote_unique_id": "526589612",
>       "account_id": 1,
>       "user_id": 1,
>       "notified_at": null,
>       "invalidate_manually": 0,
>       "invalid_identity": 0,
>       "invalidated_at": "2019-05-11T00:05:01",
>       "notification_counter": 0,
>       "region": "global",
>       "email": "thenetimp+facebook@gmail.com",
>       "oauth_id": null
>     },
>     "relationships": {
>       "remote_identity_type": {
>         "data": {
>           "type": "RemoteIdentityType",
>           "id": "2"
>         }
>       },
>       "account": {
>         "data": {
>           "type": "Account",
>           "id": "1"
>         }
>       },
>       "user": {
>         "data": {
>           "type": "User",
>           "id": "1"
>         }
>       },
>       "trusted_identity": {
>         "data": null
>       },
>       "remote_identity_type_application": {
>         "data": {
>           "type": "RemoteIdentityTypeApplication",
>           "id": "8"
>         }
>       },
>       "oauth": {
>         "data": null
>       }
>     }
>   }
> }]
> ```

### Understanding the response fields

##### Attribute Fields
> | key | data type | description |
> |-|-|-|
> | `name` | `string` | `` |
> | `created_at` | `string` | `` |
> | `modified_at` | `string` | `` |
> | `identity_hash` | `string` | `deprecated` |
> | `remote_unique_id` | `string` | `identifying value from the remote third party Oauth API` |
> | `account_id` | `string` | `The id of the account that first created the identity` |
> | `user_id` | `string` | `The id of the user that first created the identity` |
> | `notified_at` | `string` | `The datetime of the last time the account/user was notified the identity credentials had become invalid.` |
> | `invalidate_manually` | `string` | `deprecated` |
> | `invalid_identity` | `boolean` | `If the identity credentials are currently valid` |
> | `invalidated_at` | `string` | `The datetime that the identity became invalid` |
> | `notification_counter` | `string` | `deprecated` |
> | `region` | `string` | `The region associated with the identity` |
> | `email` | `string` | `The email address associated with the profile by the third party (if available)` |
> | `oauth_id` | `string` | `Association to an Oauth client/id secret for products that require user provided apps, such as Shopify.` |

##### Relationship Fields.
> | key | data type | description |
> |--|--|--|
> | `remote_identity_type` | `object` | `Reference to the remote identity type` |
> | `account` | `object` | `reference to the account` |
> | `user` | `object` | `reference to the user` |
> | `trusted_identity` | `object` | `deprecated` |
> | `remote_identity_type_application` | `object` | `reference to an internal auth application` |
> | `oauth` | `object` | `Association to an Oauth client/id secret for products that require user provided apps, such as Shopify.` |

**Note**:  Identity credentials are not provided via the Remote Identity API

</details>

<details>
 <summary><code>GET</code> <code><b>https://remote-identity.api.openbridge.io/sri</b></code></summary>

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The GET method does not require any parameters. Parameters are based on credentials supplied in the JWT.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Configuration created successfully`                                |

##### Example cURL

> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://remote-identity.api.openbridge.io/identity/{id}
> ```

##### Example Response

> ```json
> {
>   "data": {
>     "type": "RemoteIdentity",
>     "id": "362",
>     "attributes": {
>       "name": "James Andrews",
>       "created_at": "2018-02-13T18:49:51",
>       "modified_at": "2022-10-26T20:43:21",
>       "identity_hash": "b1e68ff9dca4539522c93f37ff3b9245",
>       "remote_unique_id": "526589612",
>       "account_id": 1,
>       "user_id": 1,
>       "notified_at": null,
>       "invalidate_manually": 0,
>       "invalid_identity": 0,
>       "invalidated_at": "2019-05-11T00:05:01",
>       "notification_counter": 0,
>       "region": "global",
>       "email": "thenetimp+facebook@gmail.com",
>       "oauth_id": null
>     },
>     "relationships": {
>       "remote_identity_type": {
>         "data": {
>           "type": "RemoteIdentityType",
>           "id": "2"
>         }
>       },
>       "account": {
>         "data": {
>           "type": "Account",
>           "id": "1"
>         }
>       },
>       "user": {
>         "data": {
>           "type": "User",
>           "id": "1"
>         }
>       },
>       "trusted_identity": {
>         "data": null
>       },
>       "remote_identity_type_application": {
>         "data": {
>           "type": "RemoteIdentityTypeApplication",
>           "id": "8"
>         }
>       },
>       "oauth": {
>         "data": null
>       }
>     }
>   }
> }
> ```

### Understanding the response fields

##### Attribute Fields
These are the same as on a call to a single remote identity.

##### Relationship Fields.
These are the same as on a call to a single remote identity.

**Note**:  Identity credentials are not provided via the Remote Identity API

</details>  

<details>
 <summary><code>DELETE</code> <code><b>https://remote-identity.api.openbridge.io/ri</b><b>/{id}</b></code></summary>

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The DELETE method requires the remote identity ID as part of the reuqest string.

Identities can be shared between more than one Openbridge account.  The DELETE call will remove any association between the calling account and the identity.  If the identity only belongs to the one account it will also delete the identity and any credentials associated with it.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Configuration created successfully`                                |
> | `404`         | `application/json`        | `Not found`                                |

##### Example cURL

> ```curl
>  curl -X DELETE -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://remote-identity.api.openbridge.io/ri/{remite_identity_id}
> ```

</details>


## Subscription API

The openbridge Subscription API is a RESTFUL API, that supports.  `GET`, `POST`, and `PATCH` methods. It is used for creating, retrieving, and updating pipeline subscriptions. 

<details>
 <summary><code>POST</code> <code><b>https://subscriptions.api.openbridge.io/sub</b></code></summary>

The payload schema for creating a Pipeline Subscription is variant on the product associated with the pipeline.  

###### Payload Schema.

> ```json
 >{
 >  data: {
 >    type: string,
 >    attributes: {
 >      account: integer,
 >      user: integer,
 >      product: integer,
 >      name: string,
 >      status: string,
 >      subscription_product_meta_attributes: array,
 >      storage_group: integer
 >      quantity: integer,
 >      price: double,
 >      auto_renew: integer,
 >      date_start: DatetimeString,
 >      date_end: DatetimeString,
 >      invalid_subscription: integer,
 >      rabbit_payload_successful: integer,
 >      stripe_subscription_id: string
 >    }
 >  }
 >}
> ```


##### Payload Attribute Fields

Many of the fields below are deprecated, but must be passed into the payload to create a subscription.  Please follow the informatino in `description` on how to set them properly.

> | key | data type | description |
> |-|-|-|
> | `account` | `string` | `Account ID the subscription will belong to.` |
> | `user` | `string` | `The user ID who created the pipeline` |
> | `product` | `string` | `The product ID for the pipeline` |
> | `name` | `string` | `The user defined name for the pipeline` |
> | `status` | `string` | `The status of the pipeline.  'active', 'cancelled' or 'invalid'. An 'active' state indicates a pipeline subscription that is currently turned on., A 'cancelled' state means that pipeline subscription has been turned off. A 'cancelled' state means that pipeline subscription has been turned off. and can be reactivated by patching an 'active' status. An 'invaid' status marks the pipeline subscription for later deletion.  It is important to not, you must first patch a 'cancelled' status to turn off pipeline subscription jobs. You should never patch a pipeline subscription that is 'active' directly to 'invalid'` |
> | `storage_group` | `integer` | `Storage group record ID attached to the destination subscription you want to store your data in..` |
> | `subscription_product_meta_attributes` | `string` | `The id of the account that first created the identity` |
> | `quantity` | `integer` | `depricated, should always pass '1'` |
> | `price` | `double` | `depricated, should always pass '0.00'` |
> | `auto_renew` | `string` | `deprecated, should always pass '1'` |
> | `date_start` | `string` | `deprecated Current UTC datetime format YYYY-mm-dd HH:mm:ss` |
> | `date_end` | `string` | `deprecated should always be the same value as into date_start` |
> | `invalid_subscription` | `string` | `deprecated, should always pass '0'` |
> | `rabbit_payload_successful` | `string` | `deprecated, should always pass '0'` |
> | `stripe_subscription_id` | `string` | `deprecated, should always pass ''` |
> | `remote_identity_id` | `string` or `null` | `Remote identity connected to the subscription, if none is used, then pass null` |
> | `unique_hash` | `string` | `Internal Use Only: This is a field our web app checks against a cached value for duplicates.  The generation of this hash is complex.  Please pass a string containing [] as the value.  This represents an empty stringified JSON array.` |

##### Subscription Product Meta
The base object for all subscriptions are the same. This makes it easy to templatize.  Each product has different "meta" associated with it. In the call to create a subscription you must pass along the correct parameters as part of the `subscription_product_meta` array.  A subscription product meta object within the context of a subscription creation post has a schema that like this:

> ```json
> {
>   data_id: 0,
>   data_key: 'remote_identity_id',
>   data_value: configState.remoteIdentityId,
>   data_format: 'STRING',
>   product: productId
> }
> ```

> | key | data type | description |
> |-|-|-|
> | `data_id` | `integer` | `deprecated: must always pass '0'` |
> | `data_key` | `string` | `The key part of the key value pair` |
> | `data_value` | `string` | `The value part of the key value pair` |
> | `data_format` | `string` | `Used to tell the processor what is in data_value.  Accepted values are 'STRING', 'ENCRYPTED_STRING', 'JSON', 'ENCRYPTED_JSON'` |
> | `product` | `integer` | `The product id, should be the same as the subscription product id.` |

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Content-Type      |  string  | application/json
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The POST method does not require any parameters. 

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `20`         | `application/json`        | `Created`                                |

##### Example cURL

This is an example for creating a Selling Partner Orders API subscription.

> ```json
>  {
>    "data": {
>      "type": "Subscription",
>      "attributes": {
>        "account": XXXXX,
>        "user": YYYYY,
>        "product": 53,
>        "name": "My unique subscription name",
>        "status": "active",
>        "quantity": 1,
>        "price": 0,
>        "auto_renew": 1,
>        "date_start": "2023-02-01 00:00:01",
>        "date_end": "2023-02-01 00:00:01",
>        "invalid_subscription": 0,
>        "rabbit_payload_successful": 0,
>        "stripe_subscription_id": "",
>        "storage_group": ZZZZ,
>        "remote_identity": AAAA,
>        "unique_hash": "[\"XXXXXXXXXXXXXXXXXXXXXXX\"]",
>        "subscription_product_meta_attributes": [
>          {
>            "data_key": "remote_identity_id",
>            "data_value": "AAAA",
>            "data_id": 0,
>            "data_format": "STRING",
>            "product": 53,
>          }
>        ]
>      }
>    }
>  }
> ```

It only requires one `subscription_product_meta` object and that is the `remote_identity_id`.  You may ask, why is it being passed as both an spm and in the main body of the subscription.  This is due to legacy constraints of the processing system, and some requirements of another internal system.


> ```curl
>  curl -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX"  -X POST -d '{ "data": { "type": "Subscription", "attributes": { "account": XXXXX, "user": YYYYY, "product": 53, "name": "My unique subscription name", "status": "active", "quantity": 1, "price": 0, "auto_renew": 1, "date_start": "2023-02-01 00:00:01", "date_end": "2023-02-01 00:00:01", "invalid_subscription": 0, "rabbit_payload_successful": 0, "stripe_subscription_id": "", "storage_group": ZZZZ, "remote_identity": AAAA, "unique_hash": "[\"20230201000000\"]", "subscription_product_meta_attributes": [ { "data_key": "remote_identity_id", "data_value": "AAAA", "data_id": 0, "product": 53 }]}}}' https://subscriptions.api.openbridge.io/sub
> ```

##### Example Response

The response will contain many deprecated fields, and will not include the `subscription_product_meta` array.  There will be a list of deprecated fields after the example

> ```json
> {
>   "data": {
>     "type": "Subscription",
>     "id": "XXXXX",
>     "attributes": {
>       "price": 0.0,
>       "status": "active",
>       "date_start": "2023-01-31T11:54:45",
>       "date_end": "2023-01-31T11:54:45",
>       "auto_renew": 1,
>       "created_at": "2023-01-31T11:54:48.889618",
>       "modified_at": "2023-01-31T11:54:48.889633",
>       "quantity": 1,
>       "stripe_subscription_id": "",
>       "name": "Openbridge Orders ",
>       "rabbit_payload_successful": 0,
>       "primary_job_id": null,
>       "pipeline": null,
>       "invalid_subscription": 0,
>       "invalidated_at": null,
>       "notified_at": null,
>       "canonical_name": null,
>       "account_id": XXX,
>       "product_id": 53,
>       "product_plan_id": null,
>       "remote_identity_id": AAA,
>       "storage_group_id": ZZZ,
>       "user_id": YYY,
>       "history_requested": 0,
>       "unique_hash": "[\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"]"
>     },
>     "relationships": {
>       "account": {
>         "data": {
>           "type": "Account",
>           "id": "342"
>         }
>       },
>       "product": {
>         "data": {
>           "type": "Product",
>           "id": "2"
>         }
>       },
>       "product_plan": {
>         "data": null
>       },
>       "remote_identity": {
>         "data": {
>           "type": "RemoteIdentity",
>           "id": "364"
>         }
>       },
>       "storage_group": {
>         "data": {
>           "type": "StorageGroup",
>           "id": "245"
>         }
>       },
>       "user": {
>         "data": {
>           "type": "User",
>           "id": "309"
>         }
>       }
>     }
>   },
>   "included": [
>     {
>       "type": "StorageGroup",
>       "id": "245",
>       "attributes": {
>         "product_id": 37,
>         "name": "asdfasdfads",
>         "key_name": "984e7c5f47fea2a0-asdfasdfads"
>       }
>     }
>   ]
> }
> ```

###### Attribute Keys

> | name | data type | description |
> |-|-|-|
> | `price` | `double` | `` |
> | `status` | `string` | `` |
> | `date_start` | `datetime string` | `` |
> | `date_end` | `datetime string` | `` |
> | `auto_renew` | `booelean integer` | `depricated` |
> | `created_at` | `string` | `Datetime the pipeline was created` |
> | `modified_at` | `string` | `Datetime the pipeline was last modified` |
> | `quantity` | `integer` | `deprecated` |
> | `stripe_subscription_id` | `string` | `` |
> | `name` | `string` | `string` |
> | `rabbit_payload_successful` | `integer` | `Deprecated` |
> | `primary_job_id` | `integer` | `Deprecated` |
> | `pipeline` | `string` or `null` | `Deprecated` |
> | `invalid_subscription` | `null` | `Deprecated` |
> | `invalidated_at` | `null` | `Deprecated` |
> | `notified_at` | `null` | `Deprecated` |
> | `canonical_name` | `string` | `Deprecated` |
> | `account_id` | `integer` | `Account id the pipeline subscription is associated with` |
> | `product_id` | `integer` | `Product id the pipeline subscription is associated with` |
> | `product_plan_id` | `integer` | `Deprecated` |
> | `remote_identity_id` | `integer` or `null` | `The remote identity id the pipeline subscription is associated with` |
> | `storage_group_id` | `integer` | `The storage group id where the collected data is stored.` |
> | `user_id` | `string` | `The user id that the subscription pipeline is associated with` |
> | `history_requested` | `string` | `Deprecated` |
> | `unique_hash` | `string` | `A required unique hash of the subscription product meta key value pairs` |


</details>

<details>
 <summary><code>GET</code> <code><b>https://subscriptions.api.openbridge.io/sub</b><b>/{id}</b></code></summary>

##### Parameters

> | name              |  required     | data type      | description                         |
> |-------------------|-----------|----------------|-------------------------------------|
> | `id` |  `yes` | `string`   | `The id of the desired subscription record`    |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `OK`                                |

##### Example cURL

This example holds the state that is needed during the Oauth request for a Facebook identity

> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://subscriptions.api.openbridge.io/sub/{id}'
> ```

##### Example Response

The response includes the id/token and the timestamps the state was created at. This is the same as the response received from a POST call above.  Assuming we requested it's token.  The response is that of a state that holds an object used to create a Facebook identity.

##### Example Response

The response will contain many deprecated fields, and will not include the `subscription_product_meta` array.  

> ```json
> {
>   "data": {
>     "type": "Subscription",
>     "id": "XXXXX",
>     "attributes": {
>       "price": 0.0,
>       "status": "active",
>       "date_start": "2023-01-31T11:54:45",
>       "date_end": "2023-01-31T11:54:45",
>       "auto_renew": 1,
>       "created_at": "2023-01-31T11:54:48.889618",
>       "modified_at": "2023-01-31T11:54:48.889633",
>       "quantity": 1,
>       "stripe_subscription_id": "",
>       "name": "Openbridge Orders ",
>       "rabbit_payload_successful": 0,
>       "primary_job_id": null,
>       "pipeline": null,
>       "invalid_subscription": 0,
>       "invalidated_at": null,
>       "notified_at": null,
>       "canonical_name": null,
>       "account_id": "XXX",
>       "product_id": 53,
>       "product_plan_id": null,
>       "remote_identity_id": "AAA",
>       "storage_group_id": "ZZZ",
>       "user_id": "YYY",
>       "history_requested": 0,
>       "unique_hash": "[\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"]"
>     },
>     "relationships": {
>       "account": {
>         "data": {
>           "type": "Account",
>           "id": "342"
>         }
>       },
>       "product": {
>         "data": {
>           "type": "Product",
>           "id": "2"
>         }
>       },
>       "product_plan": {
>         "data": null
>       },
>       "remote_identity": {
>         "data": {
>           "type": "RemoteIdentity",
>           "id": "364"
>         }
>       },
>       "storage_group": {
>         "data": {
>           "type": "StorageGroup",
>           "id": "245"
>         }
>       },
>       "user": {
>         "data": {
>           "type": "User",
>           "id": "309"
>         }
>       }
>     }
>   },
>   "included": [
>     {
>       "type": "StorageGroup",
>       "id": "245",
>       "attributes": {
>         "product_id": 37,
>         "name": "asdfasdfads",
>         "key_name": "984e7c5f47fea2a0-asdfasdfads"
>       }
>     }
>   ]
> }
> ```
</details>

<details>
 <summary><code>PATCH</code> <code><b>https://subscriptions.api.openbridge.io/sub</b><b>/{id}</b></code></summary>

 The `PATCH` method is used to update the pipeline subscription record.  The schema is similar to that of a `POST` however it must now include the `id`, and it is limited on the fields that can be updated.

##### Patchable Fields

> | name | data type | description |
> |-|-|-|
> | `name` |  `string`   | `The name of the pipeline subscription record`    |
> | `status` |  `string`   | `The status of the pipeline subscription record`    |

The rules for these fields are the same as in the `POST` method.

##### Example Payload

> ```json
> {
>   "data": {
>     "type": "Subscription",
>     "id": "XXXXX",
>     "attributes": {
>       "status": "active"
>     }
>  }
> ```

##### Headers

> | name | data type | description |
> |-|-|-|
> | `Authorization` | `string` | `Openbridge JWT, passed as a  authorization bearer type`
> | `Content-Type` | `string` | `application/json`


##### Parameter

> | name              |  required     | data type      | description                         |
> |-------------------|-----------|----------------|-------------------------------------|
> | `id` |  `yes` | `string`   | `The id of the pipeline subscription record`    |

##### Response

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example holds the subscription patch object to update the status to `cancelled`

> ```curl
>  curl -H "Content-Type: application/json" -H "authorization: Bearer eyJh..."  -X PATCH -d '{"data": { "type": "Subscription", "id": "XXXXXXXX", "attributes": { "status": "cancelled" }}}' https://subscriptions.api.openbridge.io/sub/XXXXXXXX
> ```

##### Example Response

The response is the same as in the `POST` method, with the patched field updated to the new value.

> ```json
> {
>   "data": {
>     "type": "Subscription",
>     "id": "XXXXX",
>     "attributes": {
>       "price": 0.0,
>       "status": "cancelled",
>       "date_start": "2023-01-31T11:54:45",
>       "date_end": "2023-01-31T11:54:45",
>       "auto_renew": 1,
>       "created_at": "2023-01-31T11:54:48.889618",
>       "modified_at": "2023-01-31T11:54:48.889633",
>       "quantity": 1,
>       "stripe_subscription_id": "",
>       "name": "Openbridge Orders ",
>       "rabbit_payload_successful": 0,
>       "primary_job_id": null,
>       "pipeline": null,
>       "invalid_subscription": 0,
>       "invalidated_at": null,
>       "notified_at": null,
>       "canonical_name": null,
>       "account_id": XXX,
>       "product_id": 53,
>       "product_plan_id": null,
>       "remote_identity_id": AAA,
>       "storage_group_id": ZZZ,
>       "user_id": YYY,
>       "history_requested": 0,
>       "unique_hash": "[\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"]"
>     },
>     "relationships": {
>       "account": {
>         "data": {
>           "type": "Account",
>           "id": "342"
>         }
>       },
>       "product": {
>         "data": {
>           "type": "Product",
>           "id": "2"
>         }
>       },
>       "product_plan": {
>         "data": null
>       },
>       "remote_identity": {
>         "data": {
>           "type": "RemoteIdentity",
>           "id": "364"
>         }
>       },
>       "storage_group": {
>         "data": {
>           "type": "StorageGroup",
>           "id": "245"
>         }
>       },
>       "user": {
>         "data": {
>           "type": "User",
>           "id": "309"
>         }
>       }
>     }
>   },
>   "included": [
>     {
>       "type": "StorageGroup",
>       "id": "245",
>       "attributes": {
>         "product_id": 37,
>         "name": "asdfasdfads",
>         "key_name": "984e7c5f47fea2a0-asdfasdfads"
>       }
>     }
>   ]
> }
> ```

</details>


### Selling Partner Product IDs.
---
Openbridge's Selling Partner products all use the same payload, the difference is product ID sent in the subscription object, and in the subscription_product_meta array objects,

> | id | product name |
> |-|-|
> | `53` | `Orders API` |
> | `55` | `Finance Real-Time` |
> | `56` | `Inbound Fulfillment` |
> | `57` | `Settlement Reports` |
> | `58` | `Fulfillment` |
> | `59` | `Inventory Real-Time` |
> | `60` | `Inventory` |
> | `61` | `Sales Reports` |
> | `62` | `Fees` |
> | `64` | `Sales & Traffic` |
> | `65` | `Seller Brand Analytics Reports` |

## State API.

The openbridge State API is a RESTFUL API, that supports.  `GET` and`POST` It is used pass the state of a transaction around to other APIs and applications with an identifying token.  It is a prerequisite to creating Oauth based identities with the Openbridge OauthAPI. 

<details>
 <summary><code>POST</code> <code><b>https://state.api.openbridge.io/state/oauth</b></code></summary>

The payload schema for creating a state token.  The `type` is always `ClientState`.  The object that is passed in the `state` is the data you want stored in the state represented as a JSON object.

###### Payload Schema.

> ```json
> {
>  data: {
>    type: string;
>    attributes: {
>      state: object
>    }
>  }
> }
> ```

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Content-Type      |  string  | application/json

##### Parameters
> The POST method does not require any parameters. 

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `application/json`        | `Created`                                |

##### Example cURL

This example holds the state that is needed during the Oauth request for a Facebook identity

> ```curl
>  curl -H "Content-Type: application/json" -X POST -d '{ "data": { "type": "ClientState", "attributes": { "state": { "account_id": "XXX", "user_id": "YYY", "remote_identity_type_id": 2, "region": "global", "return_url": "https://app.openbridge.com/wizards/facebook-page-insights", "shop_url": null }}}}' https://state.api.openbridge.io/state/oauth
> ```

**Note**: The example payload contains information required by the Openbridge Oauth API to start and manage a Facebook Authorization, but it is not restricted to only those key/value pairs.  You could for example include your own key/value pair to help with maintaining the state of your application through the identity process.

##### Example Response

The response includes the id/token and the timestamps the state was created at.

> ```json
> {
>   "data": {
>     "type": "ClientState",
>     "id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
>     "attributes": {
>       "token": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
>       "created_at": "2023-01-26T11:01:03.918717",
>       "modified_at": "2023-01-26T11:01:03.918793",
>       "state": {
>         "account_id": "XXX",
>         "user_id": "XXX",
>         "remote_identity_type_id": 2,
>         "region": "global",
>         "return_url": "https://app.openbridge.com/wizards/facebook-page-insights",
>         "shop_url": null
>       }
>     }
>   }
> }
> ```

**Note**: From the response the id and Token will always be the same.

</details>

<details>
 <summary><code>GET</code> <code><b>https://state.api.openbridge.io/state</b><b>/{id/token}</b></code></summary>

##### Parameters

> | name              |  required     | data type      | description                         |
> |-------------------|-----------|----------------|-------------------------------------|
> | `id/token` |  `yes` | `string`   | `The id/token of the desired state record`    |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `OK`                                |

##### Example cURL

This example holds the state that is needed during the Oauth request for a Facebook identity

> ```curl
>  curl -X GET https://state.api.openbridge.io/state/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

> ```

##### Example Response

The response includes the id/token and the timestamps the state was created at. This is the same as the response received from a POST call above.  Assuming we requested it's token.  The response is that of a state that holds an object used to create a Facebook identity.

> ``````json
> {
>   "data": {
>     "type": "ClientState",
>     "id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
>     "attributes": {
>       "token": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
>       "created_at": "2023-01-26T11:01:03.918717",
>       "modified_at": "2023-01-26T11:01:03.918793",
>       "state": { }
>         "account_id": "XXX",
>         "user_id": "XXX",
>         "remote_identity_type_id": 2,
>         "region": "global",
>         "return_url": "https://app.openbridge.com/wizards/facebook-page-insights",
>         "shop_url": null
>       }
>     }
>   }
> ```

</details>

# Best Practices

## Identity Health
Identities are the glue keeping your pipeline subscriptions running.  If an authorization attached to an identity is revoked it will cause all pipeline subscriptions attached to it to fail.  To get a better understanding of the concept of identities please read [Understnading Identities](https://docs.openbridge.com/en/articles/3673866-understanding-remote-identities).

Since identiies are so important; Openbridge has a daemon that is set to check identities attached to active subscriptions every 24 hours and send notifications to the affected customers.  As an API user we would send notifications to your primary account manager.  This allows you to reauthorize the identities that lost authorization so that Openbridge can continue to process data for the affected pipelines.

## Retrieving a list of valid or invalid identities
The remote identities API allows you to filter for identities that are valid or invalid. Filters are querystring paramters that are attached to a get call.  In this case we want to filter on the `invalid_identity`.  It is a boolean and can be used as `invalid_identity=1` to get only invalid identities or `invalid_identity=0` to get all valid identities.

When requesting a list of identities you should be using the 'shared remote identities' GET endpoing. 

https://remote-identity.api.openbridge.io/sri?invalid_identity=1

### Failures on your customer's identities
---

 This is an important feature if you are reselling Openbridge services to your own customers.  Since Openbridge has no connection to your customer when our system detects a failed identity we have no way to communicate this failure to them.  As a reseller you should have a system in place that maps an identity with the customer in your app who authorized the identity.  Periodically you should be querying for invalid identities, and when one is detected you should be communicating the failure with your customers so that they can reauthorized the identity.


# Frequently Asked Questions

## How do I determine if an Amazon Seller has a unified or multi-market account?
### GET /sp/marketplaces
To determine if a Seller has a unified account, you can call the API with the remote identity in question. If you get a list of more than one market returned, it is almost certainly a unified/multi-market account. In this case, rather than setting up a subscription for each country, you just needed one for that identity. We are still making a request for each country, but doing so under the unified account.

Here is an example request:
```bash
GET https://service.api.openbridge.io/service/sp/marketplaces/<remote-identity-id>
Authorization: Bearer XXXXX
```
In the response, you can see the list of associated markets:
```json
{
  "data": [
    {
      "id": "X",
      "countryCode": "FR",
      "name": "Amazon.fr",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "fr_FR",
      "domainName": "www.amazon.fr"
    },
    {
      "id": "X",
      "countryCode": "NL",
      "name": "Amazon.nl",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "nl_NL",
      "domainName": "www.amazon.nl"
    },
    {
      "id": "X",
      "countryCode": "PL",
      "name": "Amazon.pl",
      "defaultCurrencyCode": "PLN",
      "defaultLanguageCode": "pl_PL",
      "domainName": "www.amazon.pl"
    },
    {
      "id": "X",
      "countryCode": "GB",
      "name": "Amazon.co.uk",
      "defaultCurrencyCode": "GBP",
      "defaultLanguageCode": "en_GB",
      "domainName": "www.amazon.co.uk"
    },
    {
      "id": "X",
      "countryCode": "DE",
      "name": "Amazon.de",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "de_DE",
      "domainName": "www.amazon.de"
    },
    {
      "id": "X",
      "countryCode": "ES",
      "name": "Amazon.es",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "es_ES",
      "domainName": "www.amazon.es"
    },
    {
      "id": "X",
      "countryCode": "FR",
      "name": "Non-Amazon",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "fr_FR",
      "domainName": "si-prod-fr-marketplace.stores.amazon.fr"
    },
    {
      "id": "X",
      "countryCode": "SE",
      "name": "Amazon.se",
      "defaultCurrencyCode": "SEK",
      "defaultLanguageCode": "sv_SE",
      "domainName": "www.amazon.se"
    },
    {
      "id": "X",
      "countryCode": "TR",
      "name": "Amazon.com.tr",
      "defaultCurrencyCode": "TRY",
      "defaultLanguageCode": "tr_TR",
      "domainName": "www.amazon.com.tr"
    },
    {
      "id": "X",
      "countryCode": "DE",
      "name": "Non-Amazon",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "de_DE",
      "domainName": "si-prod-marketplace-de.stores.amazon.de"
    },
    {
      "id": "X",
      "countryCode": "IT",
      "name": "SI Prod IT Marketplace",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "it_IT",
      "domainName": "siprod.stores.amazon.it"
    },
    {
      "id": "X",
      "countryCode": "ES",
      "name": "SI Prod ES Marketplace",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "es_ES",
      "domainName": "siprod.stores.amazon.es"
    },
    {
      "id": "X",
      "countryCode": "BE",
      "name": "Amazon.com.be",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "fr_BE",
      "domainName": "www.amazon.com.be"
    },
    {
      "id": "X",
      "countryCode": "IT",
      "name": "Amazon.it",
      "defaultCurrencyCode": "EUR",
      "defaultLanguageCode": "it_IT",
      "domainName": "www.amazon.it"
    },
    {
      "id": "X",
      "countryCode": "GB",
      "name": "SI UK Prod Marketplace",
      "defaultCurrencyCode": "GBP",
      "defaultLanguageCode": "en_GB",
      "domainName": "siprodukmarketplace.stores.amazon.co.uk"
    }
  ]
}
```


# Changelog

See the current [CHANGELOG](./CHANGELOG.md) for updates, fixes, and enhancements.



# Docs
For more examples on configuration, guides, and constraints please refer to the docs:
[Openbridge Documentation](https://docs.openbridge.com/)

 If you have not used Openbridge before, you can get a 30-day free trial @ the [Openbridge Website](https://www.openbridge.com). For other guides, tips, or how-to examples, visit us @ the [Openbridge Blog](https://blog.openbridge.com)

# Issues

If you have any problems with or questions about the API, please contact us through a GitHub issue or via the official support portal.

# Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a GitHub issue, especially for more ambitious endeavors. This gives other contributors a chance to point you in the right direction, give you feedback on your approach, and help you find out if someone else is working on the same thing.

# References
* https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-23#section-10.13
* https://developer-docs.amazon.com/sp-api/
* https://advertising.amazon.com/API/docs/en-us/
