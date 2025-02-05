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

# URL encoding function
urlencode() {
    local string="$1"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for ((pos=0; pos<strlen; pos++)); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9]) o="$c" ;;
            *) printf -v o '%%%02x' "'$c" ;;
        esac
        encoded+="$o"
    done
    echo "$encoded"
}

process_order_ids() {
    local csv_file="${1:-}"
    local order_ids=()
    local batch_size=100

    if [[ -z "$csv_file" ]]; then
        error_exit "CSV file path is required"
    fi

    # Check if file exists and is readable
    if [[ ! -f "$csv_file" ]]; then
        error_exit "Order IDs file not found: $csv_file"
    fi

    log_message "DEBUG" "Reading order IDs from: $csv_file"

    # Skip header line and read rest
    tail -n +2 "$csv_file" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        if [[ ! "$line" =~ ^[0-9]{3}-[0-9]+-[0-9]+$ ]]; then
            error_exit "Invalid order ID format: $line"
        fi
        
        order_ids+=("$line")
    done

    [[ ${#order_ids[@]} -eq 0 ]] && error_exit "No valid order IDs found in file"
    
    printf '%s\n' "${order_ids[@]}"
}


create_product_jobs() {
    local primary_job_id="$1"
    local stage_id="${2:-1000}"
    local extra_context="$3"
    local csv_file="$4"
    local batch_size=100

    [[ ! "$primary_job_id" =~ ^[0-9]+$ ]] && error_exit "Invalid primary job ID: $primary_job_id"

    # -------------------------------------------------------
    # We no longer rely strictly on "current_date" for validity
    # We'll compute the correct date/time for each batch below.
    # -------------------------------------------------------

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

        # Example: start at +15 min for batchIndex=0, then +30, +45, etc.
        local offset_minutes=$((15 + (batch_index * 15)))

        # 1) Compute future date/time (UTC)
        #    e.g. "2025-01-26 00 04"
        local future_ts
        future_ts="$(date -u -d "+${offset_minutes} minutes" "+%Y-%m-%d %H %M")"

        # 2) Parse it into day/hour/minute
        local future_day="${future_ts%% *}"          # e.g. 2025-01-26
        local future_rest="${future_ts#* }"          # e.g. "00 04"
        local future_hour="${future_rest%% *}"       # e.g. "00"
        local future_minute="${future_rest##* }"     # e.g. "04"

        # 3) Build cron => "4 0 * * *" (minute hour * * *)
        local schedule="${future_minute} ${future_hour} * * *"

        # 4) Use future_day for valid_date_{start,end}
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
            response=$(api_request "POST" "$endpoint" "$payload")
            [[ $? -ne 0 ]] && error_exit "Failed to create product job for batch starting at index $i"
            log_message "SUCCESS" "Created product job for batch $((batch_index + 1)) of $batch_count"
        fi

        # Sleep 1 second between batches (optional)
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

    # Validate subscription_ids
    validate_subscription_id "$subscription_ids"

    # Parse options string into associative array
    declare -A params
    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            params["$key"]="$value"
        fi
    done < <(echo "$opts" | tr '&' '\n')
    
    # Validate and process parameters
    if [[ -n "${params[stage_id]:-}" ]]; then
        if [[ ! "${params[stage_id]}" =~ ^[0-9]+$ ]]; then
            error_exit "Invalid stage ID: ${params[stage_id]}"
        fi
        query_params+="&stage_id=${params[stage_id]}"
    fi

    if [[ -n "${params[request_start]:-}" ]]; then
        if [[ ! "${params[request_start]}" =~ ^((>=|<=|>|<|=)[0-9]+|[0-9]+)$ ]]; then
            error_exit "Invalid request_start format. Use: [>=|<=|>|<|=]NUMBER or NUMBER"
        fi
        query_params+="&request_start${params[request_start]}"
    fi

    if [[ -n "${params[page_size]:-}" ]]; then
        if [[ "${params[page_size]}" -gt "$MAX_PAGE_SIZE" ]]; then
            error_exit "Page size cannot exceed $MAX_PAGE_SIZE"
        fi
        query_params+="&page_size=${params[page_size]}"
    fi

    if [[ -n "${params[created_at__gte]:-}" ]]; then
        validate_datetime "${params[created_at__gte]}" "created_at__gte"
        query_params+="&created_at__gte=$(urlencode "${params[created_at__gte]}")"
    fi
    
    if [[ -n "${params[created_at__lte]:-}" ]]; then
        validate_datetime "${params[created_at__lte]}" "created_at__lte"
        query_params+="&created_at__lte=$(urlencode "${params[created_at__lte]}")"
    fi

    # If only one page number is provided and no end_page, treat as single page request
    if [[ -n "$start_page" && -z "$end_page" && "$start_page" != "1" ]]; then
        single_page_mode=true
        end_page="$start_page"
    fi

    # Validate page numbers
    if [[ ! "$start_page" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid start page number: $start_page"
    fi

    if [[ -n "$end_page" ]]; then
        if [[ ! "$end_page" =~ ^[0-9]+$ ]]; then
            error_exit "Invalid end page number: $end_page"
        fi
        if ((start_page > end_page)); then
            error_exit "Start page ($start_page) cannot be greater than end page ($end_page)"
        fi
    fi

    if [[ "$single_page_mode" == "true" ]]; then
        log_message "INFO" "Fetching single page $start_page for Subscription IDs: $subscription_ids"
    elif [[ -n "$end_page" ]]; then
        log_message "INFO" "Fetching pages $start_page to $end_page for Subscription IDs: $subscription_ids"
    else
        log_message "INFO" "Fetching all pages starting from $start_page for Subscription IDs: $subscription_ids"
    fi

    local current_page=$start_page
    local max_pages=${end_page:-100}
    local has_next_page=true

    while [[ "$has_next_page" == "true" && $current_page -le $max_pages ]]; do
        log_message "INFO" "Fetching jobs for Subscription IDs: ${subscription_ids}, Page: $current_page"

        local response
        response=$(get_jobs_page "$subscription_ids" "$current_page" "$query_params") || {
            log_message "ERROR" "Failed to retrieve page $current_page for Subscription IDs: $subscription_ids"
            return 1
        }

        # Break if no results are returned
        if [[ -z "$response" || "$response" == "null" ]]; then
            log_message "INFO" "No more data. Stopped fetching at page $current_page"
            break
        fi

        # Format and validate JSON response
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -C '.'
        else
            log_message "WARNING" "Response not valid JSON, outputting raw"
            echo "$response"
        fi

        # If in single page mode, break after first page
        if [[ "$single_page_mode" == "true" ]]; then
            break
        fi

        # Check for next page in pagination links
        local next_page
        next_page=$(echo "$response" | jq -r '.links.next')
        if [[ -z "$next_page" || "$next_page" == "null" || "$next_page" == "" ]]; then
            has_next_page=false
            log_message "INFO" "Reached last available page: $current_page"
            break
        fi

        # Stop if we've reached the end_page (if specified)
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