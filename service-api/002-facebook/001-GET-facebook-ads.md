#### Facebook Ads
<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/facebook/ads-profiles/{remote_identity_id}</b></code></summary>

This endpoint is used to get a list of account IDs associated with a Facebook identity.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `404`         |         | `Not Found`                                |

##### Example cURL

> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/facebook/ads-profiles/{remote_identity_id}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "type": "FacebookMarketing",
>      "id": "XXXXXXXXXXXXXXX",
>      "attributes": {
>        "name": "My Marketing Account Name",
>        "account_id": "XXXXXXXXXXXXXXX",
>        "account_status": 101,
>        "business_name": "XXXXXX",
>        "business_city": "london"
>      }
>    }
>  ]
>}
>```
</details>