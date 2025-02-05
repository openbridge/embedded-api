#!/bin/bash
#
# Input and environment validation functions

# Guard against multiple inclusion
[[ -n "${_VALIDATION_SH:-}" ]] && return
readonly _VALIDATION_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

validate_datetime() {
    local datetime="$1"
    local label="$2"
    
    if [[ ! "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        error_exit "Invalid $label format. Use: YYYY-MM-DDThh:mm:ss"
    fi
}

validate_date() {
    local date="${1%$'\n'}"
    date="${date//[[:space:]]/}"
    local date_type="$2"

    log_message "DEBUG" "Validating $date_type: '$date' against pattern: $DATE_REGEX"

    if [[ ! $date =~ $DATE_REGEX ]]; then
        log_message "DEBUG" "Date validation failed for $date"
        error_exit "Invalid $date_type format: $date. Expected format is YYYY-MM-DD." $E_INVALID_DATE
    fi

    # Check if we're on BSD date (macOS) or GNU date
    if date --version >/dev/null 2>&1; then
        # GNU date
        if ! date -d "$date" >/dev/null 2>&1; then
            error_exit "Invalid $date_type: $date is not a real date." $E_INVALID_DATE
        fi
    else
        # BSD date (macOS)
        if ! date -j -f "%Y-%m-%d" "$date" >/dev/null 2>&1; then
            error_exit "Invalid $date_type: $date is not a real date." $E_INVALID_DATE
        fi
    fi

    log_message "DEBUG" "Date validation passed for $date"
}

validate_numeric() {
    local value="$1"
    local field="$2"
    
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid $field: $value. Must be numeric." $E_INVALID_INPUT
    fi
}

validate_date_range() {
    local start_date="$1"
    local end_date="$2"

    # Convert dates to format that BSD date can understand
    if date --version >/dev/null 2>&1; then
        # GNU date
        start_seconds=$(date -d "$start_date" +%s)
        end_seconds=$(date -d "$end_date" +%s)
    else
        # BSD date (macOS)
        start_seconds=$(date -j -f "%Y-%m-%d" "$start_date" +%s)
        end_seconds=$(date -j -f "%Y-%m-%d" "$end_date" +%s)
    fi

    if (( start_seconds > end_seconds )); then
        error_exit "Start date ($start_date) cannot be later than end date ($end_date)."
    fi
}

validate_subscription_id() {
    local subscription_id="$1"

    if [[ ! "$subscription_id" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid subscription ID: $subscription_id. It must be a numeric value."
    fi
}

validate_subscription_status() {
    local status="$1"
    local valid=false
    
    for valid_status in "${SUBSCRIPTION_VALID_STATUSES[@]}"; do
        if [[ "$status" == "$valid_status" ]]; then
            valid=true
            break
        fi
    done
    
    if [[ "$valid" != "true" ]]; then
        error_exit "Invalid status: $status. Valid values are: ${SUBSCRIPTION_VALID_STATUSES[*]}" $E_INVALID_STATUS
    fi
}

validate_environment() {

    # Try to load config first
    load_config

    if [[ -z "${AUTH_TOKEN:-}" && -z "${REFRESH_TOKEN:-}" ]]; then
        error_exit "Neither AUTH_TOKEN nor REFRESH_TOKEN is set. Authentication is required."
    fi
}

check_dependencies() {
    local deps=("curl" "date" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            error_exit "Required dependency '$dep' is not installed." $E_DEPENDENCY
        fi
    done
}