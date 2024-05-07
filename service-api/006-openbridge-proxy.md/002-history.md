### Product Payloads
<details>
  <summary><code>GET</code> <code><b>https://service.api.dev.openbridge.io/service/products/production/product/{{product_id}}/payloads?stage_id__gte=1000</b></code></summary>

  The healthchecks endpoint is used for querying information about the health of active pipelines.  Part of the URL 

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json |
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type |

##### Parameters

> | parameter | required | description |
> |-|-|-|
> | product_id | `TRUE` | The id of the product you want the stage informatino for. |

The GET method has the following required and optional query string parameters available. 

> | parameter | required | description |
> |-|-|-|
> | stage_id__gte | `TRUE` | Used to retrieve all stages above 1000 for a given product.  Used for history requests. |


##### Response Codes

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |


#### Response Example

Please note the `First`,`Last`,`Previous`, and `Next` URLs are unusable from the outside world.  You must generate the next and previous URLs based on page that you are currently on manually.

>```
>{
>   "links": {
>     "first": "Internal address unusable from outside world",
>     "last": "Internal address unusable from outside world",
>     "next": "Internal address unusable from outside world",
>     "prev": "Internal address unusable from outside world"
>   },
>   "data": [
>     {
>       "type": "Product",
>       "id": "{{RECORDID}}",
>       "attributes": {
>         "name": "{{TABLENAME}}",
>         "created_at": "{{CREATED_AT_TIMESTAMP}}",
>         "modified_at": "{{MODIFIED_AT_TIMESTAMP}}",
>         "stage_id": {{STAGEID}}
>       }
>     },
>     ...
>   ],
>   "meta": {
>     "pagination": {
>       "page": 1,
>       "pages": 1,
>       "count": 3
>     }
>   }
> }
>```

##### Example cURL

This example is for requesting stage data for Amazon Orders API

> ```curl
>  curl -H "Content-Type: application/json" -X GET  https://service.api.dev.openbridge.io/service/products/production/product/53/payloads?stage_id__gte=1000
> ```
</details>


### History

<details>
  <summary><code>POST</code> <code><b>https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}</b></code></summary>

  The History endpoint is used for generating history requests for subscriptions where history is allowed.  Not all products can generate history requests.

###### Payload Schema

> ```json
> {
>       data: {
>         type: 'HistoryTransaction',
>         attributes: {
>           product_id: int;
>           start_date: dateString,
>           end_date: dateString,
>           is_primary: boolean,
>           start_time?: datetimeString,
>           stage_id?: productStageId
>         }
>       }
>     }
> ```

The request endpoint of the HistoryTransaction will require the subscription id.  The payload will require 4 parameters.

> | name | data type | description |
> |-|-|-|
> | `product_id` | int | The product id inside the subscription the history is being requested for.
> | `start_date` | int | The start date reflects the most recent date you want to request data from the source system for. |
> | `end_date` | int | The end date is the furthermost date from the current date that data collection will stop. |
> | `is_primary` | booelan | Always use `false` |
> | `stage_id` | int | (optional) The stage ID for a given product that can be found from the Product Payload request for that product. |
> | `start_time` | string | (required if stage_id is set) UTC Datetime string of the time you want this request to first run, must be no sooner than 10 minutes from the time of request.  15 minutes or more is recommended. |

You may notice that both the `subscription_id` and the `product_id` are required in the request.  The History transaction sets stages based on project and is unaware of what product a subscription is for otherwise.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json |
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type |


##### Parameters
> The POST method does not require any parameters. 

##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `201` | `application/json` | `Created` |

##### Example cURL

This example is for requesting stage data for Amazon Orders API.

> ```curl
>  curl -H "Content-Type: application/json" -X POST -d '{ "data": { type: "HistoryTransaction", "attributes": { "product_id": 53; "start_date": "2021-10-10", "end_date": "2021-10-01", "is_primary": true, "stage_id": 1000, "start_time": "2024-05-06 12:05:00" }}}' https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}
> ```

</details>