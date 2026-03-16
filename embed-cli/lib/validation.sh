#!/bin/bash
#
# Input and environment validation functions with config loading

# Guard against multiple inclusion
[[ -n "${_VALIDATION_SH:-}" ]] && return
readonly _VALIDATION_SH=1

# Source common if not already sourced
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Config loading function
load_config() {
    local config_file="${CONFIG_FILE:-/app/config.env}"
    
    # Check if config file exists and is readable
    if [[ -f "$config_file" && -r "$config_file" ]]; then
        source "$config_file"
        return 0
    fi
    
    # If no config file, check for required environment variables
    if [[ -n "${REFRESH_TOKEN:-}" || -n "${AUTH_TOKEN:-}" ]]; then
        # Minimum required variable is present
        return 0
    fi
    
    return 1
}

validate_environment() {
    # First try to load config if present
    load_config || true  # Don't fail if config loading fails

    # Check for required environment variables
    if [[ -z "${REFRESH_TOKEN:-}" && -z "${AUTH_TOKEN:-}" ]]; then
        echo "ERROR: REFRESH_TOKEN or AUTH_TOKEN environment variable is required" >&2
        return 1
    fi

    # Validate LOG_LEVEL if set
    if [[ -n "${LOG_LEVEL:-}" ]]; then
        local normalized_log_level
        normalized_log_level=$(printf '%s' "$LOG_LEVEL" | tr '[:lower:]' '[:upper:]')
        case "$normalized_log_level" in
            DEBUG|INFO|WARN|WARNING|ERROR) ;;
            *)
                echo "ERROR: Invalid LOG_LEVEL. Must be one of: DEBUG, INFO, WARN, ERROR" >&2
                return 1
                ;;
        esac
    fi

    return 0
}

validate_datetime() {
    local datetime="$1"
    local label="$2"
    
    if [[ ! "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}([T[:space:]])[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        error_exit "Invalid $label format. Use: YYYY-MM-DDTHH:MM:SS"
    fi
}

validate_date() {
    local date="${1%$'\n'}"
    date="${date//[[:space:]]/}"
    local date_type="$2"

    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error_exit "Invalid $date_type format: $date. Expected format is YYYY-MM-DD."
    fi
}

# Export functions that need to be available to other scripts
export -f load_config
export -f validate_environment
export -f validate_datetime
export -f validate_date
