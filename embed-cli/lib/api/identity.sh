#!/bin/bash
#
# Identity endpoint operations

# Guard against multiple inclusion
[[ -n "${_API_IDENTITY_SH:-}" ]] && return
readonly _API_IDENTITY_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"

list_identities() {
    local start_page="${1:-1}"
    local end_page="${2:-}"
    local opts="${3:-}"
    local single_page_mode=false
    local query_params=""

    # Parse options string into associative array
    declare -A params
    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            params["$key"]="$value"
        fi
    done < <(echo "$opts" | tr '&' '\n')
    
    # Validate and process parameters
    if [[ -n "${params[page_size]:-}" ]]; then
        if [[ "${params[page_size]}" -gt "$MAX_PAGE_SIZE" ]]; then
            error_exit "Page size cannot exceed $MAX_PAGE_SIZE"
        fi
        query_params+="&page_size=${params[page_size]}"
    fi

    if [[ -n "${params[invalid_identity]:-}" ]]; then
        if [[ "${params[invalid_identity]}" =~ ^[01]$ ]]; then
            query_params+="&invalid_identity=${params[invalid_identity]}"
        else
            error_exit "invalid_identity must be 0 or 1"
        fi
    fi

    if [[ -n "${params[invalidated_at__gte]:-}" ]]; then
        validate_datetime "${params[invalidated_at__gte]}" "invalidated_at__gte"
        query_params+="&invalidated_at__gte=$(urlencode "${params[invalidated_at__gte]}")"
    fi

    if [[ -n "${params[invalidated_at__lte]:-}" ]]; then
        validate_datetime "${params[invalidated_at__lte]}" "invalidated_at__lte"
        query_params+="&invalidated_at__lte=$(urlencode "${params[invalidated_at__lte]}")"
    fi

    # If only one page number is provided and no end_page, treat as single page request
    if [[ -n "$start_page" && -z "$end_page" && "$start_page" != "1" ]]; then
        single_page_mode=true
        end_page="$start_page"
    fi

    # Get all pages or single page based on mode
    local current_page=$start_page
    local max_pages=${end_page:-100}
    local has_next_page=true

    while [[ "$has_next_page" == "true" && $current_page -le $max_pages ]]; do
        log_message "INFO" "Fetching identities page: $current_page"

        local response
        response=$(get_identities_page "$current_page" "$query_params") || {
            log_message "ERROR" "Failed to retrieve page $current_page"
            return 1
        }

        # Break if no results are returned
        if [[ -z "$response" || "$response" == "null" ]]; then
            log_message "INFO" "No more data. Stopped fetching at page $current_page"
            break
        fi

        # Format and validate JSON response
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -C '.'
        else
            log_message "WARNING" "Response not valid JSON, outputting raw"
            echo "$response"
        fi

        # If in single page mode, break after first page
        if [[ "$single_page_mode" == "true" ]]; then
            break
        fi

        # Check for next page in pagination links
        local next_page
        next_page=$(echo "$response" | jq -r '.links.next')
        if [[ -z "$next_page" || "$next_page" == "null" || "$next_page" == "" ]]; then
            has_next_page=false
            log_message "INFO" "Reached last available page: $current_page"
            break
        fi

        ((current_page++))
        sleep "$SLEEP_DURATION"
    done
}

get_identities_page() {
    local page="${1:-1}"
    local query_params="${2:-}"
    
    local endpoint="${SRI_ENDPOINT}?page=${page}${query_params}"
    log_message "DEBUG" "Requesting identities from: ${endpoint}"

    api_request "GET" "$endpoint"
}

get_identity() {
    local id="$1"
    local invalid_identity="${2:-}"
    local invalidated_at="${3:-}"
    local operator="${4:-}"
    local query_params=""

    if [[ -z "$id" ]]; then
        error_exit "Identity ID is required"
    fi

    if [[ -n "$invalid_identity" ]]; then
        if [[ "$invalid_identity" =~ ^[01]$ ]]; then
            query_params+="&invalid_identity=${invalid_identity}"
        else
            error_exit "invalid_identity must be 0 or 1"
        fi
    fi

    if [[ -n "$invalidated_at" ]]; then
        validate_datetime "$invalidated_at" "invalidated_at"
        local encoded_date
        encoded_date=$(urlencode "$invalidated_at")
        local date_param="invalidated_at__${operator}=${encoded_date}"
        query_params+="&${date_param}"
    fi

    [[ -n "$query_params" ]] && query_params="?${query_params:1}"

    local endpoint="${RI_ENDPOINT}/${id}${query_params}"
    log_message "DEBUG" "Fetching identity details from: ${endpoint}"

    local response
    response=$(api_request "GET" "$endpoint") || return 1

    if echo "$response" | jq -e . >/dev/null 2>&1; then
        echo "$response" | jq -C '.'
    else
        log_message "WARNING" "Response not valid JSON, outputting raw"
        echo "$response"
    fi
}