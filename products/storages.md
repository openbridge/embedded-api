# Destinations

## Overview

Every Openbridge source subscription writes data to a **destination** — a data warehouse or cloud storage target that you configure and attach to one or more source subscriptions. A source subscription cannot deliver data without a destination.

Destinations are created via the [Openbridge Destinations API](../api-usage-docs/service-ob-api.md). The `storage` field in the request body determines which storage system is targeted and which credential fields are required.

---

## Common fields

These fields appear across all storage types.

> **Encryption is automatic.** Sensitive credential fields are encrypted server-side based on the storage type. Pass all field values as plain strings — no client-side wrapping required.

| Field | Type | Required | Description |
|---|---|---|---|
| `storage` | string | Yes | Storage type identifier (e.g. `"redshift"`) |
| `s3_bucket` | string | Yes | Openbridge-managed S3 staging bucket. Should be set to `"openbridge-zeroadmin-production"` in most cases. |
| `region` | string | No | AWS region of the staging bucket. Should be set to `"us-east-1"` in most cases. |

---

## Supported destinations

### Amazon Redshift (`redshift`)

See [our Amazon Redshift setup documentation](https://docs.openbridge.com/en/articles/1427334-configuring-your-amazon-redshift-data-warehouse-environment) for instructions for configuring your Redshift environment.

| Field | Type | Required | Description |
|---|---|---|---|
| `database` | string | Yes | Redshift database name |
| `port` | string | Yes | Redshift port (typically `5439`) |
| `host` | string | Yes | Redshift cluster endpoint |
| `user` | string | Yes | Database user |
| `password` | string | Yes | Database password |

---

### Amazon Athena (`athena`)

See [our Amazon Athena setup documentation](https://docs.openbridge.com/en/articles/1856980-how-to-set-up-amazon-athena-data-destination) for instructions for setting up Athena as a destination.

| Field | Type | Required | Description |
|---|---|---|---|
| `athena_bucket` | string | Yes | S3 bucket for Athena query results |
| `athena_database` | string | Yes | Athena database name |
| `athena_region` | string | Yes | AWS region where Athena is configured |
| `athena_access_key_id` | string | Yes | AWS access key ID |
| `athena_secret_access_key` | string | Yes | AWS secret access key |

---

### Amazon Redshift Spectrum (`spectrum`)

See [our Amazon Redshift Spectrum setup documentation](https://docs.openbridge.com/en/articles/1852484-how-to-setup-amazon-redshift-spectrum-data-destination) for instructions for setting up Redshift Spectrum as a destination.

Extends Redshift with an external S3-backed schema. Requires both standard Redshift connection credentials and Spectrum-specific parameters.

| Field | Type | Required | Description |
|---|---|---|---|
| `database` | string | Yes | Redshift database name |
| `port` | string | Yes | Redshift port |
| `host` | string | Yes | Redshift cluster endpoint |
| `user` | string | Yes | Database user |
| `password` | string | Yes | Database password |
| `spectrum_bucket` | string | Yes | S3 bucket for the Spectrum external schema |
| `spectrum_database` | string | Yes | Spectrum external database name |
| `spectrum_iam_role` | string | Yes | IAM role ARN with access to the Spectrum bucket |
| `spectrum_region` | string | Yes | AWS region of the Spectrum S3 bucket |
| `spectrum_schema` | string | Yes | Spectrum schema name |
| `spectrum_access_key_id` | string | Yes | AWS access key ID for Spectrum |
| `spectrum_secret_access_key` | string | Yes | AWS secret access key for Spectrum |

---

### Google BigQuery (`bigquery`)

See [our BigQuery setup documentation](https://docs.openbridge.com/en/articles/1872762-how-to-setup-a-google-bigquery-data-destination) for instructions for configuring your BigQuery instance.


| Field | Type | Required | Description |
|---|---|---|---|
| `bigquery_dataset_id` | string | Yes | BigQuery dataset ID |
| `bigquery_project_id` | string | Yes | GCP project ID |
| `remote_identity_id` | integer | Yes | ID of the Remote Identity containing credentials used to access the BigQuery instance. |

---

### Azure Blob Storage (`azure_blob`)

See [our Azure Blob Storage setup documentation](https://docs.openbridge.com/en/articles/5196085-how-to-create-azure-blob-storage-data-destination) for instructions for creating an Azure Blob Storage destination.

| Field | Type | Required | Description |
|---|---|---|---|
| `container` | string | Yes | Azure Blob container name |
| `connection_string` | string | Yes | Azure storage connection string |

---

### Azure Data Lake (`azure_datalake`)

See [our Azure Data Lake setup documentation](https://docs.openbridge.com/en/articles/4384989-configuring-your-azure-data-lake-storage-data-destination) for instructions for configuring your Azure Data Lake destination.

| Field | Type | Required | Description |
|---|---|---|---|
| `container` | string | Yes | Azure Data Lake container name |
| `connection_string` | string | Yes | Azure storage connection string |
| `dt_partition` | boolean | No | Enable datetime-based partitioning |

---

### Databricks (`databricks`)

Databricks destination using S3-backed Delta tables.

See [our Databricks setup documentation](https://docs.openbridge.com/en/articles/6804269-how-to-setup-databricks-lakehouse) for instructions for setting up Databricks as a destination.

| Field | Type | Required | Description |
|---|---|---|---|
| `databricks_server_hostname` | string | Yes | Databricks workspace hostname |
| `databricks_http_path` | string | Yes | SQL warehouse or cluster HTTP path |
| `databricks_access_token` | string | Yes | Databricks personal access token |
| `databricks_schema` | string | Yes | Target schema (nullable) |
| `databricks_catalog` | string | Yes | Unity Catalog name (nullable) |

---

### Databricks — external tables (`databricks_external`)

Databricks destination using externally managed ADLS storage.

See [our Databricks external tables setup documentation](https://docs.openbridge.com/en/articles/7225154-configure-databricks-external-locations) for instructions for configuring Databricks external locations.

| Field | Type | Required | Description |
|---|---|---|---|
| `databricks_server_hostname` | string | Yes | Databricks workspace hostname |
| `databricks_http_path` | string | Yes | SQL warehouse or cluster HTTP path |
| `databricks_access_token` | string | Yes | Databricks personal access token |
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
| `databricks_adls_connection_string` | string | Azure Data Lake connection string |
| `databricks_adls_container` | string | ADLS container name |

---

### Snowflake — username/password or programmatic access token (PAT) (`snowflake`)

See [our Snowflake setup documentation](https://docs.openbridge.com/en/articles/5024964-how-to-setup-snowflake-data-destination) for instructions for configuring your Snowflake instance.

| Field | Type | Required | Description |
|---|---|---|---|
| `snowflake_account` | string | Yes | Snowflake account identifier |
| `snowflake_user` | string | Yes | Snowflake username |
| `snowflake_password` | string | Yes | Snowflake password or PAT |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_use_clustering` | boolean | Yes | Enable `CLUSTER BY` on destination tables |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as Snowflake external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the Snowflake S3 stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | string | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | string | No | AWS secret key for the S3 stage |

---

### Snowflake — OAuth with S3 stage, clustering (`snowflake_oauth`)

OAuth credentials (client ID, client secret, refresh token) must be registered as a Remote Identity before creating this destination. Pass the Remote Identity's ID via `remote_identity_id`.

See [our Snowflake setup documentation](https://docs.openbridge.com/en/articles/11822520-snowflake-warehouse-with-oauth-authentication) for instructions for configuring your Snowflake instance.

| Field | Type | Required | Description |
|---|---|---|---|
| `remote_identity_id` | integer | Yes | ID of the Remote Identity containing the Snowflake OAuth credentials |
| `snowflake_account` | string | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_use_clustering` | boolean | Yes | Enable `CLUSTER BY` on destination tables |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the S3 stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | string | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | string | No | AWS secret key for the S3 stage |

---

### Snowflake — OAuth with S3 external stage (`snowflake_ext_s3`)

This is a variant of [Snowflake OAuth](#snowflake--oauth-with-s3-stage-clustering-snowflake_oauth) which stores data in a user-specified S3 bucket.

OAuth credentials (client ID, client secret, refresh token) must be registered as a Remote Identity before creating this destination. Pass the Remote Identity's ID via `remote_identity_id`.

See [our Snowflake setup documentation](https://docs.openbridge.com/en/articles/11822520-snowflake-warehouse-with-oauth-authentication) for instructions for configuring your Snowflake instance.

| Field | Type | Required | Description |
|---|---|---|---|
| `remote_identity_id` | integer | Yes | ID of the Remote Identity containing the Snowflake OAuth credentials |
| `snowflake_account` | string | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_s3_bucket` | string | Yes | S3 bucket used as external stage |
| `snowflake_s3_region` | string | Yes | AWS region of the S3 stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_aws_access_key_id` | string | No | AWS access key for the S3 stage |
| `snowflake_aws_secret_access_key` | string | No | AWS secret key for the S3 stage |

---

### Snowflake — OAuth with Azure external stage (`snowflake_ext_az`)

This is a variant of [Snowflake OAuth](#snowflake--oauth-with-s3-stage-clustering-snowflake_oauth) which stores data in a user-specified Microsoft Azure data lake.

OAuth credentials (client ID, client secret, refresh token) must be registered as a Remote Identity before creating this destination. Pass the Remote Identity's ID via `remote_identity_id`.

See [our Snowflake setup documentation](https://docs.openbridge.com/en/articles/11999093-snowflake-data-lake-azure-integration) for instructions for configuring Snowflake + Azure.

| Field | Type | Required | Description |
|---|---|---|---|
| `remote_identity_id` | integer | Yes | ID of the Remote Identity containing the Snowflake OAuth credentials |
| `snowflake_account` | string | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_az_container` | string | Yes | Azure container used as external stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |
| `snowflake_az_connection_string` | string | No | Azure storage connection string for the stage |

---

### Snowflake — OAuth with GCS external stage (`snowflake_ext_gcs`)

This is a variant of [Snowflake OAuth](#snowflake--oauth-with-s3-stage-clustering-snowflake_oauth) which stores data in a user-specified Google Cloud storage bucket.

OAuth credentials (client ID, client secret, refresh token) must be registered as a Remote Identity before creating this destination. Pass the Remote Identity's ID via `remote_identity_id`.

See [our Snowflake setup documentation](https://docs.openbridge.com/en/articles/11998892-snowflake-data-lake-gcs-integration) for instructions for configuring Snowflake + GCS.

| Field | Type | Required | Description |
|---|---|---|---|
| `remote_identity_id` | integer | Yes | ID of the Remote Identity containing the Snowflake OAuth credentials |
| `snowflake_account` | string | Yes | Snowflake account identifier |
| `snowflake_database` | string | Yes | Target database |
| `snowflake_warehouse` | string | Yes | Compute warehouse |
| `snowflake_schema` | string | Yes | Target schema |
| `snowflake_gcs_bucket` | string | Yes | GCS bucket used as external stage |
| `snowflake_gcs_service_account` | string | Yes | GCS service account email for the stage |
| `snowflake_stage` | string | Yes | Snowflake stage name |
| `snowflake_role` | string | No | Snowflake role to assume |

---

## FAQ

### Do I need to create a Remote Identity before creating a destination?

Yes, for destination types that accept a `remote_identity_id` field (such as `bigquery`, `bigquery_date`, `snowflake_oauth`, `snowflake_ext_s3`, `snowflake_ext_az`, and `snowflake_ext_gcs`), the Remote Identity must exist before you create the destination. Remote Identity creation is handled through the Openbridge UI and OAuth flow — it cannot be created via this API. Once the identity has been authorized, retrieve its ID and pass it as `remote_identity_id` in your destination request.

See the [Remote Identity API](../api-usage-docs/remote-identity-api.md) for how to list and look up existing identities.

### How long can I expect the destination creation process to complete?

The runtime of this operation can vary depending on the storage type, destination-specific settings and system load. The process will typically complete in 30-90 seconds, but it can take up to 15 minutes to complete.
