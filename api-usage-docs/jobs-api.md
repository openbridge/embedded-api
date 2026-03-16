# Jobs API

The Jobs API returns `Job` records that represent individual data pipeline execution runs for a subscription. Only jobs associated with the authenticated user's token are returned.

---

## Base URL

```
https://service.api.openbridge.io/service
```

---

## Authentication

All requests require a JWT access token passed as a Bearer token:

```
Authorization: Bearer {your_access_token}
```

Obtain an access token by posting your refresh token to the Authentication API. See [Authentication API](./authentication-api.md) for the full flow.

---

## Endpoints

### List Jobs

Returns a paginated list of jobs for the authenticated user.

```
GET https://service.api.openbridge.io/service/jobs/jobs
```

Common query filters:

- `subscription_ids={id}` — filter by subscription ID
- `id={id}` — filter by a single job ID
- `ids={id1},{id2}` — filter by multiple job IDs
- `page={n}` — page number
- `page_size={n}` — results per page
- `order_by={field}` — sort field (e.g., `id`)

**Example response:**

```json
{
  "links": {
    "first": "https://service.api.openbridge.io/service/jobs/jobs?page=1",
    "last": "https://service.api.openbridge.io/service/jobs/jobs?page=2",
    "next": "https://service.api.openbridge.io/service/jobs/jobs?page=2",
    "prev": ""
  },
  "data": [
    {
      "type": "Job",
      "id": "4100440",
      "attributes": {
        "report_date": "2026-02-22",
        "subscription_id": 123456,
        "valid_date_start": "2026-02-24",
        "valid_date_end": "2026-02-24",
        "status": "processed",
        "schedule": "25 11 * * *",
        "orig_schedule": "15 11 * * *",
        "request_start": 2,
        "request_end": 1,
        "created_at": "2026-02-24T07:25:33.852000Z",
        "modified_at": "2026-02-24T11:15:23.597000Z",
        "is_primary": false,
        "stage_id": 1022,
        "extra_context": "",
        "product_id": 70,
        "subproduct_id": "default"
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 2,
      "count": 1
    }
  }
}
```

---

### Get Job

Returns a single job record by ID.

```
GET https://service.api.openbridge.io/service/jobs/jobs/{job_id}
```

---

## Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique job ID |
| `subscription_id` | integer | The subscription this job belongs to |
| `product_id` | integer | Product ID associated with this job |
| `stage_id` | integer | Pipeline stage this job runs against |
| `subproduct_id` | string | Sub-product identifier within the product (e.g., `default`) |
| `report_date` | date | The date the data in this job covers |
| `valid_date_start` | date | Start of the validity window for this job |
| `valid_date_end` | date | End of the validity window for this job |
| `status` | string | Current job status (e.g., `processed`, `pending`, `failed`) |
| `schedule` | string | Cron expression for when this job is scheduled to run |
| `orig_schedule` | string | Original cron schedule before any adjustments |
| `request_start` | integer | Internal processing window start offset |
| `request_end` | integer | Internal processing window end offset |
| `is_primary` | boolean | Whether this is the primary job for its subscription and date |
| `extra_context` | string | Additional context passed to the job at runtime |
| `created_at` | datetime | When the job record was created |
| `modified_at` | datetime | When the job record was last updated |
