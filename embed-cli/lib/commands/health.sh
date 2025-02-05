#!/bin/bash
#
# Health check command handler

# Guard against multiple inclusion
[[ -n "${_HEALTH_COMMAND_SH:-}" ]] && return
readonly _HEALTH_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_HEALTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/health.sh"

health_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        check)
            health_check_cmd "$@"
            ;;
        --help|-h|help)
            health_help
            ;;
        *)
            error_exit "Unknown health subcommand: $subcommand"
            ;;
    esac
}

health_check_cmd() {
    local start_page="1"
    local end_page=""
    local opts=""
    local params=()
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --page|-p)
                start_page="$2"
                shift 2
                ;;
            --last-days)
                # Calculate start and end times for the day range
                local start_time
                local end_time
                start_time=$(get_relative_date "$2" "start")
                end_time=$(get_relative_date "0" "end")  # Today end
                params+=("modified_at__gte=$start_time" "modified_at__lte=$end_time")
                shift 2
                ;;
            --status)
                params+=("status=$2")
                shift 2
                ;;
            --subscription)
                params+=("subscription_id=$2")
                shift 2
                ;;
            --page-size)
                params+=("page_size=$2")
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    # Construct options string
    if [[ ${#params[@]} -gt 0 ]]; then
        opts=$(IFS='&'; echo "${params[*]}")
    fi

    get_healthcheck "$start_page" "$end_page" "$opts"
}

health_help() {
    cat << 'HELP'
Usage: embed-kit health COMMAND [options]

Commands:
    check       Get health check information

Options:
    --page, -p NUMBER     Page number for results pagination
    --last-days NUMBER    Show results from the last N days
    --status STATUS       Filter by status (ERROR, WARNING, SUCCESS, PENDING)
    --subscription ID     Filter by subscription ID
    --page-size NUMBER    Number of results per page (max 100)

Examples:
    embed-kit health check
    embed-kit health check --page 1
    embed-kit health check --last-days 2
    embed-kit health check --status ERROR
    embed-kit health check --subscription 116223
    embed-kit health check --page-size 50
HELP
}

# Register the command
register_command "health" "health_cmd" "Check system health status"
