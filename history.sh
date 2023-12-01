#!/bin/bash
#
# Description: This script performs a POST request to a specified API endpoint
# with an authorization token and a JSON payload. The script accepts command-line
# arguments for start date, end date, and subscription ID.

# Usage: script_name.sh -s <start_date> -e <end_date> -i <subscription_id>

# AUTH_TOKEN Requirements and Handling:
# - The AUTH_TOKEN is required for authenticating API requests.
# - It should be set as an environment variable before running the script.
# - If the AUTH_TOKEN environment variable is not set, the script attempts to load it from a configuration file.
# - The default path for the configuration file is './config.env', but this can be overridden by setting the CONFIG_FILE environment variable.
# - The configuration file should contain the AUTH_TOKEN in the format: export AUTH_TOKEN="your_token_here".
# - Ensure the AUTH_TOKEN is kept secure and is not exposed in insecure contexts.
# - This token is used to authenticate with the API endpoint specified in the script.

# Start Date and End Date Examples:
# - The start and end dates are used to define the date range for the API request.
# - Dates must be in the format YYYY-MM-DD (e.g., 2023-11-01).

# Example 1: Single Day Query
#   Start Date: 2023-11-01
#   End Date:   2023-11-01
#   Explanation: Both dates are the same, indicating a query for data on a specific single day.

# Example 2: Multiple Days Query
#   Start Date: 2023-11-07
#   End Date:   2023-11-01
#   Explanation: This query covers data from November 1 to November 7, 2023.

# Example 3: Month-Long Query
#   Start Date: 2023-11-30
#   End Date:   2023-11-01
#   Explanation: Covers the entire month of November 2023.

# Example 4: Query Across Different Months
#   Start Date: 2023-12-10
#   End Date:   2023-11-15
#   Explanation: Spans from November 15 to December 10, 2023, covering parts of two months.

# Example 5: Year-Long Query
#   Start Date: 2023-12-31
#   End Date:   2023-01-01
#   Explanation: Covers the entire year of 2023, from January 1 to December 31.

# Note: The start date should always be the same as or later than the end date.

# Subscription ID Description:
# - The subscription ID is a unique identifier for the data pipeline whose history you want to request.
# - It reflects the primary ID associated with a specific data pipeline or service in your Openbridge account.
# - The subscription ID is used to specify which data pipeline's history is being queried by the API call.

# Finding the Subscription ID:
# - Log in to your Openbridge account.
# - Navigate to the section where your data pipelines or services are listed.
# - Locate the data pipeline for which you want to request history.
# - The subscription ID will be listed alongside the details of the data pipeline, often labeled as 'Subscription ID', 'Pipeline ID', or similar.
# - This ID should be noted and used as an argument when running the script for querying history data.

# Note: The subscription ID is crucial for the correct functioning of the script, as it targets the specific data pipeline in your Openbridge account.


# Default configuration
API_ENDPOINT_BASE="${API_ENDPOINT_BASE:-https://service.api.openbridge.io/service/history/production/history}"
CONTENT_TYPE="application/json"
LOG_FILE="api_call.log"
RETRY_COUNT=${RETRY_COUNT:-3}
SLEEP_DURATION=${SLEEP_DURATION:-1}
CONFIG_FILE="${CONFIG_FILE:-./config.env}"

# Dedicated logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] - $message" | tee -a "$LOG_FILE"
}

# Signal handling for graceful termination
trap 'log_message "INFO" "Script interrupted."; exit 4' SIGINT SIGTERM

# Check for curl
if ! command -v curl &> /dev/null; then
    log_message "ERROR" "curl is not installed. Please install it to continue."
    exit 10
fi

# Help function
usage() {
    echo "Usage: $0 -s <start_date> -e <end_date> -i <subscription_id>"
    exit 1
}

# Validate date format (YYYY-MM-DD)
validate_date() {
    if ! [[ $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_message "ERROR" "Date format is invalid. Please use YYYY-MM-DD."
        exit 2
    fi
}

# Load configuration from file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_message "INFO" "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log_message "WARNING" "Configuration file not found at $CONFIG_FILE"
    fi
}

# API call function
call_api() {
    local start_date=$1
    local end_date=$2
    local subscription_id=$3

    local api_endpoint="${API_ENDPOINT_BASE}/${subscription_id}"
    local payload="{ \"data\": { \"type\": \"HistoryTransaction\", \"attributes\": { \"start_date\": \"${start_date}\", \"end_date\": \"${end_date}\" } } }"

     for ((attempt=1; attempt<=RETRY_COUNT; attempt++)); do
        response=$(curl -H "Content-Type: ${CONTENT_TYPE}" \
                        -H "Authorization: Bearer ${AUTH_TOKEN}" \
                        -X POST \
                        -d "${payload}" \
                        -w "%{http_code}" \
                        -o /dev/null \
                        --silent \
                        --show-error \
                        --connect-timeout 10 \
                        "${api_endpoint}")

        if [ "$response" -ge 200 ] && [ "$response" -lt 300 ]; then
            log_message "INFO" "API call succeeded (Status: $response). Job created for Subscription ID: ${subscription_id}, Date Range: ${start_date} to ${end_date}."
            return 0
        elif [ "$response" -ge 500 ] && [ "$response" -lt 600 ]; then
            log_message "WARNING" "Server error with status code: $response. Retrying in $SLEEP_DURATION second(s) (Attempt $attempt/$RETRY_COUNT)"
            sleep "$SLEEP_DURATION"
        else
            log_message "ERROR" "API call failed with status code: $response. Not retrying."
            break
        fi
    done

    log_message "ERROR" "API call failed after multiple attempts."
    return 3
}

# Main function
main() {
    # Parse command-line options
    while getopts ":s:e:i:h" opt; do
        case $opt in
            s) START_DATE="$OPTARG"
               ;;
            e) END_DATE="$OPTARG"
               ;;
            i) SUBSCRIPTION_ID="$OPTARG"
               ;;
            h) usage
               ;;
            \?) log_message "ERROR" "Invalid option: -$OPTARG"
                usage
               ;;
        esac
    done

    if [ -z "$AUTH_TOKEN" ]; then
        load_config
        if [ -z "$AUTH_TOKEN" ]; then
            log_message "ERROR" "AUTH_TOKEN is not set. Please set the AUTH_TOKEN environment variable or provide it in $CONFIG_FILE."
            exit 5
        fi
    fi

    # Validate input
    if [ -z "${START_DATE}" ] || [ -z "${END_DATE}" ] || [ -z "${SUBSCRIPTION_ID}" ]; then
        log_message "ERROR" "Start date, end date, and subscription ID are required."
        usage
    fi

    validate_date "${START_DATE}"
    validate_date "${END_DATE}"

    # Perform API call
    call_api "${START_DATE}" "${END_DATE}" "${SUBSCRIPTION_ID}"
}

# Call the main function with all passed arguments
main "$@"
