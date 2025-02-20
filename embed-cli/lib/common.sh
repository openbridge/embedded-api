#!/bin/bash
#
# Common variables and utilities used across all modules

# Guard against multiple inclusion
[[ -n "${_COMMON_SH:-}" ]] && return
readonly _COMMON_SH=1


#######################################
# Exit Codes
#######################################
readonly E_SUCCESS=0
readonly E_ERROR=1
readonly E_INVALID_DATE=2
readonly E_API_FAILURE=3
readonly E_INTERRUPTED=4
readonly E_NO_AUTH=5
readonly E_DEPENDENCY=10
readonly E_FAILURE=255

#######################################
# Version
#######################################
readonly VERSION="1.0.0"

#######################################
# API Endpoints
#######################################
readonly API_ENDPOINT_BASE="${API_ENDPOINT_BASE:-https://service.api.openbridge.io}"
readonly PRODUCT_ENDPOINT="${API_ENDPOINT_BASE}/service/products/product"
readonly JOBS_ENDPOINT="${API_ENDPOINT_BASE}/service/jobs/jobs"
readonly HEALTHCHECK_ENDPOINT="${API_ENDPOINT_BASE}/service/healthchecks/production/healthchecks/account"
readonly HISTORY_ENDPOINT_BASE="${API_ENDPOINT_BASE}/service/history/production/history"
readonly USER_ENDPOINT="https://user.api.openbridge.io/user"
readonly AUTH_ENDPOINT="https://authentication.api.openbridge.io/auth/api/ref"
readonly SUBSCRIPTION_ENDPOINT="https://subscriptions.api.openbridge.io/sub"

# Endpoints
readonly IDENTITY_ENDPOINT_BASE="https://remote-identity.api.openbridge.io"
readonly SRI_ENDPOINT="${IDENTITY_ENDPOINT_BASE}/sri"
readonly RI_ENDPOINT="${IDENTITY_ENDPOINT_BASE}/ri"

#######################################
# Request Settings
#######################################
readonly CONTENT_TYPE="application/json"
readonly RETRY_COUNT="${RETRY_COUNT:-3}"
readonly SLEEP_DURATION="${SLEEP_DURATION:-1}"

#######################################
# Validation Patterns
#######################################
readonly DATE_REGEX='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'

#######################################
# API Constants
#######################################
readonly MAX_PAGE_SIZE=100
readonly VALID_STATUSES=("ERROR" "WARNING" "SUCCESS" "PENDING")

#######################################
# Configuration Loading
#######################################
readonly DEFAULT_CONFIG_FILE="/app/config.env"
readonly CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"


# Add this to common.sh, before the parse_arguments function:

urlencode() {
    local string="$1"
    local strlen="${#string}"
    local encoded=""
    local pos c o

    for ((pos=0; pos<strlen; pos++)); do
        c="${string:${pos}:1}"
        case "${c}" in
            [-_.~a-zA-Z0-9]) o="${c}" ;;
            *) printf -v o '%%%02x' "'${c}" ;;
        esac
        encoded+="${o}"
    done
    printf "%s" "${encoded}"
}

# Already have get_relative_date() for date handling
# Need to add cron schedule generation for 10-15 mins ahead

process_order_ids() {
    local csv_file="${1:-}"
    local batch_size=100
    local order_ids=()
    
    # Validate input file
    if [[ -z "$csv_file" ]]; then
        error_exit "CSV file path is required"
    fi

    if [[ ! -f "$csv_file" ]]; then
        error_exit "Order IDs file not found: $csv_file"
    fi
    
    # Read and validate order IDs
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Validate order ID format
        if [[ ! "$line" =~ ^[0-9]{3}-[0-9]+-[0-9]+$ ]]; then
            error_exit "Invalid order ID format: $line"
        fi
        
        order_ids+=("$line")
    done < "$csv_file"

    if [[ ${#order_ids[@]} -eq 0 ]]; then
        error_exit "No valid order IDs found in file"
    fi
    
    echo "${order_ids[@]}"
}

generate_future_cron() {
    local minutes_ahead="${1:-15}"  # Default to 15 if not specified
    
    if [[ ! "$minutes_ahead" =~ ^[0-9]+$ ]]; then
        error_exit "Minutes ahead must be a positive number"
    fi

    if date --version >/dev/null 2>&1; then
        date -u -d "+${minutes_ahead} minutes" "+%M %H * * *"
    else
        date -v+"${minutes_ahead}"M -u "+%M %H * * *"
    fi
}

generate_future_timestamp() {
    if date --version >/dev/null 2>&1; then
        # GNU date
        date -u -d "15 minutes" "+%Y-%m-%d %H:%M:%S"
    else
        # BSD date
        date -v+15M -u "+%Y-%m-%d %H:%M:%S"
    fi
}

#######################################
# Shared Utility Functions
#######################################

error_exit() {
    local message="$1"
    local exit_code="${2:-$E_FAILURE}"
    local format="${3:-plain}"

    # Output to stderr
    printf "ERROR: %s\n" "$message" >&2

    if [[ "$format" == "json" ]]; then
        printf '{"error": "%s", "code": %d}\n' "$message" "$exit_code" | jq -C '.' >&2
    fi

    exit "$exit_code"
}

#######################################
# Configuration
#######################################

# Update the load_config function:
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            if [[ -n "$key" && ! "$key" =~ ^# ]]; then
                value="${value%\"}"
                value="${value#\"}"
                export "$key=$value"
            fi
        done < "$CONFIG_FILE"
    fi
    return 0
}

usage() {
    cat << HELP
Version: $VERSION

Usage: $(basename "$0") [OPTIONS]

Options:
    -s <start_date>      Start date (YYYY-MM-DD)
    -e <end_date>        End date (YYYY-MM-DD)
    -i <subscription_id> Subscription ID
    -v                   Show version
    -p <product_id>      Product ID (for getting stages)
    -j <subscription_ids> Subscription IDs (for getting jobs)
    -u                   Get user account data
    -h                   Show this help message
    -d                   Enable debug mode

Environment variables:
    API_ENDPOINT_BASE    Base URL for API endpoint
    AUTH_TOKEN          Authentication token
    REFRESH_TOKEN       Refresh token for obtaining new JWT
    CONFIG_FILE         Path to configuration file
    LOG_LEVEL          Logging level (DEBUG|INFO|WARNING|ERROR)
    RETRY_COUNT        Number of retry attempts
    SLEEP_DURATION     Sleep duration between retries
HELP
    exit $E_SUCCESS
}

parse_arguments() {
    local OPTIND
    while getopts ":s:e:i:t:p:j:P:uhHvdf:" opt; do
        case $opt in
            s) START_DATE="$OPTARG" ;;
            e) END_DATE="$OPTARG" ;;
            i) SUBSCRIPTION_ID="$OPTARG" ;;
            t) STAGE_ID="$OPTARG" ;;
            p) PRODUCT_ID="$OPTARG" ;;
            j) SUBSCRIPTION_IDS="$OPTARG" ;;
            u) GET_USER=true ;;
            H) GET_HEALTH=true ;;
            P) HEALTH_PAGE="$OPTARG" ;;
            f) CSV_FILE="$OPTARG" ;;
            h) usage ;;
            v) echo "Version: $VERSION"; exit $E_SUCCESS ;;
            d) CURRENT_LOG_LEVEL="DEBUG" ;;
            :) error_exit "Option -$OPTARG requires an argument." $E_USAGE ;;
            \?) error_exit "Invalid option: -$OPTARG" $E_USAGE ;;
        esac
    done
}