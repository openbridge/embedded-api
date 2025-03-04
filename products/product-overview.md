# Openbridge Products

This document provides information required when creating subscriptions for Openbridge products.

- [Amazon Advertising Products](#amazon-advertising-products)
  - [Amazon	Sponsored Ads (V3)](#amazon-sponsored-ads-v3)
  - [Amazon Advertising Brand Metrics](#amazon-advertising-brand-metrics)
  - [Amazon Attribution](#amazon-attribution)
  - [Amazon DSP](./products/amazon-advertising-dsp-v3.md)

- [Amazon Seller Products](#amazon-seller-products)
  - [Amazon Orders API](#amazon-orders-api)
  - [Amazon Finance Real-Time](#amazon-finance-real-time)
  - [Amazon Inbound Fulfillment](#amazon-inbound-fulfillment)
  - [Amazon Settlement Reports](#amazon-settlement-reports)
  - [Amazon Fulfillment](#amazon-fulfillment)
  - [Amazon Inventory](#amazon-inventory)
  - [Amazon Sales Reports](#amazon-sales-reports)
  - [Amazon Fees](#amazon-fees)
  - [Amazon Sales & Traffic](#amazon-sales--traffic)
  - [Amazon Seller Brand Analytics Reports](#amazon-seller-brand-analytics-reports)

- [Amazon Vendor Products](#amazon-vendor-products)

  - [Amazon Vendor Retail Analytics](#amazon-vendor-retail-analytics)
  - [Amazon Vendor Retail Procurement](#amazon-vendor-retail-procurement)
  - [Amazon Vendor Brand Analytics Reports](#amazon-vendor-brand-analytics-reports)
  - [Amazon Vendor Real-time Reports](#amazon-vendor-real-time-reports)

- [Mixed Amazon Seller and Vendor Products](#mixed-amazon-seller-and-vendor-products)
  - [Amazon Catalog Keyword Tracker](#amazon-seller-vendor-catalog-keyword-tracker)
  - [Amazon Catalog API](#amazon-seller-vendor-catalog-api)

- [Facebook Products](#facebook-products)

  - [Facebook Marketing](#facebook-marketing)
  - [Facebook Page Insights](#facebook-page-insights)
  - [Instagram Insights](#instagram-insights)
  - [Instagram Stories](#instagram-stories)

- [Google Products](#google-products)

  - [Google Analitics 360](#google-analytics-360)
  - [Google Campaign Manager](#google-campaign-manager)
  - [Google Search Ads 360](#google-search-ads-360)
  - [Google Ads](#google-ads)

- [Youtube Products](#youtube-products)
  - [Youtube Channel Insights](#youtube-channel-insights)
  - [Youtube Competitor Channels](#youtube-competitor-channels)
  - [Youtube Competitor Videos](#youtube-competitor-videos)
  - [Youtube Video Insights](#youtube-video-insights)

## Amazon Advertising Products

These products pull reports from resources attributed to the Amazon Advertising API.

### Amazon	Sponsored Ads (V3)
This product requires a call to the service API to get the requisit information for the subscription product meta.

The first call that needs to be made is to the [Amazon Advertising profiles](service-api.md#amazon-advertising-profiles)  endpoint.  This endpoint will return a list of Amazon Advertising profiles based on the requested type.  This list will provide the `profile_id` meta data.  If you need more information to display you can request the brand information for the profiles by calling the [Amazon Advertising Profile Brands](service-api.md#amazon-advertising-brands)  endpoint.  You can pass up to five profile IDs to retrieve their brand information simultaniously.  If you had more than five profiles you would need to iterate through them in groups of five to get them all.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 70 |
> | Remote Identity Type ID | 14 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | profile_id | `STRING` | Associated profile ID. |
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Advertising Brand Metrics

This product requires a call to the service API to get the requisit information for the subscription product meta.

The first call that needs to be made is to the [Amazon Advertising profiles](service-api.md#amazon)  endpoint.  This endpoint will return a list of Amazon Advertising profiles based on the requested type.  This list will provide the `profile_id` meta data.  If you need more information to display you can request the brand information for the profiles by calling the [Amazon Advertising Profile Brands](service-api.md#amazon-advertising)  endpoint.  You can pass up to five profile IDs to retrieve their brand information simultaniously.  If you had more than five profiles you would need to iterate through them in groups of five to get them all.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 75 |
> | Remote Identity Type ID | 14 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | profile_id | `STRING` | Associated profile ID. |
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |


### Amazon Attribution

This product requires a call to the service API to get the requisit information for the subscription product meta.

The first call that needs to be made is to the [Amazon Advertising profiles](service-api.md#amazon-advertising-profiles)  endpoint.  This endpoint will return a list of Amazon Advertising profiles based on the requested type.  This list will provide the `profile_id` meta data.  If you need more information to display you can request the brand information for the profiles by calling the [Amazon Advertising Profile Brands](service-api.md#amazon-advertising-profile-brands)  endpoint.  You can pass up to five profile IDs to retrieve their brand information simultaniously.  If you had more than five profiles you would need to iterate through them in groups of five to get them all.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 50 |
> | Remote Identity Type ID | 14 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | profile_id | `STRING` | Associated profile ID. |
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

## Amazon Seller Products

### Amazon Orders API

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 53 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Finance Real-Time

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 55 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Inbound Fulfillment

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 56 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Settlement Reports

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 57 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Fulfillment

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 58 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Inventory

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 60 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Sales Reports

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 61 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Fees

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 62 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Sales & Traffic

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 64 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Seller Brand Analytics Reports

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 65 |
> | Remote Identity Type ID | 17 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

## Amazon Vendor Products

### Amazon Vendor Retail Analytics

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 66 |
> | Remote Identity Type ID | 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Vendor Retail Procurement

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 67 |
> | Remote Identity Type ID | 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Vendor Brand Analytics Reports

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 69 |
> | Remote Identity Type ID | 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

### Amazon Vendor Real-time Reports

This product does not require any additional calls to the openbridge service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 72 |
> | Remote Identity Type ID | 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

#### Amazon Catalog Keyword Tracker

Amazon Catalog Keyword Tracker requires no additional API lookups with the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 82 |
> | Remote Identity Type ID | 17 or 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | keywords | `STRING` | A stringified JSON array of keywords.  The limit is 100 keywords to prevent Amazon API rate limiting.  Subscriptions with more than 100 may fail to generate reports. |
> | subproduct_id | `STRING` | This product requires a subproduct id which will always be the string `keywords`. |

### Amazon Catalog API

Amazon Catalog API requires no additional API lookups with the Openbridge Service API.  However, it is recommended that when choosing the `id_type` of `ASIN` that you use the Openbridge Service API for validating `ASIN` numbers if you are not 100% sure the ASINs you are providing are correct.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 82 |
> | Remote Identity Type ID | 17 or 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | ids | `STRING` | A stringified JSON array of ids of the type defined by `id_type`.  The limit should be 100 ids to prevent Amazon API rate limiting. Subscriptions with more than 100 may fail to generate reports. |
> | identity_type | `STRING` | `seller` or `vendor` depending if the identity type is a seller or a vendor identity. |
> | id_type | `STRING` | The catalog API can be used to request reports on different types of identifiers.  `ASIN`,`EAN`, `GTIN`, `ISBN`, `JAN`, `MINSAN`, `SKU`, and `UPC`.  <strong>Note</strong>: that `SKU` types can not be used with `vendor` type identities due to permission restrictions. |
> | subproduct_id | `STRING` | This product requires a subproduct id which will always be the string `identifiers`. |

## Facebook Products

### Facebook Marketing

Facebook marketing requires a Facebook Ad account ID that is connected to the authorized identity attached to the subscription.  A list of available Facebook Ad account IDs can be requested with the [Facebook Ads](service-api.md#facebook-ads) endpoint on the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 11 |
> | Remote Identity Type ID | 2 |

> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | ad_account_id | `STRING` | Facebook marketing account ID. |

### Facebook Page Insights

Facebook marketing requires a Facebook Page account ID that is connected to the authorized identity attached to the subscription.  A list of available Facebook Page account IDs can be requested with the [Facebook Page Profiles](service-api.md#facebook-page-profiles) endpoint on the Openbridge Service API.
__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 2 |
> | Remote Identity Type ID | 2 |

> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | account_id | `STRING` | Facebook page account ID. |

### Instagram Insights

Instagram Insights requires a Instagram account ID that is connected to the authorized identity attached to the subscription.  As well as the Facebook page ID that the instagram account is connected too.  A list of available Facebook Page account IDs and their attached Instagram Account Ids can be requested with the [Facebook Page Profiles](service-api.md#facebook-page-profiles) endpoint on the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 34 |
> | Remote Identity Type ID | 2 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | account_id | `STRING` | Instagram account ID. |
> | fb_account_id | `STRING` | Facebook page account ID. |

### Instagram Stories

Instagram Stories requires a Instagram account ID that is connected to the authorized identity attached to the subscription.  As well as the Facebook page ID that the instagram account is connected too.  A list of available Facebook Page account IDs and their attached Instagram Account Ids can be requested with the [Facebook Page Profiles](service-api.md#facebook-page-profiles) endpoint on the Openbridge Service API.


__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 38 |
> | Remote Identity Type ID | 2 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | account_id | `STRING` | Instagram account ID. |
> | fb_account_id | `STRING` | Facebook page account ID. |

## Google Products

### Google Ads

Google Ads requires a manager customer ID and client customer ID associated with the remote identity attached to the subsciption.   A list of available manager customer and client customer IDs can be requested from the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 63 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | manager_customer_id | `STRING` | The manager id that manages the client_customer_id. |
> | client_customer_id | `STRING` | The client's customer id where the reports reside. |

### Google Analytics 360

Google Analytics 360 requires a project ID and dataset ID associated with the remote identity attached to the subsciption.   A list of available project and dataset IDs can be requested with the [Google Ads](service-api.md#google-ads) endpoint on the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 3 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | project_id | `STRING` | Project ID associated with the Google BigQuery associated with the Google Analytics account. |
> | dataset_id | `STRING` | Dataset ID associated with the Google BigQuery associated with the Google Analytics account. |

### Google Campaign Manager

Google Campaign Manager requires a profile ID and report ID associated with the remote identity attached to the subsciption.   A list of available profile can be requested with the [Google Campaign Manager Profiles](service-api.md#google-campaign-manager-reports) endpoint on the Openbridge Service API and report IDs can be requested with the [Google Campaign Manager Profiles](service-api.md#google-campaign-manager-reports) endpoint

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 4 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | dfa_profile_id | `STRING` | Campaign Manager profile ID. |
> | dfa_report_id | `STRING` | Campaign report ID. |

### Google Search Ads 360

Google Search Ads 360 requires a profile ID and report ID associated with the remote identity attached to the subsciption.   A list of available profile and report IDs can be requested with the [Google Search Ads 360](service-api.md#google-search-ads-360) endpoint on the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 7 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | agency_id | `STRING` | Agency id associated with the desired reports. |
> | advertiser_id | `STRING` | Advertiser id associated with the desired reports. |

## Shopify

Shopify 360 requires the shop creation date associated with the remote identity attached to the subsciption. Shopify info can be requested with the [Shopify Info](service-api.md#shopify-info) endpoint on the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 44 |
> | Remote Identity Type ID | 16 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | shop_created_at | `STRING` | THe shop creation date in the format of YYYY-mm-dd example 2010-03-01 for March 1st 2010.  This information is provided by the shop info endpoint.  |

## Youtube Products

### Youtube Channel Insights

Youtube Channel Insights requires a channgel ID associated with the remote identity attached to the subsciption.   A list of available channgel ID can be requested from the Openbridge Service API.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 17 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | channel_id | `STRING` | Youtube associated channel ID. |

### Youtube Competitor Channels

Youtube Competitor Channels requires a list of channel ids as a stringified JSON array.  The Openbridge service API allows you to get youtube channel IDs based on various Youtube URLs.  You can provide a maximum of 7 IDs per subscription.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 18 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | channel_ids | `JSON` | Remote identity associated with the associated profile. |

### Youtube Competitor Videos

Youtube Competitor Channels requires a list of channel ids as a stringified JSON array.  The Openbridge service API allows you to get youtube channel IDs based on various Youtube URLs.  You can provide a maximum of 7 IDs per subscription.

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 15 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | channel_ids | `JSON` | Remote identity associated with the associated profile. |

### Youtube Video Insights

Youtube Video Insights requires a channgel ID associated with the remote identity attached to the subsciption.   A list of available channgel ID can be requested from the Openbridge Service API.


__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 26 |
> | Remote Identity Type ID | 1 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | channel_id | `STRING` | Youtube associated channel ID. |


