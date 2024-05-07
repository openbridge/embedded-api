- [Service API](#service-api)
	- [Third-party APIs](#third-party-apis)
	  - [Amazon Advertising](#amazon-advertising)
			- [Amazon Advertising Profiles](#amazon-advertising-profiles)
			- [Amazon Advertising Brands](#amazon-advertising-brands)
	  	- [Amazon Advertising Marketing Stream](#amazon-advertising-marketing-stream)
		- [Facebook](#facebook)
			- [Facebook Ads](#facebook-ads)
			- [Facebook Page Insights/Instagram Insights/Instagram-stories](#facebook-page-insights-instagram-insights-instagram-stories)
		- [Google](#google)
			- [Google Ads](#google-ads)
			- [Google Analytics 360](#google-analytics-360)
			- [Google Campaign Manager](#google-campaign-manager)
			- [Google Search Ads 360](#google-search-ads-360)
	  - [Shopify](#shopify)
		  - [Shopify Info](#shopify-info)
	  - [Youtube](#youtube)

  - [Openbridge API Proxies](#openbridge-api-proxies)
	  - [Healthchecks](#healthchecks)
	  - [Product Payloads](#product-payloads)
	  - [History Max Requetst](#history-max-requests)
	  - [History](#history-transaction-creation)
	  - [Jobs](#jobs)

# Service API

The service API is used as a proxy for other external API calls, mostly to third-party APIs such as Amazon, Facebook, and Google.  It also provides a proxy to Openbridge's APIs such as the health checks, history, and jobs APIs

## Third-party APIs

### Amazon Advertising

#### Amazon Advertising Profiles
<details>

  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/amzadv/profiles-only/{{remoteIdentityId}}?profile_types={{profileType(s)}}</b></code></summary>

  The Amazon Advertising Profiles service endpoint is use to get a list of profiles based on type(s) of profile that you need.

  The request endpoint of the AmazonAdvertisingProfile will require the remote identity id, and the profile types you are quering.  Depending on the product you are creating a subscription for you will need to request the correct profile types.  The profile types parameter is comma separated list of valid types.  The table below will show what types for which products.

> | product name | profile types |
> |-|-|
> | `Amazon Advertising (SB/SD)` | seller,vendor |
> | `Amazon Advertising (SP)` | seller,vendor |
> | `Amazon Advertising Ads Recommendations` | seller,vendor |
> | `Amazon Advertising Brand Metrics` | seller,vendor |
> | `Amazon Attribution` | attribution |
> | `Amazon DSP` | dsp |

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> | name | data type | description                                                           |
> |-|-|-|
> | profile_types | string | Amazon advertising profile type(s). (see the list above) 


##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example is for retrieving Amazon Advertising Profiles.
> ```curl

>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/amzadv/profiles-only/{{remoteIdentityId}}?profile_types={{profileTypes}}
> ```

###### Example Response

> ```json
> {
>   "data": [
>      {
>       "id": "number",
>       "type": "AmazonAdvertisingProfile",
>       "attributes": {
>         "country_code": "string",
>         "currency_code": "string",
>         "daily_budget": "number",
>         "timezone": "string",
>         "account_info": {
>           "id": "string",
>           "type": "string",
>           "attributes": {
>             "marketplace_country": "string",
>             "marketplace_string_id": "string",
>             "name": "string",
>             "type": "string",
>             "subType": "string",
>             "valid_payment_method": "boolean"
>           }  
>         }
>       }
>     }
>   ]
> }
> ```
</details>

#### Amazon Advertising Brands

<details>

  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/amzadv/brands/{{remoteIdentityId}}?profiles={{profileIds}}</b></code></summary>

The Amazon Advertising Profile Brands service endpoint is use to get additional meta data about Amazon Advertising profiles.  

The request endpoint of the AmazonAdvertisingProfile will require the remote identity id, and the profile types you are quering.  Depending on the product you are creating a subscription for you will need to request the correct profile types.  The profile types parameter is comma separated list of valid types.  The table below will show what types for which products.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type


##### Parameters
> | name | data type | description                                                           |
> |-|-|-|
> | profiles | string | A csv list of profile IDs valid for the provided remote identity id. 

*NOTE*: The profiles parameter is used because passing too many profiles at once can cause the upstream API to time out.  Therefore you should never send more than 5 profile IDs at one time.  This means that if you have 100 profile IDs from the Amazon Advertising Profiles endpoint you would have to loop through and call this endpoint 20 times to get all the extra meta information.

##### Responses

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |

##### Example cURL

This example is for retrieving Amazon Advertising Profile Brands.
> ```curl

>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/amzadv/brands/{{remoteIdentityId}}?profiles={{profileIds}}
> ```

###### Example Response

> ```json
> {
>   "data": {
>     "id": "number"
>     "type": "AmazonAdvertisingProfileBrand",
>     "attributes": {
>       "brand_entity_id": "";
>       "brand_registry_name": "string",
>       "profile_id": "string",
>     }
>   }
> }
> ```

</details>

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

> ```curl

>  curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/amzadv/stream/{remote_identity_id}
> ```

##### Example Response
{{ RESPONSE }}

</details>

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

> ```curl

>  curl -X PATCH -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/amzadv/stream/{remote_identity_id}/{sub_id}
> ```

##### Example Response
{{ RESPONSE }}


</details>


### Amazon Pricing API and Catalog API


### Facebook

#### Facebook Ads
<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/facebook/ads-profiles/{remote_identity_id}</b></code></summary>

This endpoint is used to get a list of account IDs associated with a Facebook identity.

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
> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/facebook/ads-profiles/{remote_identity_id}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "type": "FacebookMarketing",
>      "id": "XXXXXXXXXXXXXXX",
>      "attributes": {
>        "name": "My Marketing Account Name",
>        "account_id": "XXXXXXXXXXXXXXX",
>        "account_status": 101,
>        "business_name": "XXXXXX",
>        "business_city": "london"
>      }
>    }
>  ]
>}
>```
</details>

#### Facebook Page Insights/Instagram Insights/Instagram-stories

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

### Google Ads

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/googleads/list-customers/{remote_identity_id}</b></code></summary>

This endpoint is used to get a list of customers attached to the associated identity.

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
> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/googleads/list-customers/{remote_identity_id}
> ```

##### Example Response
> ```
>{
>  "data": [
>    {
>      "id": "XXXXXXXXX",
>      "descriptive_name": '"XXXXXXXXXXXXX"',
>      "currency_code": "CAD",
>      "time_zone": "America/Toronto",
>      "auto_tagging_enabled": false,
>      "has_partners_badge": false,
>      "manager": true,
>      "test_account": false
>    }
>  ]
>}
>```
</details>

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}</b></code></summary>

This endpoint is used to get a list of customer managed by a manager customer.  You will need both the remote identity ID and the manager customer ID to get the list of managed customers.  A manager customer will have the 'manager' attribute set to true in the list customers call.

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
> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/googleads/list-managed/{remote_identity_id}/{google_ads_customer_id}
> ```

##### Example Response
>```
>{
>  "data": {
>    "manager": {
>      "id": "XXXXXXXXXXXXX",
>      "name": "Manager Account Name"
>    },
>    attributes: [
>      {
>        "id": "XXXXXXXXXXX",
>        "descriptive_name": "Descriptive name",
>        "currency_code": "AED",
>        "time_zone": "Asia/Dubai",
>        "test_account": false,
>        "level": 3,
>        "resource_name": "customers/XXXXXXXXXX/customerClients/XXXXXXXXXXXXX"
>      }
>    ]
>  }
>}
>```
</details>

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

> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/bq/projects/{remote_identity_id}
> ```

</details>


### Get Bigquery datasets.

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/bq/project-datasets/{remote_identity_id}?project_id={project_id}</b></code></summary>

This endpoint provides a list of google bigquery project datasets associated with the identtiy.

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

> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/bq/project-datasets/{remote_identity_id}?project_id={project_id}
> ```

</details>
### Google Campaign Manager

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

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/gcm/reports/{remote_identity_id}?profile_id={profile_id}</b></code></summary>

{{ Some text here }}

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Parameters

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `profile_id` |  `string`  | `The profile ID you want reports for.`

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `404`         |         | `Not Found`                                |

##### Example cURL

> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/gcm/reports/{remote_identity_id}?profile_id={{profile_id}}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "id": "700936099",
>      "attributes": {
>        "ownerProfileId": "XXXXXXXXXX",
>        "accountId": "XXXXXXXXXX",
>        "name": "Report Name",
>        "fileName": "DCM_global_export_MC",
>        "kind": "dfareporting#report",
>        "type": "STANDARD",
>        "etag": "\"NPy0DkBZHJQTiOfcOqtfTBzEQUo\"",
>        "lastModifiedTime": "1643227626000",
>        "format": "CSV",
>        "criteria": {
>          "dateRange": {
>            "relativeDateRange": "YESTERDAY",
>            "kind": "dfareporting#dateRange"
>          },
>          "dimensions": [
>            {
>              "name": "date",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "advertiserId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "advertiser",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "campaignId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "campaignExternalId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "campaign",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementExternalId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placement",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementCostStructure",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementRate",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "creativeId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "creative",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "creativeType",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "adId",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "ad",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "adType",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "site",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "campaignStartDate",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "campaignEndDate",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "clickThroughUrl",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "richMediaVideoLength",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementStartDate",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "placementEndDate",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "packageRoadblock",
>              "kind": "dfareporting#sortedDimension"
>            },
>            {
>              "name": "packageRoadblockId",
>              "kind": "dfareporting#sortedDimension"
>            }
>          ],
>          "metricNames": [
>            "impressions",
>            "clicks",
>            "clickRate",
>            "activeViewViewableImpressions",
>            "activeViewMeasurableImpressions",
>            "activeViewEligibleImpressions",
>            "totalConversions",
>            "totalConversionsRevenue",
>            "richMediaTrueViewViews",
>            "richMediaCustomAverageTime",
>            "richMediaVideoViews",
>            "richMediaAverageVideoViewTime",
>            "richMediaVideoFirstQuartileCompletes",
>            "richMediaVideoMidpoints",
>            "richMediaVideoThirdQuartileCompletes",
>            "richMediaVideoCompletions",
>            "richMediaVideoPlays",
>            "richMediaVideoViewRate"
>          ]
>        },
>        "schedule": {
>          "active": true,
>          "repeats": "DAILY",
>          "every": 1,
>          "startDate": "2021-03-18",
>          "expirationDate": "2025-03-18"
>        },
>        "delivery": {
>          "emailOwner": false
>        }
>      }
>    }
>  ],
>  "includes": {
>    "next": ""
>  }
>}
>```

</details>

### Google Search Ads 360

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/gsa/agency/{remote_identity_id}</b></code></summary>

This endpoint returns a list advertiser/agency pairs associated with an identity.

##### Headers

> | name      |        data type               | description                                                           |
> |-----------|------------------------------------|-----------------------------------------------------------------------|
> | `Authorization` |  `string`  | `Openbridge JWT, passed as a  authorization bearer type`

##### Parameters
> Put parameters here.

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`        | `Success`                                |
> | `400`         |         | `Bad Request`                                |
> | `401`         |         | `Not Authorized`                                |
> | `404`         |         | `Not Found`                                |

##### Example cURL

> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/service/gsa/agency/{remote_identity_id}
> ```

##### Example Response
>```
>{
>  "data": [
>    {
>      "id": "XXXXXXXXXX:XXXXXXXXXX",
>      "attributes": {
>        "agency": "XXXXXXXXXX",
>        "agencyId": "XXXXXXXXXX",
>        "advertiser": "XXXXXXXXXX",
>        "advertiserId": "XXXXXXXXXX"
>      }
>    },
>    {
>      "id": "XXXXXXXXXX:XXXXXXXXXX",
>      "attributes": {
>        "agency": "XXXXXXXXXX",
>        "agencyId": "XXXXXXXXXX",
>        "advertiser": "XXXXXXXXXX",
>        "advertiserId": "XXXXXXXXXX"
>      }
>    }
>  ],
>  "includes": {
>    "next": ""
>  }
>}
>```

</details>

## Shopify

### Shopify Info

<details>
 <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service</b><b>/service/shopify/shop-info/{remote_identity_id}</b></code></summary>

This endpoint is used to get the shopify shop meta information.

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
> ```curl

>  curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer YOURJWTXXXXXXXXXXXX" https://service.api.openbridge.io/service/shopify/shopify-info/{remote_identity_id}
> ```

##### Example Response
>```
>{
>    "data": {
>        "shop": {
>            "id": 000000001,
>            "name": "My Shop Name",
>            "email": "support@xxxxx.xxx",
>            "domain": "xxxxxx.xx",
>            "province": "",
>            "country": "US",
>            "address1": "123 ABC Lane",
>            "zip": "xxxxxx",
>            "city": "XXXXXXX",
>            "source": null,
>            "phone": "+XXXXXXX",
>            "latitude": XX.XXXXXX,
>            "longitude": XX.XXXXX,
>            "primary_locale": "XX",
>            "address2": "",
>            "created_at": "2023-03-22T17:42:27+01:00",
>            "updated_at": "2024-01-10T09:11:34+01:00",
>            "country_code": "XX",
>            "country_name": "XXXXXXXX",
>            "currency": "XX",
>            "customer_email": "XXXXX@XXXXXX.XX",
>            "timezone": "(GMT+01:00) Europe/XXXXXXX",
>            "iana_timezone": "Europe/XXXXXXXX",
>            "shop_owner": "XXXXXXXXX XXXXXXXXXXX",
>            "money_format": "€{{amount_with_comma_separator}}",
>            "money_with_currency_format": "€{{amount_with_comma_separator}} EUR",
>            "weight_unit": "kg",
>            "province_code": null,
>            "taxes_included": true,
>            "auto_configure_tax_inclusivity": null,
>            "tax_shipping": null,
>            "county_taxes": true,
>            "plan_display_name": "Shopify",
>            "plan_name": "professional",
>            "has_discounts": true,
>            "has_gift_cards": false,
>            "myshopify_domain": "XXXXXXXXXXX.myshopify.com",
>            "google_apps_domain": null,
>            "google_apps_login_enabled": null,
>            "money_in_emails_format": "€{{amount_with_comma_separator}}",
>            "money_with_currency_in_emails_format": "€{{amount_with_comma_separator}} EUR",
>            "eligible_for_payments": true,
>            "requires_extra_payments_agreement": false,
>            "password_enabled": false,
>            "has_storefront": true,
>            "finances": true,
>            "primary_location_id": XXXXXXXXXXX,
>            "checkout_api_supported": true,
>            "multi_location_enabled": true,
>            "setup_required": false,
>            "pre_launch_enabled": false,
>            "enabled_presentment_currencies": [
>                "EUR"
>            ],
>            "transactional_sms_disabled": true,
>            "marketing_sms_consent_enabled_at_checkout": false
>        }
>    }
>}
>```
</details>

## Openbridge API Proxies

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

### History Max Requests
<details>
  <summary><code>GET</code> <code><b>https://service.api.openbridge.io/service/history/production/history/meta/max-request</b></code></summary>

  The History max requests endpoint provides a list of all products that support history requests and the max number of days history can be requested for each.

##### Headers

> | name | data type | description                                                           |
> |-|-|-|
> | Content-Type | string | application/json |
> | Authorization | string | Openbridge JWT, passed as a  authorization bearer type |

##### Response Codes

> | http code | content-type | response |
> |-|-|-|
> | `200` | `application/json` | `OK` |


#### Response Example

>```
{
>  "data": [
>    {
>      "id": {{PRODUCTID}},
>      "attributes": {
>        "max_request_time": int,
>        "max_days_per_request": int,
>        "base_request_start": int
>      }
>      ...
>  ]
>}
>```


> | Attribute | meaning |
> |-|-|-|
> | max_request_time | The maximum number of days in the past history can requested for. |
> | max_days_per_request | Maximum number of days history can be requested for per request. |
> | base_request_start | When setting up history this is the number of days from today in the past that history can most recently be requested for.  For most products the value is 1, but for some products it is higher.  For example.  Facebook Page Insights (product id 2) has a base_request_start of 5.  On Jan 20th history can only be requested up until Jan 15.  For Amazon Orders API which has a base_request_start of 1 On Jan 20th history can only be requested up until Jan 19. |


##### Example cURL

This example is for requesting product max history request data.

> ```curl
>  curl -H "Content-Type: application/json" -X GET  https://service.api.openbridge.io/service/history/production/history/meta/max-request
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
> | `start_date` | int | The start date reflects the most recent date you want to request data from the source system for. |
> | `end_date` | int | The end date is the furthermost date from the current date that data collection will stop. |
> | `is_primary` | booelan | Always use `false` |
> | `stage_id` | int | (optional) The stage ID for a given product that can be found from the Product Payload request for that product. |
> | `start_time` | string | (required if stage_id is set) UTC Datetime string of the time you want this request to first run, must be no sooner than 10 minutes from the time of request.  15 minutes or more is recommended. |

**Note**:  We have recently removed the need to add a product_id as part of the payload, as it is now inferred from the subscription.

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
>  curl -H "Content-Type: application/json" -X GET https://service.api.openbridge.io/service/amzadv/profiles-only/{{remoteIdentityId}}?profile_types={{profileTypes}}
> ```

###### Example Response

> ```json
> {
>   "data": [
>      {
>       "id": "number",
>       "type": "AmazonAdvertisingProfile",
>       "attributes": {
>         "country_code": "string",
>         "currency_code": "string",
>         "daily_budget": "number",
>         "timezone": "string",
>         "account_info": {
>           "id": "string",
>           "type": "string",
>           "attributes": {
>             "marketplace_country": "string",
>             "marketplace_string_id": "string",
>             "name": "string",
>             "type": "string",
>             "subType": "string",
>             "valid_payment_method": "boolean"
>           }  
>         }
>       }
>     }
>   ]
> }
> ```
  
  
</details>


