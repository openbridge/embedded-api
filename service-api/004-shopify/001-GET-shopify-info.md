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

