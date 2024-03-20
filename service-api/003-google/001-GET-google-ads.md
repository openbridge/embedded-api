### Google Ads

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/googleads/list-customers/{remote_identity_id}</b></code></summary>

This endpoint is used to get a list of customers attached to the associated identity.

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
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/googleads/list-customers/{remote_identity_id}
> ```

##### Example Response
> ```
>{
>  "data": [
>    {
>      "id": "XXXXXXXXX",
>      "descriptive_name": '"XXXXXXXXXXXXX"',
>      "currency_code": "CAD",
>      "time_zone": "America/Toronto",
>      "auto_tagging_enabled": false,
>      "has_partners_badge": false,
>      "manager": true,
>      "test_account": false
>    }
>  ]
>}
>```
</details>

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}</b></code></summary>

This endpoint is used to get a list of customer managed by a manager customer.  You will need both the remote identity ID and the manager customer ID to get the list of managed customers.  A manager customer will have the 'manager' attribute set to true in the list customers call.

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
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}
> ```

##### Example Response
>```
>{
>  "data": {
>    "manager": {
>      "id": "XXXXXXXXXXXXX",
>      "name": "Manager Account Name"
>    },
>    attributes: [
>      {
>        "id": "XXXXXXXXXXX",
>        "descriptive_name": "Descriptive name",
>        "currency_code": "AED",
>        "time_zone": "Asia/Dubai",
>        "test_account": false,
>        "level": 3,
>        "resource_name": "customers/XXXXXXXXXX/customerClients/XXXXXXXXXXXXX"
>      }
>    ]
>  }
>}
>```
</details>