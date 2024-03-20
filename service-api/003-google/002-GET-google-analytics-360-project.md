## Google Analytics 360

### Get Bigquery project.

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/bq/projects/{remote_identity_id}</b></code></summary>

This endpoint provides a list of google bigquery projects associated with the identtiy.

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
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/bq/projects/{remote_identity_id}
> ```

</details>