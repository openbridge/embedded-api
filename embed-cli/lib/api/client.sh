#!/bin/bash
# Guard against multiple inclusion
[[ -n "${_API_CLIENT_SH:-}" ]] && return
readonly _API_CLIENT_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"

api_request() {
    local method endpoint payload
    # Validate inputs at the beginning for better flow control
    if [[ -z "$1" || -z "$2" ]]; then
        log_message "ERROR" "Invalid API request: missing method or endpoint."
        return 1
    fi

    method="$1"
    endpoint="$2"
    payload="${3:-}"

    # Debug logging for the request
    log_message "DEBUG" "Making $method request to: $endpoint"
    [[ -n "$payload" ]] && log_message "DEBUG" "With payload: $payload"

    # Check if in debug mode (no POST)
    if [[ "${DEBUG_NO_POST:-}" == "true" ]]; then
        log_message "DEBUG" "=== DEBUG MODE (no POST) ==="
        [[ -n "$payload" ]] && echo "$payload" | jq '.'
        log_message "DEBUG" "=== END DEBUG MODE ==="
        return 0
    fi

    # Ensure a valid token is available
    ensure_valid_token || return 1

    local response http_code attempt
    for ((attempt = 1; attempt <= RETRY_COUNT; attempt++)); do
        if [[ "$attempt" != "1" ]]; then
            log_message "INFO" "Retry attempt $attempt of $RETRY_COUNT"
        fi

        # Execute the API request using curl
        response=$(curl -s -X "$method" \
            -H "Content-Type: $CONTENT_TYPE" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            ${payload:+-d "$payload"} \
            -w "\n%{http_code}" \
            "$endpoint")

        http_code=$(echo "$response" | tail -n 1)
        response=$(echo "$response" | sed '$d')

        # Log response details
        log_message "DEBUG" "Received HTTP status: $http_code"
        log_message "DEBUG" "Response: $response"

        if [[ "$http_code" =~ ^2 ]]; then
            if echo "$response" | jq -e . >/dev/null 2>&1; then
                log_message "DEBUG" "Successful API response received."
                echo "$response"
                return 0
            else
                log_message "WARNING" "Malformed JSON response received"
                echo "$response"
                return 0
            fi
        elif [[ "$http_code" =~ ^5 ]]; then
            log_message "WARNING" "Server error ($http_code). Retrying ($attempt/$RETRY_COUNT)..."
            sleep "$SLEEP_DURATION"
            continue
        else
        log_message "ERROR" "API request failed with HTTP status $http_code: $response"
        return 1
        fi
    done

    log_message "ERROR" "API request failed after $RETRY_COUNT attempts to $endpoint"
    return 1
}