### Amazon Advertising Marketing Stream

<details>
 <summary><code>POST</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/amzadv/stream/{remote_identity_id}</b></code></summary>

This endpoint is used in the creation of the Amazon Marketing stream SQS queues that are needed to collect data.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Payload
> 

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `application/json`        | `Success`                                |
> | `202`         | `application/json`        | `Success`                                |
> | `204`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `403`         |         | `Forbidden`                                |
> | `404`         |         | `Not Found`                                |
> | `409`         |         | `Conflict`                                |

##### Example cURL

{{ CURLEXAMPLE }}
> ```curl
>  curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/amzadv/stream/{remote_identity_id}
> ```

##### Example Response
{{ RESPONSE }}

</details>