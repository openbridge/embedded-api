### Healthchecks Query
<details>
  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/{{account_id}}</b></code></summary>

  The healthchecks endpoint is used for querying information about the health of active pipelines.  Part of the URL 

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters

> | parameter | required | description |
> |-|-|-|
> | account_id | `TRUE` | The acocunt ID that owns the subscription is passed in as part of the URI. |

The GET method has the following required and optional query string parameters available. 

> | parameter | required | description |
> |-|-|-|
> | subscription_id | `TRUE` | Pipeline Subscription ID you want health informatino for. |
> | modified_at__gte | `TRUE` | Modified date greater than evaluator. |
> | modified_at__lte | `TRUE` | Modified date less than evaluator.. |
> | page | `TRUE` | Paginated page number for the over all query. |
> | page_size | `FALSE` | Result count per page, should not exceed 100. |
> | status | `TRUE` | Should be set to `ERROR` to find pipeline subscription errors. |


##### Response Codes

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |


#### Response Example

Please note the `First`,`Last`,`Previous`, and `Next` URLs are unusable from the outside world.  You must generate the next and previous URLs based on page that you are currently on manually.

>```
>{
>    "results": [
>        {
>            "id": {{ID}},
>            "modified_at": "{{MODIFIEDAT}}",
>            "company": "{{COMPANYNAME}}",
>            "email_address": "{{EMAILADDRESS}}",
>            "product_id": {{PRODUCTID}},
>            "subproduct_id": null,
>            "product_name": "{{PRODUCTNAME}}",
>            "payload_name": "{{PAYLOADNAME}}",
>            "storage_id": "{{STORAGEID}}",
>            "subscription_id": 116828,
>            "subscription_name": "{{SUBSCRIPTIONNAME}}",
>            "hc_runtime": "{{RUNTIMEDATETIME}}",
>            "status": "{{STATUS}}",
>            "message": {{MESSAGE}},
>            "file_path": "{{FILEPATH}}",
>            "owner": " ",
>            "sender": "{{SENDERNAME}}",
>            "transaction_id": "{{TRANSACTIONID}}",
>            "err_msg": "{{ERRORMESSAGE}}",
>            "error_code": "",
>            "job_id": null,
>            "account_id": {{ACCOUNTID}}
>        }
>    ],
>    "meta": {
>        "pagination": {
>            "page": 1,
>            "pages": 1,
>            "count": 1
>        }
>    },
>    "links": {
>        "first": "XXXXXX",
>        "last": "XXXXXXXX",
>        "next": null,
>        "prev": null
>    }
>}
>```

##### Example cURL

This example is for requesting one day of health check data for January 24, 2024.

> ```curl
>  curl -H "Content-Type: application/json" -X GET  https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/{{account_id}}?subscription_id={{subscription_ID}}&page=1&status=ERROR&page_size=10&modified_at__gte=2024-01-23%2000:00:00&modified_at__lte=2024-01-24%2023:59:59
> ```

</details>
