# Healthchecks - Best Practices

Healthchecks are a useful tool for understanding the state of your subscriptions. Here are some bits of knowledge and recommendations for usage.

- Healthchecks are only updated every four hours. No state changes will be reported during that time period. As such, we recommend only requesting new results at this interval.
- In general, most subscriptions will not have any healthchecks. Only subscriptions which experience errors will return anything at all. Therefore, retrieving healthchecks for individual subscriptions independently is expensive and does not scale well.


Below is a Python script which incorporates our usage recommendations. The snippet requests all healthchecks linked to our account and groups them by subscription ID. 


```python
import requests
from datetime import datetime, timedelta
from itertools import groupby

ob_access_token = "YOUR_ACCESS_TOKEN"  # This should be the token used to access our APIs
account_id = "YOUR_ACCOUNT_ID"
yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S")
hc_url = f"https://service.api.openbridge.io/service/healthchecks/production/healthchecks/account/{account_id}"
query_string = f"?status=ERROR&page_size=100&modified_at__gte={yesterday}"  # This can be modified to your needs

# Request only healthchecks from the last 24 hours
headers = {"Authorization": "Bearer " + ob_access_token}
resp = requests.get(hc_url + query_string, headers=headers)
resp.raise_for_status()
response_body = resp.json()
healthchecks = response_body['results']

# Paginate through any remaining healthchecks
while response_body['links']['next']:
    resp = requests.get(response_body['links']['next'], headers=headers)
    resp.raise_for_status()
    response_body = resp.json()
    healthchecks.extend(response_body.get('results', []))
    

# Split healthchecks by subscription ID
healthchecks_by_sub = {}
for subscription_id, results in groupby(healthchecks, key=lambda x: x['subscription_id']):
    healthchecks_by_sub[subscription_id] = list(results)

# healthchecks_by_sub is now a simple JSON object split by subscription ID
```

From this point, any number of actions can be taken using the `healthchecks_by_sub` object. One option is to cache the results so they can be retrieved at will during the four hour window before healthchecks are updated again.
