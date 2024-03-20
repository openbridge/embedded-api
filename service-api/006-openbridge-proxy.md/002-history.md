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
>           is_primary: boolean
>         }
>       }
>     }
> ```

The request endpoint of the HistoryTransaction will require the subscription id.  The payload will require 4 parameters.

> | name | data type | description |
> |-|-|-|
> | `product_id` | int | The product id inside the subscription the history is being requested for.
> | `start_date` | int | The start date reflects the most recent date you want to request data from the source system for.
> | `end_date` | int | The end date is the furthermost date from the current date that data collection will stop.
> | `is_primary` | booelan | Always use `false`

You may notice that both the `subscription_id` and the `product_id` are required in the request.  The History transaction sets stages based on project and is unaware of what product a subscription is for otherwise.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> The POST method does not require any parameters. 

##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `201` | `application/json` | `Created` |

##### Example cURL

This example is for an Amazon Selling Partner Sales & Traffic product.

> ```curl
>  curl -H "Content-Type: application/json" -X POST -d '{ "data": { type: "HistoryTransaction", "attributes": { "product_id": 64; "start_date": "2021-10-10", "end_date": "2021-10-01", "is_primary": true }}}' https://service.api.openbridge.io/service/history/production/history/{{subscriptionId}}
> ```

##### Request Max Dates

Each product has a maximum amount of days that history can be requested for (ie the end date).  The maximium `end_date` is always calculated from the date that history is being requested on.

> | Product Name | Product Id | Max Days |
> |-|-|-|
> | Amazon Sales & Traffic | 64 | 700 |
> | Amazon Seller Brand Analytics Reports | 65 | 365 |
> | Amazon Settlement Reports | 57 | 90 |
> | Amazon Fulfillment | 58 | 540 |
> | Amazon Inventory | 59 | 540 |
> | Amazon Sales Reports | 61 | 730 |
> | Amazon Fees | 62 | 30 |

</details>