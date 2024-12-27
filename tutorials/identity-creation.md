# Table of contents


- [Creating your first identity](#creating-your-first-identity)
  - [Identity State](#identity-state)
    - [Itentity Types](#identity-types)
    - [Amazon Advertising Regions](#amazon-advertising-regions)
    - [Redirect URL](#redirect-url)
  - [Creating a state object](#create-a-state-object)
  - [nitializing the authorization process](#initializing-the-authorization-process)
    - [Security Note (MUST READ)](#security-note-must-read)
    - [Additional Oauth return parameters](#additional-oauth-return-parameters)

<br>
<br>
<br>
<br>


# Creating your first identity

## Identity State
The first step in creating an identity is to create a persistent state using the Openbridge [state api](#state-api).  The OAuth standard has us pass a state token at the beginning of the process.  This allows us to retain the state from the beginning of the process through the end of the process as on the return the state token is given back to us.

The schema for the state to create an identity is:

```json
 {
    account_id: string;
    user_id: string;,
    region: string;
    remote_identity_type_id: integer;
    return_url: string;
    shop_url: string | null;
   }
 ```

The `account_id` and the `user_id` can be retrieved using the [Account API](#account-api). The `account_id` will be the `data.id` on the response tree, and the `user_id` will be `data.attributes.owner.id` on the response tree.

### Identity Types
---
Openbridge offers connections to several third parties. Internally we call these `remote identity types` and we have an id that we associate with each of them.

> | id    | provider  | region |
> |-------------------|-----------|----------|
> | `1` |  Google (except for Adwords) | global |
> | `2` |  Facebook | global |
> | `8` |  Google Adwords | global |
> | `14` |  Amazon Advertising | [region index](#amazon-advertising-regions) |
> | `17` |  Amazon Selling Partner | [region index](#amazon-selling-partner--vendor-central-regions) |
> | `18` |  Amazon Vendor Central | [region index](#amazon-selling-partner--vendor-central-regions) |


### Amazon Advertising Regions
---
> | region identifier    | region name |
> |-------------------|-----------|
> | `na` |  `North America` |
> | `eu` |  `Europe` |
> | `fe` |  `Far East` |


### Amazon Selling Partner &amp; Vendor Central Regions
---
> | region identifier    | region name |
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

### Redirect URL
Whether the identity is created successfully, or an error happens in the process, the oauth API needs to know where to return the end user too. We store this in the state, it allows for greater flexibility in app creation, since you aren't tied to returning a user to a single location. Openbridge for example redirects users to the wizard they started on. We include a parameter to indicate what stage of the wizard the user was last on.


### Shop URL
The `shop_url` is only used in conjunction with shopify identities. Currently we do not support the creation of Shopify authenticated identities for our API users at this time.


## Create a state object
With these in mind, let's create a state that can be used for gaining an authorization for Amazon Selling Partner API, We'll do it for account 1, that is owned by user 1. (Don't really do this it is only for example, please use your own user and account id, you can use the [Account API](#account-api) to retrieve them.). We will do it for the `US` region. We'll then return them to the Openbirdge wizard for the Selling Partners "Orders API" product, and we'll pass the stage parameter so we land on the identity selection page.

> ```json
> {
>  "account_id": "1";
>  "user_id": "1";,
>  "remote_identity_type_id": 17;
>  "region": "US";
>  "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity"
>  "shop_url": null;
> }
> ```

```json
{
  "account_id": "1",
  "user_id": "1",
  "remote_identity_type_id": 17,
  "region": "US",
  "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity",
  "shop_url": null
}
```

Now that we have the state object, we need to generate a payload for the [state API](#state-api) with it. We add it to the payload as the `state` attribute.

```json
{
  "data": {
    "type": "ClientState",
    "attributes": {
      "state": {
        "account_id": "1",
        "user_id": "1",
        "remote_identity_type_id": 17,
        "region": "US",
        "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity",
        "shop_url": null
      }
    }
  }
}
```

Our curl request for testing looks like this.
```
curl -H "Content-Type: application/json" -X POST -d '{ "data": { "type": "ClientState", "attributes": { "state": { "account_id": "1", "user_id": "1", "remote_identity_type_id": 17, "region": "US", "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity", "shop_url": null } } } }' https://state.api.openbridge.io/state/oauth
```

Which will produce the following response
```json
{
  "data": {
    "type": "ClientState",
    "id": "36613eebc2b09e4ec36663ebdf647658",
    "attributes": {
      "token": "36613eebc2b09e4ec36663ebdf647658",
      "created_at": "2023-01-26T14:29:09.996295",
      "modified_at": "2023-01-26T14:29:09.996327",
      "state": {
        "account_id": "1",
        "user_id": "1",
        "remote_identity_type_id": 17,
        "region": "US",
        "return_url": "https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity",
        "shop_url": null
      }
    }
  }
}
```

You can see that the output is much like the input, except we have been given `created_at` and `modified_at` data, and the `id` and `token` which should always be the same thing.  What we really care about is the `id`/`token`.  This is the value that will represent our calls to the third-party OAuth APIs.

## Initializing the authorization process
---
To start the authorization process simply redirect the user in the browser to the Oauth API's initialize URL along with the state token.

```bash
https://oauth.api.openbridge.io/oauth/initialize?state=XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Security Note (MUST READ).
The OAuth API is called via a redirect in the browser. It should **NEVER** be called in a frame or iframe element withing HTML in the browser. Many OAuth providers disable this as it is a [clickjacking security risk](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-23#section-10.13). All of the providers Openbridge uses have disabled it. Popups may work on some third parties, but it is **not** supported by Openbridge.

Once the user is directed to the Openbridge Oauth api, the state is read based on the passed in state token. Based on the `remote_identity_type_id` in the state the end user will be redirected to the correct oauth provider. In our example that is Amazon Selling Partner. Once the user completes the process they are returned back to the Openbridge oauth api, where the identity information is stored in the Openbridge database, and the end user is then redirected to the return_url that was created in the state. In our case the blow URL along with some additional query string parameters.

```bash
https://app.openbridge.com/wizards/amazon-selling-partner-orders?stage=identity&state=XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Additional Oauth return parameters
---
> | key | datatype | description |
> |-------------------|-----------|-|
> | `state` | `string` | The state id/token we passed during the initialization process.
> | `ri_id` | `integer` | The id of the created/reauthorized identity.
> | `reauth` | `boolean` | Whether this is a new identity in the Openbridge database or a reauthorization of an existing identity identity. An identity can be new to a user/account but not to our database. It is possible for 2 accounts to have the same identity associated with it. We call these shared identities.
> | `status` | `string` | returned when an error is present, it's value should always be `error`.
> | `status_message` | `string` | The message related to the status, in this case it is an error message.

In the case of the `status` key, you should check for the value to be error, as in the future this field may be expanded on. Don't rely simply on it's existence for error handling.

When an identity is successfully created you can use the [identities API](#remote-identity-api) to query it.

**Note** The process for reauthorizing an identity is exactly the same as creating one. In the case of a reauth we return parameter `reauth` in the querystring.