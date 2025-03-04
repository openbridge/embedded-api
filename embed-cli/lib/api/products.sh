#!/bin/bash
#
# Product endpoint operations with pagination support

# Guard against multiple inclusion
[[ -n "${_API_PRODUCTS_SH:-}" ]] && return
readonly _API_PRODUCTS_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"

get_stages() {
    local product_id="$1"
    local opts="${2:-}"

    # Validate product_id
    if [[ ! "$product_id" =~ ^[0-9]+$ ]]; then
        error_exit "Product ID must be numeric."
    fi

    local endpoint="${PRODUCT_ENDPOINT}/${product_id}/payloads?stage_id__gte=1000"
    
    # Add additional query parameters if provided
    if [[ -n "$opts" ]]; then
        endpoint="${endpoint}&${opts}"
    fi
    
    log_message "INFO" "Fetching stages for Product ID: ${product_id}"
    log_message "DEBUG" "Using endpoint: ${endpoint}"

    local response
    response=$(api_request "GET" "$endpoint") || {
        error_exit "Failed to fetch stages for Product ID: ${product_id}"
    }

    # Format and output the response
    echo "$response" | jq -C '.'
}