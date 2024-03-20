<details>
 <summary><code>PATCH</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/amzadv/stream/{remote_identity_id}/{sub_id}</b></code></summary>

This endpoint is used in the updating of the Amazon Marketing stream SQS queues that are needed to collect data.  It should only be called when new SQS queue types are available.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Payload
> 

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `403`         |         | `Forbidden`                                |
> | `404`         |         | `Not Found`                                |
> | `409`         |         | `Conflict`                                |

##### Example cURL

{{ CURLEXAMPLE }}
> ```curl
>  curl -X PATCH -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/amzadv/stream/{remote_identity_id}/{sub_id}
> ```

##### Example Response
{{ RESPONSE }}


</details>