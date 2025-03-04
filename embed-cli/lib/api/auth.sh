#!/bin/bash
#
# Authentication and token management with caching

# Guard against multiple inclusion
[[ -n "${_API_AUTH_SH:-}" ]] && return
readonly _API_AUTH_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"

# Cache settings
readonly CACHE_DIR="${CACHE_DIR:-/app/cache}"
readonly TOKEN_CACHE="${CACHE_DIR}/jwt_token.json"
readonly TOKEN_EXPIRY_BUFFER=300  # 5 minutes buffer before expiry

# Initialize cache directory
init_cache() {
    if [[ ! -d "$CACHE_DIR" ]]; then
        mkdir -p "$CACHE_DIR" 2>/dev/null || {
            log_message "DEBUG" "Cache directory unavailable, continuing without cache"
            return 0
        }
        log_message "DEBUG" "Created cache directory: $CACHE_DIR"
    fi
}

decode_jwt_payload() {
    local token="$1"
    local payload
    
    if [[ -z "$token" ]]; then
        log_message "DEBUG" "Empty token provided"
        return 1
    fi

    # Check basic JWT format first
    if [[ ! "$token" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
        log_message "DEBUG" "Invalid JWT format"
        return 1
    fi
    
    # Extract payload (second part of JWT)
    if ! payload=$(echo -n "${token#*.}" | cut -d. -f1 | base64 -d 2>/dev/null); then
        log_message "DEBUG" "Failed to decode base64 payload"
        return 1
    fi
    
    # Verify it's valid JSON
    if ! echo "$payload" | jq empty 2>/dev/null; then
        log_message "DEBUG" "Invalid JSON in payload"
        return 1
    fi

    echo "$payload"
    return 0
}

load_cached_token() {
    if [[ ! -f "$TOKEN_CACHE" ]]; then
        return 1
    fi

    # Load token from cache
    local cached_token
    cached_token=$(jq -r '.token' "$TOKEN_CACHE" 2>/dev/null)
    if [[ -z "$cached_token" || "$cached_token" == "null" ]]; then
        return 1
    fi

    # Set the token for validation
    AUTH_TOKEN="$cached_token"
    return 0
}

is_token_valid() {
    local token="${1:-$AUTH_TOKEN}"
    
    if [[ -z "$token" ]]; then
        log_message "DEBUG" "No token provided for validation"
        return 1
    fi

    local payload
    payload=$(decode_jwt_payload "$token")
    if [[ $? -ne 0 ]]; then
        log_message "DEBUG" "Invalid token format or corrupted payload"
        return 1
    fi

    # Extract and validate required fields
    local expires_at user_id account_id
    expires_at=$(echo "$payload" | jq -r '.expires_at')
    user_id=$(echo "$payload" | jq -r '.user_id')
    account_id=$(echo "$payload" | jq -r '.account_id')

    # Validate required fields
    if [[ -z "$user_id" || "$user_id" == "null" || 
          -z "$account_id" || "$account_id" == "null" || 
          -z "$expires_at" || "$expires_at" == "null" ]]; then
        log_message "DEBUG" "Token missing required fields"
        return 1
    fi

    # Check expiry
    local current_time
    current_time=$(date +%s)
    expires_at=$(printf "%.0f" "$expires_at")

    if (( current_time + TOKEN_EXPIRY_BUFFER >= expires_at )); then
        log_message "DEBUG" "Token expired or will expire soon"
        return 1
    fi

    log_message "DEBUG" "JWT token valid until $(date -d "@$expires_at" "+%Y-%m-%d %H:%M:%S")"
    return 0
}

save_token() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        log_message "DEBUG" "Empty token provided to save"
        return 0
    fi

    # Only attempt to cache if token appears valid
    if decode_jwt_payload "$token" >/dev/null 2>&1; then
        # Only attempt to cache if CACHE_DIR exists and is writable
        if [[ -d "$CACHE_DIR" && -w "$CACHE_DIR" ]]; then
            init_cache
            
            local payload
            payload=$(decode_jwt_payload "$token")
            local expires_at
            expires_at=$(echo "$payload" | jq -r '.expires_at')
            expires_at=$(printf "%.0f" "$expires_at")

            if jq -n \
                --arg token "$token" \
                --arg expires_at "$expires_at" \
                --arg payload "$payload" \
                '{
                    token: $token,
                    expires_at: ($expires_at|tonumber),
                    payload: ($payload|fromjson)
                }' > "$TOKEN_CACHE" 2>/dev/null; then
                log_message "DEBUG" "Token cached, expires: $(date -d "@$expires_at" "+%Y-%m-%d %H:%M:%S")"
            else
                log_message "DEBUG" "Unable to cache token, continuing without caching"
            fi
        else
            log_message "DEBUG" "Cache directory not available, continuing without caching"
        fi
    else
        log_message "DEBUG" "Token validation failed, skipping cache"
    fi

    # Return success regardless of caching outcome
    return 0
}

validate_jwt() {
    # First try to get token from environment
    if [[ -z "${AUTH_TOKEN:-}" ]]; then
        # If no token in environment, try cache
        if ! load_cached_token; then
            log_message "DEBUG" "No token found in environment or cache"
            return 1
        fi
    fi

    # Validate the token
    if ! is_token_valid "$AUTH_TOKEN"; then
        return 1
    fi

    return 0
}

retrieve_jwt_using_refresh() {
    if [[ -z "${REFRESH_TOKEN:-}" ]]; then
        log_message "ERROR" "No refresh token available"
        return 1
    fi

    log_message "DEBUG" "Retrieving new token using refresh token"
    
    local payload response
    payload=$(jq -n --arg token "$REFRESH_TOKEN" \
         '{data: {type: "APIAuth", attributes: {refresh_token: $token}}}')
    
    response=$(curl -s -X POST \
         -H "Content-Type: application/json" \
         -d "$payload" \
         "$AUTH_ENDPOINT")
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to connect to auth endpoint"
        return 1
    fi

    if ! echo "$response" | jq empty 2>/dev/null; then
        log_message "ERROR" "Invalid JSON response from auth endpoint"
        return 1
    fi

    AUTH_TOKEN=$(echo "$response" | jq -r '.data.attributes.token')
    if [[ "$AUTH_TOKEN" == "null" || -z "$AUTH_TOKEN" ]]; then
        log_message "ERROR" "No token in response"
        return 1
    fi

    # Try to cache the token, but don't fail if caching unavailable
    save_token "$AUTH_TOKEN"

    log_message "SUCCESS" "Successfully retrieved new token"
    return 0
}

ensure_valid_token() {
    if ! validate_jwt; then
        log_message "DEBUG" "No valid token found, attempting refresh"
        if ! retrieve_jwt_using_refresh; then
            return 1
        fi
    fi
    return 0
}