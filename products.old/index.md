# Openbridge Products

This document provides information required when creating subscriptions for Openbridge products.

- [Amazon Advertising Products](#amazon-advertising-products)
  - [Amazon Advertizing (SB/SD)](#amazon-advertizing-sbsd)
  - [Amazon Advertizing (SP)](#amazon-advertizing-sp)
  - [Amazon Advertising Brand Metrics](#amazon-advertising-brand-metrics)
  - [Amazon Attribution](#amazon-attribution)
  - [Amazon DSP](#amazon-dsp)

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

### Amazon Advertizing (SB/SD)
__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 40 |
> | Remote Identity Type ID | 14 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | kdp_state | `STRING` | Value is always `default`, |
> | marketplace | `STRING` | Value is country code from the associated profile. |
> | profile_id | `STRING` | Associated profile ID. |
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | type | `STRING` | The Amazon Advertising account type associated with the profile. |


### Amazon Advertizing (SP)

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

### Amazon DSP

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 54 |
> | Remote Identity Type ID | 14 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | profile_id | `STRING` | Associated profile ID. This field is an empty string for Amazon managed accounts |
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |
> | account_id | `STRING` | Remote identity associated with the associated profile. |
> | managed | `STRING` | `true` for Amazon managed accounts `false` for non managed accounts . |
> | advertiser_ids | `JSON` | A stringified array of Attribution advertiser IDs.  In case of an Amazon managed accounts it should be an empty array `[]`. |


## Amazon Seller Products

### Amazon Orders API

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

__Product Attributes__
> | Key | Value |
> |-|-|
> | Product ID | 72 |
> | Remote Identity Type ID | 18 |

__Required Subscription Product Meta__
> | Data Key | Data Format Value | Data Value |
> |-|-|-|
> | remote_identity_id | `STRING` | Remote identity associated with the associated profile. |

## Facebook Products

### Facebook Marketing

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

### Google Analytics 360

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

### Google Ads

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

## Youtube Products

### Youtube Channel Insights

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


