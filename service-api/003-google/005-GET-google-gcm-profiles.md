### Google Campaign Manager Profiles

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/gcm/profiles/{remote_identity_id}</b></code></summary>

This endpoint provides a list of profiles associated with a given identity.

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

{{ CURLEXAMPLE }}
> ```curl
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/gcm/profiles/{remote_identity_id}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "id": "5905858",
>      "attributes": {
>        "kind: 'dfareporting#userProfile",
>        "username: 'analyticsrequests",
>        "accountId: 'XXXXXXXXX",
>        "accountName: 'Account Name",
>        "etag: "'XXXXXXXXXaTjgKplpiRgRgzTOVD5_GUdUcps"
>      }
>    }
>  ],
>  "includes": {
>    "next": ""
>  }
>}
>```
</details>