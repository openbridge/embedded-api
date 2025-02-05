#!/bin/bash
#
# Subscription endpoint operations

# Guard against multiple inclusion
[[ -n "${_API_SUBSCRIPTION_SH:-}" ]] && return
readonly _API_SUBSCRIPTION_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"

# Module-specific constants
readonly SUBSCRIPTION_VALID_STATUSES=("active" "cancelled")

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

parse_options() {
    local opts="$1"
    local query_params=""
    local IFS='&'
    local -a params=($opts)
    
    for param in "${params[@]}"; do
        [[ -z "$param" ]] && continue
        local key="${param%%=*}"
        local value="${param#*=}"
        
        case "$key" in
            status)
                validate_subscription_status "$value"
                query_params+="&status=$value"
                ;;
            storage_group)
                validate_numeric "$value" "storage group"
                query_params+="&storage_group=$value"
                ;;
            product)
                validate_numeric "$value" "product"
                query_params+="&product=$value"
                ;;
            page_size)
                if [[ "$value" -gt "$MAX_PAGE_SIZE" ]]; then
                    error_exit "Page size cannot exceed $MAX_PAGE_SIZE" $E_INVALID_INPUT
                fi
                query_params+="&page_size=$value"
                ;;
            created_at__gte|created_at__lte|modified_at__gte|modified_at__lte)
                validate_datetime "$value" "$key"
                local encoded_value
                encoded_value=$(printf '%s' "$value" | sed 's/ /%20/g;s/:/%3A/g')
                query_params+="&$key=$encoded_value"
                ;;
        esac
    done

    echo "$query_params"
}
get_subscriptions() {
    local start_page="${1:-1}"
    local end_page="${2:-}"
    local opts="${3:-}"
    local single_page_mode=false
    local query_params=""

    # Parse and validate options
    if [[ -n "$opts" ]]; then
        query_params=$(parse_options "$opts")
    fi

    # If only one page number is provided and no end_page, treat as single page request
    if [[ -n "$start_page" && -z "$end_page" && "$start_page" != "1" ]]; then
        single_page_mode=true
        end_page="$start_page"
    fi

    # Validate page numbers
    if [[ ! "$start_page" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid start page number: $start_page" $E_INVALID_INPUT
    fi

    if [[ -n "$end_page" ]]; then
        if [[ ! "$end_page" =~ ^[0-9]+$ ]]; then
            error_exit "Invalid end page number: $end_page" $E_INVALID_INPUT
        fi
        if ((start_page > end_page)); then
            error_exit "Start page ($start_page) cannot be greater than end page ($end_page)" $E_INVALID_INPUT
        fi
    fi

    if [[ "$single_page_mode" == "true" ]]; then
        log_message "INFO" "Fetching single page $start_page"
    elif [[ -n "$end_page" ]]; then
        log_message "INFO" "Fetching pages $start_page to $end_page"
    else
        log_message "INFO" "Fetching all pages starting from $start_page"
    fi

    local current_page=$start_page
    local max_pages=${end_page:-100}
    local has_next_page=true

    while [[ "$has_next_page" == "true" && $current_page -le $max_pages ]]; do
        log_message "INFO" "Fetching subscriptions page: $current_page"

        local response
        response=$(get_subscriptions_page "$current_page" "$query_params") || {
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

        # Stop if we've reached the end_page (if specified)
        if [[ -n "$end_page" && $current_page -ge $end_page ]]; then
            log_message "INFO" "Reached requested end page: $end_page"
            break
        fi

        ((current_page++))
        sleep "$SLEEP_DURATION"
    done

    return 0
}

get_subscriptions_page() {
    local page="${1:-1}"
    local query_params="${2:-}"

    local endpoint="${SUBSCRIPTION_ENDPOINT}?page=${page}${query_params}"
    log_message "DEBUG" "Requesting subscriptions from: ${endpoint}"

    local response
    response=$(api_request "GET" "$endpoint")
    local status=$?

    if [[ $status -eq 0 ]]; then
        log_message "DEBUG" "Raw API Response: $response"
        if [[ -z "$response" || "$response" == "null" ]]; then
            log_message "DEBUG" "Empty or null response received"
            return 1
        fi
        echo "$response"
        return 0
    else
        log_message "ERROR" "API request failed with status: $status"
        return 1
    fi
}

update_subscription() {
    local subscription_id="$1"
    local update_type="$2"
    local update_value="$3"

    # Validate inputs
    if [[ -z "$subscription_id" ]]; then
        error_exit "Subscription ID is required" $E_INVALID_INPUT
    fi

    if [[ ! "$subscription_id" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid subscription ID: $subscription_id" $E_INVALID_INPUT
    fi

    if [[ -z "$update_type" || -z "$update_value" ]]; then
        error_exit "Update type and value are required" $E_INVALID_INPUT
    fi

    # Validate update type and value
    case "$update_type" in
        status)
            validate_subscription_status "$update_value"
            ;;
        storage_group)
            if [[ ! "$update_value" =~ ^[0-9]+$ ]]; then
                error_exit "Storage group must be numeric" $E_INVALID_INPUT
            fi
            ;;
        *)
            error_exit "Invalid update type: $update_type" $E_INVALID_INPUT
            ;;
    esac

    # Construct the update payload
    local payload
    payload=$(jq -n \
        --arg id "$subscription_id" \
        --arg type "$update_type" \
        --arg value "$update_value" \
        '{
            data: {
                type: "Subscription",
                id: $id,
                attributes: {
                    ($type): (if $type == "storage_group" then ($value|tonumber) else $value end)
                }
            }
        }')

    log_message "INFO" "Updating subscription $subscription_id $update_type to: $update_value"

    local endpoint="${SUBSCRIPTION_ENDPOINT}/${subscription_id}"
    local response
    response=$(api_request "PATCH" "$endpoint" "$payload")
    local status=$?

    if [[ $status -eq 0 ]]; then
        log_message "SUCCESS" "Successfully updated subscription $subscription_id"
        echo "$response" | jq -C '.'
        return 0
    else
        log_message "ERROR" "Failed to update subscription $subscription_id"
        return 1
    fi
}