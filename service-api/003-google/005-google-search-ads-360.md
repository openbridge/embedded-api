### Google Search Ads 360

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/gsa/agency/{remote_identity_id}</b></code></summary>

This endpoint returns a list advertiser/agency pairs associated with an identity.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Parameters
> Put parameters here.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `404`         |         | `Not Found`                                |

##### Example cURL

{{ CURLEXAMPLE }}
> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/gsa/agency/{remote_identity_id}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "id": "XXXXXXXXXX:XXXXXXXXXX",
>      "attributes": {
>        "agency": "XXXXXXXXXX",
>        "agencyId": "XXXXXXXXXX",
>        "advertiser": "XXXXXXXXXX",
>        "advertiserId": "XXXXXXXXXX"
>      }
>    },
>    {
>      "id": "XXXXXXXXXX:XXXXXXXXXX",
>      "attributes": {
>        "agency": "XXXXXXXXXX",
>        "agencyId": "XXXXXXXXXX",
>        "advertiser": "XXXXXXXXXX",
>        "advertiserId": "XXXXXXXXXX"
>      }
>    }
>  ],
>  "includes": {
>    "next": ""
>  }
>}
>```

</details>
