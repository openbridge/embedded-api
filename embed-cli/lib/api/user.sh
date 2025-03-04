#!/bin/bash
#
# User account endpoint operations

# Guard against multiple inclusion
[[ -n "${_API_USER_SH:-}" ]] && return
readonly _API_USER_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"

get_user() {
    # Verify that the required environment variable is set
    local endpoint="${USER_ENDPOINT:?USER_ENDPOINT environment variable not set}"
    
    # Log the API request attempt
    log_message "DEBUG" "Initiating user data fetch from endpoint: ${endpoint}"

    # Make the API request and handle errors
    local response
    if ! response=$(api_request "GET" "${endpoint}"); then
        log_message "ERROR" "API request failed for endpoint: ${endpoint}"
        return 1
    fi

    # Process and validate the JSON response
    local json_output
    if json_output=$(jq -C '.' <<< "${response}" 2>&1) && [[ -n "${json_output}" ]]; then
        # Successful JSON parsing - output formatted result
        printf "%s\n" "${json_output}"
        return 0
    else
        # Handle invalid JSON response
        log_message "WARNING" "Received malformed JSON response from ${endpoint}"
        log_message "DEBUG" "Failed JSON parsing attempt. Raw response: ${response}"
        printf "Invalid response format received. Original data:\n%s\n" "${response}"
        return 1
    fi
}

get_user_id() {
    # Validate required environment variable
    local endpoint="${USER_ENDPOINT:?USER_ENDPOINT environment variable not set}"
    
    # Log initial attempt with endpoint information
    log_message "DEBUG" "Attempting to fetch user ID from endpoint: ${endpoint}"

    # Execute API request with error handling
    local response
    if ! response=$(api_request "GET" "${endpoint}"); then
        log_message "ERROR" "API request failed for user ID endpoint: ${endpoint}"
        return 1
    fi

    # Validate JSON structure before processing
    if ! jq -e . >/dev/null 2>&1 <<< "${response}"; then
        log_message "ERROR" "Received invalid JSON response"
        log_message "DEBUG" "Endpoint: ${endpoint}"
        log_message "DEBUG" "Invalid JSON content: ${response}"
        return 1
    fi

    # Extract and validate account ID in one step
    local account_id
    if ! account_id=$(jq -er '.data[0].attributes.account_id // empty' <<< "${response}"); then
        log_message "ERROR" "Account ID not found or invalid in response"
        log_message "DEBUG" "Endpoint: ${endpoint}"
        log_message "DEBUG" "Response content: ${response}"
        return 1
    fi

    # Success case handling
    log_message "INFO" "Successfully retrieved user account ID: ${account_id}"
    printf "%s" "${account_id}"
    return 0
}