<details>
 <summary><code>DELETE</code> <code><b>https://remote-identity.api.openbridge.io/ri</b><b>/{id}</b></code></summary>

Identities can be shared between more than one Openbridge account.  The DELETE call will remove any association between the calling account and the identity.  If the identity only belongs to the one account it will also delete the identity and any credentials associated with it.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | Authorization      |  string  | Openbridge JWT, passed as a  authorization bearer type

##### Parameters
> The DELETE method requires the remote identity ID as part of the reuqest string.


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Configuration created successfully`                                |
> | `404`         | `application/json`        | `Not found`                                |

##### Example cURL

> ```curl
>  curl -X DELETE -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://remote-identity.api.openbridge.io/ri/{remite_identity_id}
> ```

</details>