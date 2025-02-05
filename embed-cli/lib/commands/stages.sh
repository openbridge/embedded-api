#!/bin/bash
#
# Stages command handler with pagination support

# Guard against multiple inclusion
[[ -n "${_STAGES_COMMAND_SH:-}" ]] && return
readonly _STAGES_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_PRODUCTS_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/products.sh"

stages_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        list)
            stages_list_cmd "$@"
            ;;
        --help|-h|help)
            stages_help
            ;;
        *)
            error_exit "Unknown stages subcommand: $subcommand"
            ;;
    esac
}

stages_list_cmd() {
    local product_id=""
    local page="1"
    local page_size=""
    local opts=""
    local params=()
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --product|-p)
                product_id="$2"
                shift 2
                ;;
            --page|-P)
                page="$2"
                shift 2
                ;;
            --page-size|-s)
                page_size="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    if [[ -z "$product_id" ]]; then
        error_exit "Product ID is required"
    fi

    # Validate and add pagination parameters
    if [[ -n "$page_size" ]]; then
        if [[ ! "$page_size" =~ ^[0-9]+$ ]]; then
            error_exit "Page size must be numeric"
        fi
        if ((page_size > MAX_PAGE_SIZE)); then
            error_exit "Page size cannot exceed $MAX_PAGE_SIZE"
        fi
        params+=("page_size=$page_size")
    fi

    if [[ -n "$page" ]]; then
        if [[ ! "$page" =~ ^[0-9]+$ ]]; then
            error_exit "Page number must be numeric"
        fi
        params+=("page=$page")
    fi

    # Construct options string
    if [[ ${#params[@]} -gt 0 ]]; then
        opts=$(IFS='&'; echo "${params[*]}")
    fi

    get_stages "$product_id" "$opts"
}

stages_help() {
    cat << 'HELP'
Usage: embed-cli stages COMMAND [options]

Commands:
    list        List stages for a product

Options:
    --product, -p ID     Product ID to list stages for
    --page, -P NUMBER    Page number for results (default: 1)
    --page-size, -s NUM  Number of results per page (max 100)

Examples:
    embed-cli stages list --product 70
    embed-cli stages list --product 70 --page 2
    embed-cli stages list --product 70 --page-size 50
HELP
}

# Register the command
register_command "stages" "stages_cmd" "Manage product stages"