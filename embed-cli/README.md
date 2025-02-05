

# `embed-cli` Overview
The `embed-cli` is a unified tool to manage Openbridge API services. It is designed to interact with a suite of Openbridge API endpoints, performing tasks such as:

- Creating and listing data pipeline jobs  
- Checking health reports  
- Retrieving acount and user information  
- Getting product metadata 

 The `embed-cli` packaged as a Docker based tool provides a packaged, easy-to-run collection of API operations. By containerizing `embed-cli`, you avoid installing dependencies locally and ensure that the runtime environment is consistent across different systems. 

## `embed-cli` Features

1. **Historical Data Retrieval**  
   - Query data for a single day, multiple days, or an entire range of dates.  
   - Retrieve subscription-based job history with optional stage filtering.

2. **User Account Management**  
   - Retrieve user information (e.g., user ID, account details).  
   - Requires valid authentication tokens.

3. **Health Checks**  
   - Retrieve and display health checks.  
   - Supports pagination for large result sets.

4. **Jobs Management**  
   - List existing jobs associated with a given subscription.  
   - Create new jobs, optionally specifying date ranges, subscriptions, and stages.  
   - Create jobs in bulk via CSV.

5. **Subscriptions Management**  
   - List subscriptions with pagination and filters (e.g., status).  
   - Update subscription details (e.g., status, storage group).

6. **Product Stages**  
   - Retrieve stage details for a given product.

8. **Configurable Logging and Debugging**  
   - Control logging verbosity and output locations.  
   - Environment variable–driven toggling of debug vs. production logging.

9. **Authentication**  
   - Supports both `AUTH_TOKEN` (JWT) and `REFRESH_TOKEN`.  
   - Environment variables or config file usage.

## Getting Started
There are two principal prerequisites to quickly use the API:

1. **API Access Approval**
2. **Docker Installation** to use `embed-cli`

