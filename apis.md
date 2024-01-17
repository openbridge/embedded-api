## Service API

### Amazon Advertising Profiles

<details>

  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/amzadv/profiles-only/{{remoteIdentityId}}?profile_types={{profileType(s)}}</b></code></summary>

  The Amazon Advertising Profiles service endpoint is use to get a list of profiles based on type(s) of profile that you need.

  The request endpoint of the AmazonAdvertisingProfile will require the remote identity id, and the profile types you are quering.  Depending on the product you are creating a subscription for you will need to request the correct profile types.  The profile types parameter is comma separated list of valid types.  The table below will show what types for which products.

> | product name | profile types |
> |-|-|
> | `Amazon Advertising (SB/SD)` | seller,vendor |
> | `Amazon Advertising (SP)` | seller,vendor |
> | `Amazon Advertising Ads Recommendations` | seller,vendor |
> | `Amazon Advertising Brand Metrics` | seller,vendor |
> | `Amazon Attribution` | attribution |
> | `Amazon DSP` | dsp |

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> | name | data type | description                                                           |
> |-|-|-|
> | profile_types | string | Amazon advertising profile type(s). (see the list above) 


##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example is for retrieving Amazon Advertising Profiles.

> ```curl
>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/amzadv/profiles-only/{{remoteIdentityId}}?profile_types={{profileTypes}}
> ```

###### Example Response

> ```json
> {
>   data: {
>     id: number
>     type: 'AmazonAdvertisingProfile',
>     attributes: {
>       country_code: string;
>       currency_code: string,
>       daily_budget: number,
>       timezone: string,
>       account_info: {
>         id: string,
>         type: string,
>         attributes: {
>           marketplace_country: string,
>           marketplace_string_id: string,
>           name: string,
>           type: string,
>           subType: string,
>           valid_payment_method: boolean
>         }  
>       }
>     }
>   }
> }
> ```


</details>

### Amazon Advertising Profile Brands

<details>

  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/amzadv/brands/{{remoteIdentityId}}?profiles={{profileIds}}</b></code></summary>

The Amazon Advertising Profile Brands service endpoint is use to get additional meta data about Amazon Advertising profiles.  

The request endpoint of the AmazonAdvertisingProfile will require the remote identity id, and the profile types you are quering.  Depending on the product you are creating a subscription for you will need to request the correct profile types.  The profile types parameter is comma separated list of valid types.  The table below will show what types for which products.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> | name | data type | description                                                           |
> |-|-|-|
> | profiles | string | A csv list of profile IDs valid for the provided remote identity id. 

*NOTE*: The profiles parameter is used because passing too many profiles at once can cause the upstream API to time out.  Therefore you should never send more than 5 profile IDs at one time.  This means that if you have 100 profile IDs from the Amazon Advertising Profiles endpoint you would have to loop through and call this endpoint 20 times to get all the extra meta information.

##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example is for retrieving Amazon Advertising Profile Brands.

> ```curl
>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/amzadv/brands/{{remoteIdentityId}}?profiles={{profileIds}}
> ```

###### Example Response

> ```json
> {
>   data: {
>     id: number
>     type: 'AmazonAdvertisingProfileBrand',
>     attributes: {
>       brand_entity_id: string;
>       brand_registry_name: string,
>       profile_id: string,
>     }
>   }
> }
> ```

</details>

### History Transaction Creation

<details>
  <summary><code>POST</code> <code><b>https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}</b></code></summary>

  The History endpoint is used for generating history requests for subscriptions where history is allowed.  Not all products can generate history requests.

###### Payload Schema

> ```json
> {
>       data: {
>         type: 'HistoryTransaction',
>         attributes: {
>           product_id: int;
>           start_date: dateString,
>           end_date: dateString,
>           is_primary: boolean
>         }
>       }
>     }
> ```

The request endpoint of the HistoryTransaction will require the subscription id.  The payload will require 4 parameters.

> | name | data type | description |
> |-|-|-|
> | `product_id` | int | The product id inside the subscription the history is being requested for.
> | `start_date` | int | The start date reflects the most recent date you want to request data from the source system for.
> | `end_date` | int | The end date is the furthermost date from the current date that data collection will stop.
> | `is_primary` | booelan | Always use `false`

You may notice that both the `subscription_id` and the `product_id` are required in the request.  The History transaction sets stages based on project and is unaware of what product a subscription is for otherwise.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> The POST method does not require any parameters. 

##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `201` | `application/json` | `Created` |

##### Example cURL

This example is for an Amazon Selling Partner Sales & Traffic product.

> ```curl
>  curl -H "Content-Type: application/json" -X POST -d '{ "data": { type: "HistoryTransaction", "attributes": { "product_id": 64; "start_date": "2021-10-10", "end_date": "2021-10-01", "is_primary": true }}}' https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}
> ```

##### Request Max Dates

Each product has a maximum amount of days that history can be requested for (ie the end date).  The maximium `end_date` is always calculated from the date that history is being requested on.

> | Product Name | Product Id | Max Days |
> |-|-|-|
> | Amazon Sales & Traffic | 64 | 700 |
> | Amazon Seller Brand Analytics Reports | 65 | 365 |
> | Amazon Settlement Reports | 57 | 90 |
> | Amazon Fulfillment | 58 | 540 |
> | Amazon Inventory | 59 | 540 |
> | Amazon Sales Reports | 61 | 730 |
> | Amazon Fees | 62 | 30 |

</details>
