# Service API: Rules

## When to use

Use this endpoint to retrieve table schema information for a given data path. Rules records define the destination table name, column definitions (name, SQL type, default value), CSV dialect settings, and Redshift COPY parameters for a specific integration report. Query this endpoint when you need to inspect the expected schema for a path.

---

## Prerequisites

- A valid Bearer JWT in the `Authorization` header. See [Authentication API](./authentication-api.md).

---

## Endpoint

### Search rules by path

```
GET /service/rules/{environment}/v1/rules/search
```

| Path parameter | Description |
|---|---|
| `environment` | `prod` or `dev` |

**Example request**

```http
GET https://service.api.openbridge.io/service/rules/prod/v1/rules/search?path__icontains=google-adwords&latest=true
Authorization: Bearer <jwt>
```

---

## Query parameters

| Parameter | Description |
|---|---|
| `path` | Exact match on the data path (e.g. `google-adwords/adwords_account_performance`) |
| `path__icontains` | Case-insensitive substring search on the path |
| `version` | Exact version number |
| `latest` | Set to `true` to return only the highest version per unique path |

**Example: look up all paths for a specific integration**

```http
GET https://service.api.openbridge.io/service/rules/prod/v1/rules/search?path__icontains=google-adwords&latest=true
Authorization: Bearer <jwt>
```

**Example: look up a specific path and version**

```http
GET https://service.api.openbridge.io/service/rules/prod/v1/rules/search?path=google-adwords/adwords_account_performance&version=5
Authorization: Bearer <jwt>
```

---

## Response

Results are returned as a paginated JSON:API response.

**Top-level structure**

| Field | Type | Description |
|---|---|---|
| `links.first` | string | URL of the first page |
| `links.last` | string | URL of the last page |
| `links.next` | string | URL of the next page (empty string if none) |
| `links.prev` | string | URL of the previous page (empty string if none) |
| `data` | array | Array of Rules objects |
| `meta.pagination.page` | integer | Current page number |
| `meta.pagination.pages` | integer | Total number of pages |
| `meta.pagination.count` | integer | Total number of matching records |

**Rules object fields**

| Field | Type | Description |
|---|---|---|
| `type` | string | Always `"Rules"` |
| `id` | string | Composite identifier: `{account_id}/{path}/{version}` |
| `attributes.account_id` | string | Account identifier (`"DEFAULT"` for system-level rules) |
| `attributes.path` | string | Data path identifying the integration and report type (e.g. `google-adwords/adwords_account_performance`) |
| `attributes.version` | integer | Version number of this rules record |
| `attributes.rules` | object | Full rules definition — see below |
| `attributes.created_at` | datetime \| null | When the record was created |
| `attributes.modified_at` | datetime \| null | When the record was last updated |

---

## Rules object

The `attributes.rules` object contains the full schema and load configuration for the data path.

### Destination

| Field | Type | Description |
|---|---|---|
| `destination.tablename` | string | The destination table name in the data warehouse (e.g. `adwords_account_performance_v5`) |

### Schema fields

`rules.configuration.load.schema.fields` is an array describing each column in the destination table.

| Field | Type | Description |
|---|---|---|
| `name` | string | Column name |
| `type` | string | SQL data type (e.g. `VARCHAR (1024)`, `BIGINT`, `DOUBLE PRECISION`, `BOOLEAN`, `DATE`, `TIMESTAMP`) |
| `default` | string \| null | Default value expression, or `null` |
| `np_kind` | string | NumPy dtype character code used to derive the SQL type |
| `ob_field` | boolean | `true` for Openbridge-managed system columns; `false` for source data columns |

**Openbridge system columns** (`ob_field: true`) are appended to every table automatically:

| Column | Type | Description |
|---|---|---|
| `ob_transaction_id` | `varchar(256)` | Pipeline transaction identifier |
| `ob_file_name` | `varchar(2048)` | Source file name |
| `ob_processed_at` | `varchar(256)` | Processing timestamp |
| `ob_modified_date` | `TIMESTAMP` | Last modification timestamp (default: `getdate()`) |

### Dialect

The `rules.dialect` object describes the CSV parsing settings used to read source files.

| Field | Description |
|---|---|
| `delimiter` | Field delimiter character |
| `quotechar` | Quote character |
| `quoting` | Quote mode (0 = QUOTE_MINIMAL) |
| `doublequote` | Whether double-quoting is used for escaping |
| `encoding` | File encoding (e.g. `UTF-8`) |
| `lineterminator` | Line ending sequence |
| `skipinitialspace` | Whether to skip whitespace after the delimiter |

---

## Example response

```json
{
  "links": {
    "first": "https://service.api.openbridge.io/service/rules/rules/search?latest=true&page=1&path__icontains=google-adwords",
    "last": "https://service.api.openbridge.io/service/rules/rules/search?latest=true&page=1&path__icontains=google-adwords",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "Rules",
      "id": "DEFAULT/google-adwords/adwords_account_performance/5",
      "attributes": {
        "account_id": "DEFAULT",
        "path": "google-adwords/adwords_account_performance",
        "version": 5,
        "rules": {
          "destination": {
            "tablename": "adwords_account_performance_v5"
          },
          "configuration": {
            "load": {
              "schema": {
                "fields": [
                  {
                    "name": "account_currency_code",
                    "type": "VARCHAR (1024)",
                    "default": null,
                    "np_kind": "O",
                    "ob_field": false
                  },
                  {
                    "name": "clicks",
                    "type": "BIGINT",
                    "default": null,
                    "np_kind": "i",
                    "ob_field": false
                  },
                  {
                    "name": "ob_transaction_id",
                    "type": "varchar(256)",
                    "default": null,
                    "np_kind": "O",
                    "ob_field": true
                  },
                  {
                    "name": "ob_modified_date",
                    "type": "TIMESTAMP",
                    "default": "getdate()",
                    "np_kind": "O",
                    "ob_field": true
                  }
                ]
              },
              "prepend_headers": false
            }
          },
          "dialect": {
            "delimiter": ",",
            "quotechar": "\"",
            "quoting": 0,
            "doublequote": true,
            "encoding": "UTF-8",
            "lineterminator": "\r\n",
            "skipinitialspace": false
          },
          "meta": {
            "version": 5
          }
        },
        "created_at": null,
        "modified_at": null
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pages": 1,
      "count": 1
    }
  }
}
```
