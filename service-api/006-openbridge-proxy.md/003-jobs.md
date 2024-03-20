### Jobs API.
<details>
  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/jobs/jobs?subscription_ids={{subscription_id}}</b></code></summary>
  
The jobs endpoint will allow you to get detailed information about the current job states of a given pipeline subscription.


##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> | name | data type | description                                                           |
> |-|-|-|
> | subscription_ids | string | Accepts a comma seperated list of pipeline subscrition IDs, however we recommend doing checks one at a time. |
> |`order_by`|`is_primary`|`orders job records primary first then history`|
> |`page`|`number`|`paginated history page`|
> |`page_size`|`number`|`number of records to show per page request`|
> | `is_primary` |`boolean` | `'true' to return prumary jobs 'false' to return history jobs. Exclude for all jobs` |


##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example is for retrieving Jobs records for a given pipeline.

> ```curl
>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/jobs/jobs?subscription_ids={{subscription_id}}
> ```

###### Example Response

> ```json
>{
>    "links": {
>        "first": "UNUSABLE URL",
>        "last": "UNUSABLE URL",
>        "next": "",
>        "prev": ""
>    },
>    "data": [
>        {
>            "type": "Job",
>            "id": "1568426",
>            "attributes": {
>                "report_date": null,
>                "subscription_id": "XXXXXXXXX",
>                "valid_date_start": "2024-02-15",
>                "valid_date_end": "2099-12-31",
>                "status": "active",
>                "schedule": "42 14 * * *",
>                "orig_schedule": "42 14 * * *",
>                "request_start": 1,
>                "request_end": 0,
>                "created_at": "2024-02-15T12:37:54.483313",
>                "modified_at": "2024-02-15T12:37:54.483326",
>                "is_primary": true,
>                "stage_id": 1,
>                "extra_context": null,
>                "product_id": 82,
>                "subproduct_id": "identifiers"
>            }
>        }
>    ],
>    "meta": {
>        "pagination": {
>            "page": 1,
>            "pages": 1,
>            "count": 1
>        }
>    }
>}
> ``` 
</details>