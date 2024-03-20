#### Amazon Advertising Brands

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
>   "data": {
>     "id": "number"
>     "type": "AmazonAdvertisingProfileBrand",
>     "attributes": {
>       "brand_entity_id": "";
>       "brand_registry_name": "string",
>       "profile_id": "string",
>     }
>   }
> }
> ```

</details>