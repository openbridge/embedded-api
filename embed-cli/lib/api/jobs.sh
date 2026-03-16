#!/bin/bash
#
# Jobs endpoint operations with enhanced pagination and filtering

# Guard against multiple inclusion
[[ -n "${_API_JOBS_SH:-}" ]] && return
readonly _API_JOBS_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"

create_product_jobs() {
    local primary_job_id="$1"
    local stage_id="${2:-1000}"
    local extra_context="$3"
    local csv_file="$4"
    local batch_size=100

    [[ ! "$primary_job_id" =~ ^[0-9]+$ ]] && error_exit "Invalid primary job ID: $primary_job_id"

    # Build the array of order IDs
    local order_ids=()
    if [[ -n "$csv_file" ]]; then
        log_message "DEBUG" "Processing CSV file: $csv_file"
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip header
            [[ "$line" == "amazon_order_id" ]] && continue
            
            # Skip empty lines
            [[ -z "$line" ]] && continue
            
            # Validate and add order ID
            if [[ "$line" =~ ^[0-9]{3}-[0-9]+-[0-9]+$ ]]; then
                order_ids+=("$line")
                log_message "DEBUG" "Added order ID: $line"
            fi
        done < "$csv_file"

        if [[ ${#order_ids[@]} -eq 0 ]]; then
            error_exit "No valid order IDs found in file"
        fi
        
        log_message "DEBUG" "Total order IDs found: ${#order_ids[@]}"

    elif [[ -n "$extra_context" ]]; then
        IFS=',' read -r -a order_ids <<< "$extra_context"
        for order_id in "${order_ids[@]}"; do
            [[ ! "$order_id" =~ ^[0-9]{3}-[0-9]+-[0-9]+$ ]] && error_exit "Invalid order ID format: $order_id"
        done
    else
        error_exit "No order IDs provided"
    fi

    local total_orders=${#order_ids[@]}
    local batch_count=$(( (total_orders + batch_size - 1) / batch_size ))

    for ((batch_index=0, i=0; i<total_orders; i+=batch_size, batch_index++)); do
        local batch_end=$((i + batch_size))
        [[ $batch_end -gt $total_orders ]] && batch_end=$total_orders

        local batch_ids=("${order_ids[@]:i:batch_size}")

        local offset_minutes=$((15 + (batch_index * 15)))

        local future_day schedule
        if is_gnu_date; then
            future_day="$(date -u -d "+${offset_minutes} minutes" "+%Y-%m-%d")"
        else
            future_day="$(date -u -v+"${offset_minutes}"M "+%Y-%m-%d")"
        fi
        schedule="$(generate_future_cron "$offset_minutes")"

        local payload
        payload=$(jq -n \
            --arg start "$future_day" \
            --arg end "$future_day" \
            --arg stage "$stage_id" \
            --arg schedule "$schedule" \
            --argjson orders "$(printf '%s\n' "${batch_ids[@]}" | jq -R . | jq -sc .)" \
            '{
                data: {
                    type: "Job",
                    attributes: {
                        is_primary: false,
                        valid_date_start: $start,
                        valid_date_end: $end,
                        stage_id: ($stage|tonumber),
                        extra_context: ("{\"order_ids\": " + ($orders | tostring) + "}"),
                        request_start: 1,
                        request_end: 0,
                        schedule: $schedule
                    }
                }
            }'
        )

        log_message "DEBUG" "Creating product job batch $((batch_index + 1)) of $batch_count"

        if [[ "${DEBUG_NO_POST:-false}" == "true" ]]; then
            echo "===== DEBUG MODE (no POST) ====="
            echo "$payload" | jq '.'
            echo "================================"
        else
            local endpoint="${JOBS_ENDPOINT}/${primary_job_id}"
            local response
            if ! response=$(api_request "POST" "$endpoint" "$payload"); then
                error_exit "Failed to create product job for batch starting at index $i"
            fi
            log_message "SUCCESS" "Created product job for batch $((batch_index + 1)) of $batch_count"
        fi

        sleep 1
    done

    return 0
}

get_jobs() {
    local subscription_ids="$1"
    local start_page="${2:-1}"
    local end_page="${3:-}"
    local opts="${4:-}"
    local single_page_mode=false
    local query_params=""

    #validate_subscription_id "$subscription_ids"

    local stage_id request_start page_size created_at_gte created_at_lte
    stage_id=$(get_query_param_value "$opts" "stage_id" || true)
    request_start=$(get_query_param_value "$opts" "request_start" || true)
    page_size=$(get_query_param_value "$opts" "page_size" || true)
    created_at_gte=$(get_query_param_value "$opts" "created_at__gte" || true)
    created_at_lte=$(get_query_param_value "$opts" "created_at__lte" || true)

    if [[ -n "$stage_id" ]]; then
        [[ ! "$stage_id" =~ ^[0-9]+$ ]] && error_exit "Invalid stage ID: $stage_id"
        query_params+="&stage_id=$stage_id"
    fi

    if [[ -n "$request_start" ]]; then
        [[ ! "$request_start" =~ ^((>=|<=|>|<|=)[0-9]+|[0-9]+)$ ]] && error_exit "Invalid request_start format. Use: [>=|<=|>|<|=]NUMBER or NUMBER"
        query_params+="&request_start${request_start}"
    fi

    if [[ -n "$page_size" ]]; then
        validate_numeric "$page_size" "page size"
        [[ "$page_size" -gt "$MAX_PAGE_SIZE" ]] && error_exit "Page size cannot exceed $MAX_PAGE_SIZE"
        query_params+="&page_size=$page_size"
    fi

    if [[ -n "$created_at_gte" ]]; then
        validate_datetime "$created_at_gte" "created_at__gte" || return $?
        query_params+="&created_at__gte=$(urlencode "$created_at_gte")"
    fi
    
    if [[ -n "$created_at_lte" ]]; then
        validate_datetime "$created_at_lte" "created_at__lte" || return $?
        query_params+="&created_at__lte=$(urlencode "$created_at_lte")"
    fi

    if [[ -n "$start_page" && -z "$end_page" && "$start_page" != "1" ]]; then
        single_page_mode=true
        end_page="$start_page"
    fi

    [[ ! "$start_page" =~ ^[0-9]+$ ]] && error_exit "Invalid start page number: $start_page"

    if [[ -n "$end_page" ]]; then
        [[ ! "$end_page" =~ ^[0-9]+$ ]] && error_exit "Invalid end page number: $end_page"
        ((start_page > end_page)) && error_exit "Start page ($start_page) cannot be greater than end page ($end_page)"
    fi

    [[ "$single_page_mode" == "true" ]] && log_message "INFO" "Fetching single page $start_page for Subscription IDs: $subscription_ids"
    [[ -n "$end_page" ]] && log_message "INFO" "Fetching pages $start_page to $end_page for Subscription IDs: $subscription_ids"
    [[ -z "$end_page" && "$single_page_mode" == "false" ]] && log_message "INFO" "Fetching all pages starting from $start_page for Subscription IDs: $subscription_ids"

    local current_page=$start_page
    local max_pages=${end_page:-100}
    local has_next_page=true

    while [[ "$has_next_page" == "true" && $current_page -le $max_pages ]]; do
        log_message "INFO" "Fetching jobs for Subscription IDs: ${subscription_ids}, Page: $current_page"

        local response
        if ! response=$(get_jobs_page "$subscription_ids" "$current_page" "$query_params"); then
            log_message "ERROR" "Failed to retrieve page $current_page for Subscription IDs: $subscription_ids"
            return 1
        fi

        if [[ -z "$response" || "$response" == "null" ]]; then
            log_message "INFO" "No more data. Stopped fetching at page $current_page"
            break
        fi

        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -C '.'
        else
            log_message "WARNING" "Response not valid JSON, outputting raw"
            echo "$response"
        fi

        [[ "$single_page_mode" == "true" ]] && break

        local next_page
        next_page=$(echo "$response" | jq -r '.links.next')
        if [[ -z "$next_page" || "$next_page" == "null" ]]; then
            has_next_page=false
            log_message "INFO" "Reached last available page: $current_page"
            break
        fi

        if [[ -n "$end_page" && $current_page -ge $end_page ]]; then
            log_message "INFO" "Reached requested end page: $end_page"
            break
        fi

        ((current_page++))
        sleep "$SLEEP_DURATION"
    done

    return 0
}

get_jobs_page() {
    local subscription_ids="$1"
    local page="${2:-1}"
    local query_params="${3:-}"

    local endpoint="${JOBS_ENDPOINT}?subscription_ids=${subscription_ids}&page=${page}${query_params}"
    log_message "DEBUG" "Requesting jobs from: ${endpoint}"

    api_request "GET" "$endpoint"
}
