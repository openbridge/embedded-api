# Rate Limiting

Openbridge APIs enforce rate limits to ensure fair usage and service stability. When a limit is exceeded the API returns `429 Too Many Requests`. Clients must handle this response and back off before retrying.

---

## Limits

| Scope | Limit | Window |
|---|---|---|
| Per IP address | 1,000 requests | 5 minutes (rolling) |

---

## Response Headers

Rate-limit headers are only present on `429` responses:

| Header | Value | Description |
|---|---|---|
| `Retry-After` | `60` | Seconds to wait before retrying |

No per-request quota headers (`X-RateLimit-Remaining`, etc.) are included in normal responses.

---

## Error Response

A rate-limited request returns `HTTP 429` with a JSON body:

```json
{
  "errors": [
    {
      "status": "429",
      "title": "Too Many Requests",
      "detail": "Rate limit exceeded. Retry after 60 seconds."
    }
  ]
}
```

---

## Retry Strategy

Do not retry immediately after receiving a `429`. Wait at least the `Retry-After` value (60 seconds), then apply exponential backoff with jitter for subsequent failures.

### Recommended algorithm

1. On `429`, wait 60 seconds (`Retry-After` header value).
2. For each subsequent failure, double the wait time up to a maximum of 5 minutes.
3. Add random jitter (±10–20%) to avoid synchronized retries from multiple clients.
4. After a configurable number of retries (recommended: 5), surface the error to the caller.

### Example — Python

```python
import time
import random
import requests

def request_with_backoff(method, url, **kwargs):
    max_retries = 5
    wait = 60  # matches Retry-After

    for attempt in range(max_retries):
        response = requests.request(method, url, **kwargs)

        if response.status_code != 429:
            return response

        jitter = wait * random.uniform(0.1, 0.2)
        sleep_time = wait + jitter

        if attempt < max_retries - 1:
            time.sleep(sleep_time)
            wait = min(wait * 2, 300)  # cap at 5 minutes
        else:
            response.raise_for_status()

    return response
```

### Example — JavaScript (Node.js)

```javascript
async function requestWithBackoff(url, options = {}, maxRetries = 5) {
  let wait = 60; // matches Retry-After

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const response = await fetch(url, options);

    if (response.status !== 429) {
      return response;
    }

    if (attempt === maxRetries - 1) {
      throw new Error(`Rate limit exceeded after ${maxRetries} retries`);
    }

    const jitter = wait * (0.1 + Math.random() * 0.1);
    const sleepMs = (wait + jitter) * 1000;

    await new Promise((resolve) => setTimeout(resolve, sleepMs));
    wait = Math.min(wait * 2, 300);
  }
}
```

---

## Best Practices

**Do not retry on other 4xx errors.** Retry logic should apply only to `429` and transient `5xx` responses. Retrying `400`, `401`, `403`, or `404` will not resolve those errors.

**Serialize bulk operations.** When creating multiple subscriptions or triggering multiple history requests, introduce a small delay between calls (e.g., 100–200 ms) rather than firing them all concurrently.

**Cache access tokens.** The Authentication API is rate-limited like all other APIs. Reuse JWT access tokens until they expire rather than exchanging the refresh token on every request. See [Authentication API](./authentication-api.md) for token lifetime details.

**Use idempotent requests safely.** If a `POST` request is interrupted before a response is received (not a `429`), look up whether the resource was created before retrying to avoid duplicates.

---

## Summary

| Scenario | Action |
|---|---|
| `429` received | Wait 60 seconds, then retry with exponential backoff |
| Repeated `429` after retries | Surface the error; do not retry indefinitely |
| Other `4xx` errors | Do not retry; inspect and fix the request |
