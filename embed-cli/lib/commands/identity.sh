#!/bin/bash
#
# Identity command handler

# Guard against multiple inclusion
[[ -n "${_IDENTITY_COMMAND_SH:-}" ]] && return
readonly _IDENTITY_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_IDENTITY_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/identity.sh"

identity_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        list)
            identity_list_cmd "$@"
            ;;
        get)
            identity_get_cmd "$@"
            ;;
        --help|-h|help)
            identity_help
            ;;
        *)
            error_exit "Unknown identity subcommand: $subcommand"
            ;;
    esac
}

identity_list_cmd() {
    local start_page="1"
    local end_page=""
    local opts=""
    local params=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --page|-p)
                start_page="$2"
                shift 2
                ;;
            --start-page|-S)
                start_page="$2"
                shift 2
                ;;
            --end-page|-e)
                end_page="$2"
                shift 2
                ;;
            --range|-r)
                if [[ "$2" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    start_page="${BASH_REMATCH[1]}"
                    end_page="${BASH_REMATCH[2]}"
                else
                    error_exit "Invalid range format. Use: start-end (e.g., 1-10)"
                fi
                shift 2
                ;;
            --invalid)
                params+=("invalid_identity=$2")
                shift 2
                ;;
            --invalidated-before)
                params+=("invalidated_at__lte=$2")
                shift 2
                ;;
            --invalidated-after)
                params+=("invalidated_at__gte=$2")
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

    list_identities "$start_page" "$end_page" "$opts"
}

identity_get_cmd() {
    local id="$1"
    shift || error_exit "Identity ID is required"
    
    local invalid_status="" invalidated_at="" operator=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --invalid)
                invalid_status="$2"
                shift 2
                ;;
            --invalidated-before)
                invalidated_at="$2"
                operator="lte"
                shift 2
                ;;
            --invalidated-after)
                invalidated_at="$2"
                operator="gte"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    get_identity "$id" "$invalid_status" "$invalidated_at" "$operator"
}

identity_help() {
    cat << 'HELP'
Usage: embed-cli identity COMMAND [options]

Commands:
    list        List remote identities 
    get         Get details for specific identity

List options:
    --page, -p NUMBER            Get a single specific page
    --start-page, -S NUMBER      Start page for range
    --end-page, -e NUMBER        End page for range
    --range, -r START-END        Page range in format: start-end (e.g., 1-10)
    --page-size NUMBER           Results per page (max 100)
    --invalid STATUS             Filter by invalid status (0 or 1)
    --invalidated-before DATE    Filter by invalidation date (before)
    --invalidated-after DATE     Filter by invalidation date (after)

Get options:
    ID                          Identity ID to retrieve
    --invalid STATUS            Filter by invalid status (0 or 1)
    --invalidated-before DATE   Filter by invalidation date (before)
    --invalidated-after DATE    Filter by invalidation date (after)

Examples:
    embed-cli identity list
    embed-cli identity list --page 5
    embed-cli identity list --range 1-10
    embed-cli identity list --invalid 1
    embed-cli identity list --invalidated-before "2024-01-01T00:00:00"
    embed-cli identity list --page-size 50
    embed-cli identity get 4832
    embed-cli identity get 4832 --invalid 0
HELP
}

# Register the command
register_command "identity" "identity_cmd" "Manage remote identities"