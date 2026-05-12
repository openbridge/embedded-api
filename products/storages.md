# Destinations

## Overview

Every Openbridge source subscription writes data to a **destination** — a data warehouse or cloud storage target that you configure and attach to one or more source subscriptions. A source subscription cannot deliver data without a destination.

Destinations are created via the [Openbridge Destinations API](../api-usage-docs/service-ob-api.md). The `storage` field in the request body determines which storage system is targeted and which credential fields are required.

---

## Encrypted fields

Sensitive credential fields are not passed as plain strings. They must be wrapped in an encrypted object:

```json
{
  "encrypt": "kms",
  "value": "<your-secret-value>"
}
```

Fields that require this format are marked **encrypted** in the tables below.

---

## Common fields

These fields appear across all storage types.

| Field | Type | Required | Description |
|---|---|---|---|
| `storage` | string | Yes | Storage type identifier (e.g. `"redshift"`) |
| `s3_bucket` | string | Yes | Openbridge-managed S3 staging bucket. Should be set to `"openbridge-zeroadmin-production"` in most cases. |
| `region` | string | No | AWS region of the staging bucket. Should be set to `"us-east-1"` in most cases. |

---

## Supported destinations

### Amazon Redshift (`redshift`)

| Field | Type | Required | Description |
|---|---|---|---|
| `database` | string | Yes | Redshift database name |
| `port` | string | Yes | Redshift port (typically `5439`) |
| `host` | encrypted | Yes | Redshift cluster endpoint |
| `user` | encrypted | Yes | Database user |
| `password` | encrypted | Yes | Database password |

---

### Amazon Athena (`athena`)

| Field | Type | Required | Description |
|---|---|---|---|
| `athena_bucket` | string | Yes | S3 bucket for Athena query results |
| `athena_database` | string | Yes | Athena database name |
| `athena_region` | string | Yes | AWS region where Athena is configured |
| `athena_access_key_id` | encrypted | Yes | AWS access key ID |
| `athena_secret_access_key` | encrypted | Yes | AWS secret access key |

---

### Amazon Redshift Spectrum (`spectrum`)

Extends Redshift with an external S3-backed schema. Requires both standard Redshift connection credentials and Spectrum-specific parameters.

| Field | Type | Required | Description |
|---|---|---|---|
| `database` | string | Yes | Redshift database name |
| `port` | string | Yes | Redshift port |
| `host` | encrypted | Yes | Redshift cluster endpoint |
| `user` | encrypted | Yes | Database user |
| `password` | encrypted | Yes | Database password |
| `spectrum_bucket` | string | Yes | S3 bucket for the Spectrum external schema |
| `spectrum_database` | string | Yes | Spectrum external database name |
| `spectrum_iam_role` | string | Yes | IAM role ARN with access to the Spectrum bucket |
| `spectrum_region` | string | Yes | AWS region of the Spectrum S3 bucket |
| `spectrum_schema` | string | Yes | Spectrum schema name |
| `spectrum_access_key_id` | encrypted | Yes | AWS access key ID for Spectrum |
| `spectrum_secret_access_key` | encrypted | Yes | AWS secret access key for Spectrum |

---

### Google BigQuery (`bigquery`)

| Field | Type | Required | Description |
|---|---|---|---|
| `bigquery_dataset_id` | string | Yes | BigQuery dataset ID |
| `bigquery_project_id` | string | Yes | GCP project ID |
| `bigquery_service_account` | encrypted | No | Service account JSON key |

---

### Google BigQuery — date-partitioned (`bigquery_date`)

Same base fields as `bigquery`. Exactly one authentication method must be provided.

**Base fields:**

| Field | Type | Required |
|---|---|---|
| `bigquery_dataset_id` | string | Yes |
| `bigquery_project_id` | string | Yes |

**Option A — Service account:**

| Field | Type | Description |
|---|---|---|
| `bigquery_service_account` | encrypted | Service account JSON key |

**Option B — OAuth2:**

| Field | Type | Description |
|---|---|---|
| `oauth2_access_token` | encrypted | OAuth2 access token |
| `oauth2_client_id` | encrypted | OAuth2 client ID |
| `oauth2_client_secret` | encrypted | OAuth2 client secret |
| `oauth2_refresh_token` | encrypted | OAuth2 refresh token |

---

### Azure Blob Storage (`azure_blob`)

| Field | Type | Required | Description |
|---|---|---|---|
| `container` | string | Yes | Azure Blob container name |
| `connection_string` | encrypted | Yes | Azure storage connection string |

---

### Azure Data Lake (`azure_datalake`)

| Field | Type | Required | Description |
|---|---|---|---|
| `container` | string | Yes | Azure Data Lake container name |
| `connection_string` | encrypted | Yes | Azure storage connection string |
| `dt_partition` | boolean | No | Enable datetime-based partitioning |

---

### Databricks (`databricks`)

Databricks destination using S3-backed Delta tables.

