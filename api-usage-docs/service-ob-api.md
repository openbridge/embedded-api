# Service API: Openbridge Destinations

## When to use

Use these endpoints to provision a new Openbridge destination (data warehouse or storage target) tied to the authenticated user's account. The creation flow is asynchronous: the initial request validates the supplied storage credentials and returns immediately with a `202 Accepted`, then a polling endpoint lets you track progress until the destination subscription is ready.

---

## Prerequisites

- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoints

### Create a destination

```
POST /service/ob/destination
```

Initiates destination creation. Validates the storage credentials against the target storage system, then creates a permanent account mapping and subscription when validation succeeds.

**Example request**

```http
POST https://service.api.openbridge.io/service/ob/destination
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "name": "My Redshift Destination",
  "storage_parameters": {
    "storage": "redshift",
    "remote_identity_id": 0
  }
}
```

---

### Poll destination status

```
GET /service/ob/destination/{co_id}
```

| Path parameter | Description |
|---|---|
| `co_id` | The operation ID returned in the `Location` header of the create response |

Poll this endpoint after receiving a `202` from the create call. Repeat until the response is `200` (success) or `400` (failure).

**Example request**

```http
GET https://service.api.openbridge.io/service/ob/destination/42
Authorization: Bearer <jwt>
```

---

## Request body

`POST /service/ob/destination` accepts a JSON body with the following fields.

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Display name for the destination |
| `storage_parameters` | object | Yes | Storage connection details — see below |
| `storage_parameters.storage` | string | Yes | Storage type identifier — see supported values below |
| `storage_parameters.remote_identity_id` | integer | No | ID of a stored remote identity whose credentials will be merged into `storage_parameters`. Omit or set to `0` when supplying credentials directly. |

Additional keys inside `storage_parameters` depend on the storage type and are passed through to the account mapping and storage validation services.

**Supported `storage` values**

See [Storages](../products/storages.md) for all supported storage types and their required fields.

---

## Responses

### Create destination — `202 Accepted`

Returned immediately after the storage validation job is queued.

| Element | Description |
|---|---|
| `Location` header | URL to poll for status: `/ob/destination/{co_id}` |
| `data.type` | Always `"OpenbridgeDestination"` |
| `data.attributes.status` | Initial status; always `"PENDING"` |
| `data.attributes.accmapping_path` | Internal path of the temporary account mapping |
| `data.attributes.storage_id` | ID of the storage validation job |

**Example**

```json
{
  "data": {
    "type": "OpenbridgeDestination",
    "attributes": {
      "status": "PENDING",
      "accmapping_path": "/ebs/ftpd/a1b2c3d4e5f6-000042",
      "storage_id": "789"
    }
  }
}
```

---

### Poll destination status responses

**`202 Accepted` — still processing**

Returned while storage validation is running. The `status` field will be `"PENDING"` or `"PROCESSING"`. Continue polling.

```json
{
  "data": {
    "type": "OpenbridgeDestination",
    "attributes": {
      "status": "PROCESSING",
      "accmapping_path": "/ebs/ftpd/a1b2c3d4e5f6-000042",
      "storage_id": "789"
    }
  }
}
```

**`200 OK` — destination ready**

Returned when storage validation succeeded and the subscription was created. The response body is the newly created subscription record.

**`400 Bad Request` — failed**

Returned when validation or subscription creation fails. The body contains an `errors` array.

| Field | Type | Description |
|---|---|---|
| `errors[].message` | string | Human-readable description of the error |
| `errors[].code` | string | Machine-readable error code (e.g. `"UNKNOWN_STATUS"`) |

```json
[
  {
    "message": "An error occurred when testing the account mapping",
    "code": "BUCKET_NOT_FOUND"
  }
]
```

**`403 Forbidden`**

The `co_id` exists but does not belong to the authenticated account.

---

## Async flow

```
POST /service/ob/destination
  → 202 Accepted
  → Location: /service/ob/destination/{co_id}

GET /service/ob/destination/{co_id}   ← repeat until terminal status
  → 202 Accepted (status: PENDING | PROCESSING)  ← continue polling
  → 200 OK                                        ← done; subscription created
  → 400 Bad Request                               ← done; storage validation failed
```
