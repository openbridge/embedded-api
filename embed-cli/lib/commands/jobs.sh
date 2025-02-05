#!/bin/bash
#
# Jobs command handler

# Guard against multiple inclusion
[[ -n "${_JOBS_COMMAND_SH:-}" ]] && return
readonly _JOBS_COMMAND_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
[[ -n "${_API_JOBS_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/jobs.sh"
[[ -n "${_API_HISTORY_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../api/history.sh"

jobs_cmd() {
    local subcommand="$1"
    shift || true

    case "$subcommand" in
        list)
            jobs_list_cmd "$@"
            ;;
        create)
            jobs_create_cmd "$@"
            ;;
        create-product)
            jobs_create_product_cmd "$@"
            ;;
        batch)
            jobs_batch_cmd "$@"
            ;;
        --help|-h|help)
            jobs_help
            ;;
        *)
            error_exit "Unknown jobs subcommand: $subcommand"
            ;;
    esac
}

jobs_list_cmd() {
    local subscription_id=""
    local start_page="" end_page=""
    local is_single_page=false
    local opts=""
    local params=()
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --subscription|-s)
                subscription_id="$2"
                shift 2
                ;;
            --page|-p)
                start_page="$2"
                is_single_page=true
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
            --last-days)
                # Calculate start and end times for the day range
                local start_time
                local end_time
                start_time=$(get_relative_date "$2" "start")
                end_time=$(get_relative_date "0" "end")
                params+=("created_at__gte=$start_time" "created_at__lte=$end_time")
                shift 2
                ;;
            --page-size)
                params+=("page_size=$2")
                shift 2
                ;;
            --stage)
                params+=("stage_id=$2")
                shift 2
                ;;
            --request-start)
                params+=("request_start=$2")
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    if [[ -z "$subscription_id" ]]; then
        error_exit "Subscription ID is required"
    fi

    # Construct options string
    if [[ ${#params[@]} -gt 0 ]]; then
        opts=$(IFS='&'; echo "${params[*]}")
    fi

    # Handle different pagination modes
    if [[ "$is_single_page" == "true" ]]; then
        get_jobs "$subscription_id" "$start_page" "" "$opts"
    elif [[ -n "$start_page" && -n "$end_page" ]]; then
        get_jobs "$subscription_id" "$start_page" "$end_page" "$opts"
    else
        get_jobs "$subscription_id" "${start_page:-1}" "" "$opts"
    fi
}

jobs_create_cmd() {
    local start_date="" end_date="" subscription_id="" stage_id=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --start|-s)
                start_date="$2"
                shift 2
                ;;
            --end|-e)
                end_date="$2"
                shift 2
                ;;
            --subscription|-i)
                subscription_id="$2"
                shift 2
                ;;
            --stage|-t)
                stage_id="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    # Validate required params
    if [[ -z "$start_date" || -z "$end_date" || -z "$subscription_id" ]]; then
        error_exit "Missing required parameters. Use --help for usage."
    fi

    create_jobs "$start_date" "$end_date" "$subscription_id" "$stage_id"
}

jobs_create_product_cmd() {
    if [[ $# -eq 0 ]]; then
        error_exit "No arguments provided"
    fi
    
    local primary_job_id="" stage_id="1000" extra_context="" csv_file=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --job-id|-j)
                primary_job_id="$2"
                if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                    error_exit "Invalid job ID: $2"
                fi
                shift 2
                ;;
            --stage|-s)
                stage_id="$2"
                if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                    error_exit "Invalid stage ID: $2"
                fi
                shift 2
                ;;
            --orders|-o)
                extra_context="$2"
                shift 2
                ;;
            --file|-f)
                csv_file="$2"
                if [[ ! -f "$csv_file" ]]; then
                    error_exit "File not found: $csv_file"
                fi
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    # Validate mutually exclusive options
    if [[ -n "$extra_context" && -n "$csv_file" ]]; then
        error_exit "Cannot specify both --orders and --file"
    fi

    if [[ -z "$primary_job_id" ]]; then
        error_exit "Primary job ID is required"
    fi

    if [[ -z "$extra_context" && -z "$csv_file" ]]; then
        error_exit "Either --orders or --file must be specified"
    fi

    create_product_jobs "$primary_job_id" "$stage_id" "$extra_context" "$csv_file"
}

jobs_batch_cmd() {
    local file=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file|-f)
                file="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    if [[ -z "$file" ]]; then
        error_exit "CSV file is required"
    fi

    process_csv_file "$file"
}

jobs_help() {
    cat << 'HELP'
Usage: embed-kit jobs COMMAND [options]

Commands:
    list        List jobs for a subscription
    create      Create a new job
    batch       Process batch jobs from CSV

List options:
    --subscription, -s ID    Subscription ID to list jobs for
    --page, -p NUMBER       Get a single specific page
    --start-page, -S NUMBER Start page for range
    --end-page, -e NUMBER   End page for range
    --range, -r START-END   Page range in format: start-end (e.g., 1-10)
    --last-days NUMBER      Show results from the last N days
    --page-size NUMBER      Results per page (max 100)
    --stage NUMBER         Stage ID to filter by (e.g., 1002)
    --request-start VALUE   Filter by request_start using operators: 
                          [>=|<=|>|<|=]NUMBER or NUMBER

Create options:
    --start, -s DATE        Start date (YYYY-MM-DD)
    --end, -e DATE         End date (YYYY-MM-DD)
    --subscription, -i ID   Subscription ID
    --stage, -t ID         Optional stage ID

Create product options:
    --job-id, -j ID      Primary job ID
    --stage, -s ID       Stage ID (default: 1000)
    --orders, -o LIST    Comma-separated order IDs
    --file, -f PATH     CSV file containing order IDs

Batch options:
    --file, -f PATH        Path to CSV file

Examples:
    embed-kit jobs list --subscription 116223
    embed-kit jobs list --subscription 116223 --page 5
    embed-kit jobs list --subscription 116223 --range 5-10
    embed-kit jobs list --subscription 116223 --last-days 7
    embed-kit jobs list --subscription 116223 --page-size 50
    embed-kit jobs list --subscription 116223 --stage 1002 --request-start ">=15"
    embed-kit jobs list --subscription 116223 --stage 1002 --request-start "<10"
    embed-kit jobs create --start 2024-01-01 --end 2024-01-01 --subscription 116223
    embed-kit jobs batch --file jobs.csv
    embed-kit jobs create-product --job-id 12345 --orders "111-2222-3333,444-5555-6666"
    embed-kit jobs create-product --job-id 12345 --file orders.csv
HELP
}

# Register the command
register_command "jobs" "jobs_cmd" "Manage jobs and historical transactions"