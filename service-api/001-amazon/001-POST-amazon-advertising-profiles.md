#### Amazon Advertising Profiles
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
>   "data": [
>      {
>       "id": "number",
>       "type": "AmazonAdvertisingProfile",
>       "attributes": {
>         "country_code": "string",
>         "currency_code": "string",
>         "daily_budget": "number",
>         "timezone": "string",
>         "account_info": {
>           "id": "string",
>           "type": "string",
>           "attributes": {
>             "marketplace_country": "string",
>             "marketplace_string_id": "string",
>             "name": "string",
>             "type": "string",
>             "subType": "string",
>             "valid_payment_method": "boolean"
>           }  
>         }
>       }
>     }
>   ]
> }
> ```
</details>