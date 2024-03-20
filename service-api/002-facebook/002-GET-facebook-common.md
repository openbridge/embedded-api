#### Facebook Page Profiles

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/facebook/page-profiles/{remote_identity_id}</b></code></summary>

This endpoint is used to get a list of page IDs and associated Instagram business acount IDs that are associated with a given identity.

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
>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/facebook/page-profiles/{remote_identity_id}
> ```

##### Example Response

If a Facebook page does not have an Instagram account ID attached to it the response would look like this.
>```
>{
>  "data": [
>    {
>      "type": "FacebookPages",
>      "id": "XXXXXXXXXXXXX",
>      "attributes": {
>        "name": "Page Name",
>        "country_page_likes": 5711753,
>        "name_with_location_descriptor": "Page location description",
>        "engagement": {
>          "count": 10061100,
>          "social_sentence": "10M people like this."
>        },
>        "description": "Page description text",
>        "about": "Page short description"
>      }
>    }
>  ]
>}
>```

If a Facebook page has an Instagram account attached to it it would include it in the response like this.

>```
>{
>  "data": [
>    {
>      "type": "FacebookPages",
>      "id": "XXXXXXXXXXXXX",
>      "attributes": {
>        "name": "Page Name",
>        "instagram_business_account": {
>          "id": "XXXXXXXXXXXX"
>        },
>        "country_page_likes": 5711753,
>        "name_with_location_descriptor": "Page location description",
>        "engagement": {
>          "count": 10061100,
>          "social_sentence": "10M people like this."
>        },
>        "description": "Page description text",
>        "about": "Page short description"
>      }
>    }
>  ]
>}
>```

</details>