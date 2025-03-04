#!/bin/bash
#
# Subscription command handler

# Guard against multiple inclusion
[[ -n "${_SUBSCRIPTION_COMMAND_SH:-}" ]] && return
readonly _SUBSCRIPTION_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
[[ -n "${_API_SUBSCRIPTION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/subscription.sh"

subscription_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        list)
            subscription_list_cmd "$@"
            ;;
        update)
            subscription_update_cmd "$@"
            ;;
        --help|-h|help)
            subscription_help
            ;;
        *)
            error_exit "Unknown subscription subcommand: $subcommand"
            ;;
    esac
}

subscription_list_cmd() {
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
            --status|-s)
                params+=("status=$2")
                shift 2
                ;;
            --storage-group|-g)
                params+=("storage_group=$2")
                shift 2
                ;;
            --product|-P)
                params+=("product=$2")
                shift 2
                ;;
            --created-after)
                params+=("created_at__gte=$2")
                shift 2
                ;;
            --created-before)
                params+=("created_at__lte=$2")
                shift 2
                ;;
            --modified-after)
                params+=("modified_at__gte=$2")
                shift 2
                ;;
            --modified-before)
                params+=("modified_at__lte=$2")
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

    get_subscriptions "$start_page" "$end_page" "$opts"
}

subscription_update_cmd() {
    local subscription_id=""
    local update_type=""
    local update_value=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id|-i)
                subscription_id="$2"
                shift 2
                ;;
            --status|-s)
                update_type="status"
                update_value="$2"
                shift 2
                ;;
            --storage-group|-g)
                update_type="storage_group"
                update_value="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$subscription_id" ]]; then
        error_exit "Subscription ID is required"
    fi

    if [[ -z "$update_type" || -z "$update_value" ]]; then
        error_exit "Either --status or --storage-group must be specified"
    fi

    update_subscription "$subscription_id" "$update_type" "$update_value"
}

subscription_help() {
    cat << 'HELP'
Usage: embed-cli subscription COMMAND [options]

Commands:
    list        List subscriptions
    update      Update subscription status or storage group

List options:
    --page, -p NUMBER           Specific page number
    --status, -s STATUS         Filter by status (active or cancelled)
    --storage-group, -g NUMBER  Filter by storage group ID
    --product, -P NUMBER        Filter by product ID
    --created-after DATE        Show items created after date (YYYY-MM-DDTHH:MM:SS)
    --created-before DATE       Show items created before date (YYYY-MM-DDTHH:MM:SS)
    --modified-after DATE       Show items modified after date (YYYY-MM-DDTHH:MM:SS)
    --modified-before DATE      Show items modified before date (YYYY-MM-DDTHH:MM:SS)
    --page-size NUMBER          Results per page (max 100)

Update options:
    --id, -i ID                Subscription ID to update
    --status, -s STATUS        Set subscription status (active or cancelled)
    --storage-group, -g NUMBER Set storage group ID

Examples:
    # List all subscriptions
    embed-cli subscription list

    # List active subscriptions
    embed-cli subscription list --status active

    # List subscriptions for a specific storage group
    embed-cli subscription list --storage-group 1289

    # List active subscriptions for a product
    embed-cli subscription list --status active --product 50

    # Combined filters
    embed-cli subscription list --storage-group 1289 --status active --product 50

    # List with date filters
    embed-cli subscription list --created-after 2024-01-01T00:00:00

    # Update subscription status
    embed-cli subscription update --id 123456 --status cancelled

    # Update storage group
    embed-cli subscription update --id 123456 --storage-group 1289
HELP
}

# Register the command
register_command "subscription" "subscription_cmd" "Manage subscriptions"