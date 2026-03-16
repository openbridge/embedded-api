#!/bin/bash
#
# Base command handling functionality

# Guard against multiple inclusion
[[ -n "${_COMMAND_SH:-}" ]] && return
readonly _COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"

# Command registry
COMMAND_MAP=""

register_command() {
    local command="$1"
    local handler="$2"
    local description="$3"
    
    COMMAND_MAP="${COMMAND_MAP}${command}:${handler}:${description}\n"
}

get_handler() {
    local command="$1"
    echo -e "$COMMAND_MAP" | grep "^${command}:" | cut -d':' -f2
}

get_description() {
    local command="$1"
    echo -e "$COMMAND_MAP" | grep "^${command}:" | cut -d':' -f3
}

get_commands() {
    echo -e "$COMMAND_MAP" | cut -d':' -f1
}

execute_command() {
    local command="$1"
    shift  # Remove command from arguments

    local handler
    handler=$(get_handler "$command")
    
    if [[ -z "$handler" ]]; then
        error_exit "Unknown command: $command"
    fi
    
    $handler "$@"
}

show_help() {
    local command="${1:-}"
    
    if [[ -n "$command" ]]; then
        local handler
        handler=$(get_handler "$command")
        
        if [[ -n "$handler" ]]; then
            ${handler}_help
            return
        fi
    fi

    # Show general help
    echo "Usage: embed-cli COMMAND [options]"
    echo
    echo "Commands:"
    
    while IFS=: read -r cmd handler desc; do
        if [[ -n "$cmd" ]]; then
            printf "  %-20s %s\n" "$cmd" "$desc"
        fi
    done <<< "$(echo -e "$COMMAND_MAP")"
}