| Field | Type | Required | Description |
|---|---|---|---|
| `databricks_server_hostname` | string | Yes | Databricks workspace hostname |
| `databricks_http_path` | encrypted | Yes | SQL warehouse or cluster HTTP path |
| `databricks_access_token` | encrypted | Yes | Databricks personal access token |
| `databricks_schema` | string | Yes | Target schema (nullable) |
| `databricks_catalog` | string | Yes | Unity Catalog name (nullable) |

---

### Databricks — external tables (`databricks_external`)

Databricks destination using externally managed ADLS storage.

| Field | Type | Required | Description |
|---|---|---|---|
| `databricks_server_hostname` | string | Yes | Databricks workspace hostname |
| `databricks_http_path` | encrypted | Yes | SQL warehouse or cluster HTTP path |
| `databricks_access_token` | encrypted | Yes | Databricks personal access token |
| `databricks_schema` | string | Yes | Target schema (nullable) |
| `databricks_catalog` | string | Yes | Unity Catalog name (nullable) |
| `databricks_storage_format` | string | Yes | External storage format; currently only `"adls"` |
| `databricks_credentials_name` | string | Yes | Databricks storage credential name (nullable) |
| `databricks_bucket_uri` | string | Yes | External storage URI (e.g. `abfss://<container>@<account>`) |
| `databricks_path_prefix` | string | Yes | Path prefix within the external storage |
| `databricks_use_clustering` | boolean | Yes | Enable Databricks liquid clustering |
| `databricks_use_partitioning` | boolean | Yes | Enable table partitioning |
| `databricks_partition_format` | string | No | Partition date format string (default: `%Y-%m-%d`) |

When `databricks_storage_format` is `"adls"`, these additional fields are required:

| Field | Type | Description |
|---|---|---|
| `databricks_adls_connection_string` | encrypted | Azure Data Lake connection string |
| `databricks_adls_container` | string | ADLS container name |

---

### Snowflake — username/password (`snowflake`)

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | encrypted | Yes | Snowflake account identifier |
| `snowflake_user` | encrypted | Yes | Snowflake username |
| `snowflake_password` | encrypted | Yes | Snowflake password or PAT |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_use_clustering` | boolean | Yes | Enable `CLUSTER BY` on destination tables |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as Snowflake external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the Snowflake S3 stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | encrypted | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | encrypted | No | AWS secret key for the S3 stage |

---

### Snowflake — OAuth with S3 stage (`snowflake_ext_s3`)

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | encrypted | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the S3 stage |
| `snowflake_refresh_token` | encrypted | Yes | Snowflake OAuth refresh token |
| `snowflake_client_id` | encrypted | Yes | Snowflake OAuth client ID |
| `snowflake_client_secret` | encrypted | Yes | Snowflake OAuth client secret |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | encrypted | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | encrypted | No | AWS secret key for the S3 stage |

---

### Snowflake — OAuth with Azure external stage (`snowflake_ext_az`)

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | encrypted | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_az_container` | string | Yes | Azure container used as external stage |
| `snowflake_refresh_token` | encrypted | Yes | Snowflake OAuth refresh token |
| `snowflake_client_id` | encrypted | Yes | Snowflake OAuth client ID |
| `snowflake_client_secret` | encrypted | Yes | Snowflake OAuth client secret |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_az_connection_string` | encrypted | No | Azure storage connection string for the stage |

---

### Snowflake — OAuth with GCS external stage (`snowflake_ext_gcs`)

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | encrypted | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_gcs_bucket` | string | Yes | GCS bucket used as external stage |
| `snowflake_gcs_service_account` | string | Yes | GCS service account email for the stage |
| `snowflake_refresh_token` | encrypted | Yes | Snowflake OAuth refresh token |
| `snowflake_client_id` | encrypted | Yes | Snowflake OAuth client ID |
| `snowflake_client_secret` | encrypted | Yes | Snowflake OAuth client secret |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |

---

### Snowflake — OAuth with S3 stage, clustering (`snowflake_oauth`)

Variant of `snowflake_ext_s3` with `snowflake_use_clustering` as an explicit required field.

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | encrypted | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_use_clustering` | boolean | Yes | Enable `CLUSTER BY` on destination tables |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the S3 stage |
| `snowflake_refresh_token` | encrypted | Yes | Snowflake OAuth refresh token |
| `snowflake_client_id` | encrypted | Yes | Snowflake OAuth client ID |
| `snowflake_client_secret` | encrypted | Yes | Snowflake OAuth client secret |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | encrypted | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | encrypted | No | AWS secret key for the S3 stage |

---

### PostgreSQL (`postgres`)

| Field | Type | Required | Description |
|---|---|---|---|
| `destination_s3_region` | string | Yes | AWS region of the customer-owned S3 staging bucket |
| `destination_s3_bucket` | string | Yes | Customer-owned S3 bucket for staging |
| `host` | string | Yes | PostgreSQL host |
| `user` | string | Yes | Database user |
| `password` | encrypted | Yes | Database password |
| `database` | string | No | Database name |
| `port` | string | No | PostgreSQL port (default: `5432`) |
| `iam_role` | string | No | AWS IAM role ARN |
