### Google Campaign Manager Reports

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

{{ CURLEXAMPLE }}
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