### 1. API Access Approval
Access approval is required to use the Openbridge Embedded APIs. Only Openbridge customers with Premium or higher account plans are eligible for access. Contact Openbridge via the [official support portal](https://openbridge.zendesk.com) to request access. Customers who have been granted access to use the Embedded APIs will be given the `api-user` role to the owner of the account. Once Openbridge access has been granted, you will need to log out of the Openbridge app and then log back in. 

#### Create A Refresh Token
Once approved for API access, you will need to generate a refresh token to call the APIs. What is a refresh token? It is a long lived token that the `embed-cli` or your customer application will use to generate a JWT using the Openbridge authorization API. 

To create a refresh token you must have been granted the `api-user` role on your account. If you have this role, log into the Openbridge app. In the main menu and select `Account` and you will be presented with a `API Management` menu option to navigate you to the refresh token management page. Click on the `"Create Refresh Token"` button. A modal will present itself where you will need to choose a name for the token. Click the `Create` button and your token will be generated, and presented to you. 

**Note:** *Once you have a copy of your refresh token, securely store this token. This token will not be displayed again, nor will it be stored for future retrieval. If the token is lost, you will need to generate a new one.*

### 2. Docker Installation
Install Docker in the environment where you plan to execute API commands. This can be either locally or on a hosted cloud platform like Amazon Web Services (AWS). Refer to the appropriate Docker installation guide for your environment:

- [Docker Installation Guide for Linux](https://docs.docker.com/engine/install/)
- [Docker Installation Guide for macOS](https://docs.docker.com/desktop/setup/install/mac-install/)
- [Docker Installation Guide for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)

#### Build the `embed-cli` Docker Image

Use the provided `Dockerfile` to build the Docker image. From the directory containing both the `Dockerfile` and the `embed-cli` script (and any related files), run:

```docker
docker build -t openbridge/embed-cli .
```

This command creates a Docker image named `openbridge/embed-cli`. You can name it anything you’d like (e.g., `myorg/embed-cli`), but for the sake of consistency, this guide uses `openbridge/embed-cli`.

#### Environment Variables

When running `embed-cli`, authentication tokens and other configuration values are **primarily passed through environment variables** to the container. Some key environment variables include:

- **`REFRESH_TOKEN`**: Alternative token for API authentication.  
- **`LOG_LEVEL`**: Controls verbosity (`DEBUG`, `INFO`, `WARN`, `ERROR`).  

### Config File
You can mount a config file into the container with your refresh token information:
```docker
        docker run --rm \
          -v "$(pwd)/config.env:/app/config.env" \
          openbridge/embed-cli jobs list --subscription 123456
```
`embed-cli` will source environment variables from `/app/config.env`.

### Basic Usage

A simple run without any mounted volumes or additional environment variables might look like:

```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli <command> [options]
```
For many operations, environment variables are **required** (especially for authentication). Omitting them will likely produce an authentication error.

Responses will be output as JSON, the contents of which will vary based on the specific operation. Here is an example:

```json
{
  "id": 123456789,
  "modified_at": "2024-06-27T12:31:11.230000Z",
  "company": "Dummy Company",
  "email_address": "dummy@example.com",
  "product_id": 99,
  "subproduct_id": null,
  "product_name": "dummy-product",
  "payload_name": "dummy_payload",
  "storage_id": "dummy-storage-id",
  "subscription_id": 987654,
  "subscription_name": "dummy_subscription",
  "hc_runtime": "2024-06-27T12:35:45.427000Z",
  "status": "UNPROCESSED",
  "message": null,
  "file_path": "dummy/path/to/file.gz",
  "owner": "Dummy Owner",
  "sender": "dummysender",
  "transaction_id": "dummy-transaction-id",
  "err_msg": "Dummy error message",
  "error_code": "DUMMY_ERROR",
  "job_id": null,
  "account_id": 12345
}
```

Here is an example when you retrieve user account information:

```docker
  docker run --rm \                     
    -e "REFRESH_TOKEN=ABC123DummyToken:78cc49e667485hfc04f79235b5cd2244
n1234567890abcdef1234567890abcdef" \
    -e "LOG_LEVEL=INFO" \
    openbridge/embed-cli user info
```
When this is run, the user information will be returned for the account as shown in this sample:

```json
docker run --rm \                     
  -e "REFRESH_TOKEN=XYPb2GtdoUVJ2y7nZNpzRn:78cc49e667485hfc04f79235b5cd2244" \
  -e "LOG_LEVEL=INFO" \
  openbridge/embed-cli user info
2025-01-21 22:51:06 - [SUCCESS] - Successfully retrieved new token
{
  "links": {
    "first": "https://user.api.openbridge.io/user?page=1",
    "last": "https://user.api.openbridge.io/user?page=1",
    "next": "",
    "prev": ""
  },
  "data": [
    {
      "type": "User",
      "id": "9999",
      "attributes": {
        "account_id": 8888,
        "first_name": "John",
        "last_name": "Doe",
        "email_address": "john.doe@example.com",
        "password_request_token_expire": "2025-01-01T12:00:00",
        "created_at": "2025-01-01T12:01:00",
        "modified_at": "2025-01-01T12:02:00",
        "is_admin": 0,
        "email_address_normalized": "john.doe@example.com"
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

### Cache Your JWT Token

Token caching improves performance and reliability by storing the JWT locally instead of requesting a new one for each command. The cache stores the token, expiration time, and payload in /app/cache/jwt_token.json. This reduces API calls and latency, particularly important in automation scenarios. The cache automatically refreshes tokens nearing expiration (5-minute buffer).


*Important security considerations:Note, that your local directory permissions should be restricted since it contains sensitive tokens. In our mounted volume at $HOME/.embed-cli example will persist between container runs so ensure proper cleanup occurs as needed. Consider encryption at rest for production environments and monitor the cache directory size over time.*

```docker
docker run --rm \
  -e "REFRESH_TOKEN=XYPb2GtdoUVJ2y7nZNpzRn:78cc49e667485hfc04f79235b5cd2244" \
  -e "LOG_LEVEL=DEBUG" \
  -v "$HOME/.embed-cli:/app/cache" \
  openbridge/embed-cli jobs list --subscription XXXXXXX
```

#### Using Docker Volumes For Cache
Docker volumes can offer elevated security since they're isolated and managed by Docker:

- Access restricted to Docker processes/containers
- Cannot be accidentally exposed through host filesystem permissions
- Data encrypted at rest when using volume encryption
- Volume permissions controlled through Docker rather than host OS
- Built-in volume audit logging capabilities

For production/enterprise usage, Docker volumes are recommended. For individual developer usage, host mounts (`-v`) may be acceptable if proper permissions (700) are set.


You can quickly create a docker volume to store the token:
```docker
docker volume create embed-cli-cache
```
Then use the new volumne in your command:
```docker
docker run --rm \
  -e "REFRESH_TOKEN=XYPb2GtdoUVJ2y7nZNpzRn:78cc49e667485hfc04f79235b5cd2244" \
  -e "LOG_LEVEL=DEBUG" \
  --mount source=embed-cli-cache,target=/app/cache \
  openbridge/embed-cli jobs list --subscription XXXXXXX
```

To inspect the `embed-cli-cache` volume contents:

```docker
docker run --rm -it \
  --mount source=embed-cli-cache,target=/app/cache \
  alpine ls -la /app/cache
```
Lastly, you can quickly clean the `embed-cli-cache` volume up by removing it:
```docker
docker volume rm embed-cli-cache
```

## Examples

Below are examples for various tasks. Each command can be customized with additional flags, environment variables, or volume mounts as needed.

### Health Checks

Get all health checks:

```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli health check
```
Get a specific page (e.g., page 5) of health checks:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli health check --page 5
```
Get a range of pages (pages 5 through 10):

```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli health check --range 5-10
```
Alternatively:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli health check --start-page 5 --end-page 10
```
---

### Jobs

List all jobs for a given subscription ID:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli jobs list --subscription XXXXXXX
```

This retrieves any jobs from the last 2 days.

```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli jobs list --subscription XXXXXXX --last-days 2
```

Get a specific page (e.g., page 5):
```docker
      docker run --rm \
        -e "REFRESH_TOKEN=your_refresh_token" \
        openbridge/embed-cli jobs list --subscription XXXXXXX --page 5
```

Get a range of pages (e.g., 5 through 10):
```docker
      docker run --rm \
        -e "REFRESH_TOKEN=your_refresh_token" \
        openbridge/embed-cli jobs list --subscription XXXXXXX --range 5-10
```
You can use a slightly different syntax for the start and end pages:
```docker
      docker run --rm \
        -e "REFRESH_TOKEN=your_refresh_token" \
        openbridge/embed-cli jobs list --subscription XXXXXXX --start-page 5 --end-page 10
```
Request jobs based on a specic report or data type by `--stage`
```docker
 docker run --rm \
   -v "$(pwd)/config.env:/app/config.env" \
   openbridge/embed-cli jobs list --subscription XXXXXXX --stage 1002
```
---
#### Creating Jobs

Create a single job:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli jobs create \
        --start 2024-01-01 \
        --end 2024-01-01 \
        --subscription XXXXXXX
```
However, an additional variable called `--stage` can be used to refine a request. The `--stage` reflects the specific report or data you want to request. This is a more efficient API call as the upstream data source only needs to respond with the report or data specified. This is critical in use cases where data source API rate limits and throttling is a concern.
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      openbridge/embed-cli jobs create \
        --start 2024-01-01 \
        --end 2024-01-01 \
        --subscription XXXXXXX \
        --stage 1001
```
#### Batch Processing

The `-f` or `--file` flag allows you to specify a CSV input for bulk operations for jobs creation.

Example: Processing a CSV for historical data jobs:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      -v "$(pwd)/backfill.csv:/app/backfill.csv" \
      openbridge/embed-cli -f /app/backfill.csv
```
The `backfill.csv` must look like:

```csv
    date,subscription_id
    2025-01-05,XXXXXXX
    2025-01-06,XXXXXXX
    2025-01-07,XXXXXXX
```
`date` reflects the report or data date you want to request and `subscription_id` the specifc pipeline you want to collect the data for.

A batch CSV file can also contain an additional column called `stage_id`. The `stage_id` reflects the specific report or data you want to request.

A `backfill_stage.csv` CSV file with the additional `stage_id`:

```csv
       date,subscription_id,stage_id
       2024-01-01,XXXXXXX,1001
       2024-01-02,XXXXXXX,1002
```
Next, run the batch process with the `backfill_stage.csv` file:
```docker
       docker run --rm \
         -e "REFRESH_TOKEN=your_refresh_token" \
         -v "$(pwd)/backfill_stage.csv:/data/backfill_stage.csv:ro" \
         openbridge/embed-cli jobs batch --file /data/backfill_stage.csv
```

---
#### User Information


Retrieve just the user ID:

```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli user id
```

Retrieve compelte user metadaa info:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli user info
```
---
#### Subscriptions

List all subscriptions:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli subscription list
```
List subscriptions with a specific page size:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      -e "MAX_PAGE_SIZE=50" \
      openbridge/embed-cli subscription list --page-size 50
```
List only active subscriptions:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli subscription list --status active
```
Update a subscription status:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli subscription update --id 123456 --status active
```
Update a subscription storage group:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli subscription update --id 123456 --storage-group 1289
```
---

#### Product Stages

List stages for a given product ID:
```docker
    docker run --rm \
      -e "REFRESH_TOKEN=your_token_here" \
      openbridge/embed-cli stages list --product 70
```
### Identities

List all identities (paginated):
```docker
docker run --rm \
 -e "REFRESH_TOKEN=your_token_here" \
 openbridge/embed-cli identity list
```
List with page size and range
```docker
docker run --rm \
 -e "REFRESH_TOKEN=your_token_here" \
 openbridge/embed-cli identity list --page-size 50 --range 1-10
```
List invalid identities only
```docker
docker run --rm \
 -e "REFRESH_TOKEN=your_token_here" \
 openbridge/embed-cli identity list --invalid 1
```
List identities invalidated after date
```docker
docker run --rm \
 -e "REFRESH_TOKEN=your_token_here" \
 openbridge/embed-cli identity list --invalidated-after "2024-01-01T00:00:00"
```
Get specific identity details
```docker
docker run --rm \
 -e "REFRESH_TOKEN=your_token_here" \
 openbridge/embed-cli identity get 4832
```
---
#### Debugging and Logging

Enable debug mode:

    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      -e "LOG_LEVEL=DEBUG" \
      openbridge/embed-cli jobs list --subscription XXXXXXX

Logs will output much more detailed information (e.g., request payloads, detailed error messages).

Custom retry and sleep settings:

    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      -e "RETRY_COUNT=5" \
      -e "SLEEP_DURATION=2" \
      openbridge/embed-cli jobs list --subscription XXXXXXX

Mount a directory for persistent logs:

    docker run --rm \
      -e "REFRESH_TOKEN=your_refresh_token" \
      -v "$(pwd)/logs:/app/logs" \
      -e "LOG_FILE=/app/logs/api_call.log" \
      openbridge/embed-cli health check

All logs will be written to `api_call.log` within your local `logs` directory.

---

#### Version Check

To verify which version of the tool you’re running:

    docker run --rm openbridge/embed-cli -v

You’ll see output indicating the version, commit hash, or build date, depending on how the CLI is configured.


## Notes and Best Practices

- **Authentication**: Always ensure your `AUTH_TOKEN` or `REFRESH_TOKEN` is valid and **never** commit these tokens to a public repository.  
- **Date Formats**: For job creation or historical data retrieval, use `YYYY-MM-DD` format. The CLI expects valid ISO date strings.  
- **Mounting Files**: If you need to process multiple CSV files, consider mounting the entire directory containing them, rather than a single file. For example:

      docker run --rm \
        -e "REFRESH_TOKEN=your_token_here" \
        -v "$(pwd):/data" \
        openbridge/embed-cli jobs batch --file /data/jobs.csv

- **Security**: Use Docker secrets or other secure credential management solutions when running in production environments.



## `embed-cli` Project Directory Structure

This is structure of the `embed-cli` project code. This is only relevant if you want to explore the code directly. In the Dockker context, this is abstracted so the internal operations are exposed through the `docker run` operations.

```bash
.
├── bin/
│   └── embed-cli
├── lib/
│   ├── api/
│   │   └── identity.sh
│   ├── commands/
│   │   └── identity.sh 
│   ├── test/
│   │   ├── integration/
│   │   │   ├── test_identity_cmd.sh
│   │   │   └── test_embed_kit.sh
│   │   └── unit/
│   │       └── test_identity_api.sh
│   ├── common.sh
│   ├── logging.sh
│   └── validation.sh
└── Dockerfile
```

 **Note**: This structure may vary in your own environment.


