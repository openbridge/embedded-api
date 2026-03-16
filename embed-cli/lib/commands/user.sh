#!/bin/bash
#
# User command handler

# Guard against multiple inclusion
[[ -n "${_USER_COMMAND_SH:-}" ]] && return
readonly _USER_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_USER_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/user.sh"

user_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        info)
            user_info_cmd "$@"
            ;;
        id)
            user_id_cmd "$@"
            ;;
        --help|-h|help)
            user_help
            ;;
        *)
            error_exit "Unknown user subcommand: $subcommand"
            ;;
    esac
}

user_info_cmd() {
    # Get full user information and ensure it's properly formatted
    local response
    response=$(get_user) || {
        error_exit "Failed to get user information"
    }
    
    # Output is already formatted by get_user function
    echo "$response"
}

user_id_cmd() {
    # Get just the account ID
    local id
    id=$(get_user_id) || {
        error_exit "Failed to get user ID"
    }
    echo "$id"
}

user_help() {
    cat << 'HELP'
Usage: embed-cli user COMMAND

Commands:
    info        Get full user account information
    id          Get user account ID only

Examples:
    embed-cli user info
    embed-cli user id
HELP
}

# Register the command
register_command "user" "user_cmd" "Manage user account information"