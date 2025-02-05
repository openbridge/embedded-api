#!/bin/bash
#
# History endpoint operations

# Guard against multiple inclusion
[[ -n "${_API_HISTORY_SH:-}" ]] && return
readonly _API_HISTORY_SH=1

# Source required modules
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
[[ -n "${_LOGGING_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
[[ -n "${_VALIDATION_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
[[ -n "${_API_CLIENT_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
[[ -n "${_API_AUTH_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"

create_jobs() {
    local start_date="$1"
    local end_date="$2"
    local subscription_id="$3"
    local stage_id="${4:-}"

    # Validate dates first
    validate_date "$start_date" "start date"
    validate_date "$end_date" "end date"
    validate_date_range "$start_date" "$end_date"

    # Then validate subscription ID
    if [[ -z "$subscription_id" ]]; then
        error_exit "Subscription ID is missing or empty"
    fi

    # Encode subscription ID with fallback
    local encoded_subscription_id
    if command -v jq &>/dev/null; then
        encoded_subscription_id=$(printf '%s' "$subscription_id" | jq -sRr @uri)
    else
        log_message "WARNING" "jq not found, using fallback encoding"
        encoded_subscription_id=$(printf '%s' "$subscription_id" | sed 's/ /%20/g')
    fi

    # Check if encoding succeeded
    if [[ -z "$encoded_subscription_id" ]]; then
        error_exit "Failed to encode Subscription ID"
    fi

    local endpoint="${HISTORY_ENDPOINT_BASE}/${encoded_subscription_id}"
    log_message "INFO" "Creating jobs for Subscription ID: $subscription_id, Date Range: $start_date to $end_date"

    # Construct API payload
    local payload
    if [[ -n "$stage_id" ]]; then
        local start_time
        start_time=$(generate_future_timestamp)
        log_message "DEBUG" "Using start time: $start_time for stage ID: $stage_id"
        
        payload=$(jq -n \
            --arg start "$start_date" \
            --arg end "$end_date" \
            --arg stage "$stage_id" \
            --arg time "$start_time" \
            '{
                data: {
                    type: "HistoryTransaction",
                    attributes: {
                        start_date: $start,
                        end_date: $end,
                        stage_id: ($stage|tonumber),
                        start_time: $time
                    }
                }
            }')
    else
        payload=$(jq -n \
            --arg start "$start_date" \
            --arg end "$end_date" \
            '{
                data: {
                    type: "HistoryTransaction",
                    attributes: {
                        start_date: $start,
                        end_date: $end
                    }
                }
            }')
    fi

    # Make API request
    local response
    response=$(api_request "POST" "$endpoint" "$payload")
    local status=$?

    if [[ $status -eq 0 ]]; then
        log_message "SUCCESS" "Job created successfully for Subscription ID: $subscription_id"
        echo "$response" | jq -C '.'
        return 0
    else
        log_message "ERROR" "Failed to create job for Subscription ID: $subscription_id"
        return $E_API_FAILURE
    fi
}

process_csv_file() {
    local csv_file="$1"

    if [[ ! -f "$csv_file" ]]; then
        error_message "CSV file not found at $csv_file"
        return 1
    fi

    # Count total lines (excluding header)
    local total_lines=$(( $(wc -l < "$csv_file") - 1 ))
    local current_line=0

    # Normalize line endings and remove BOM if present
    local temp_csv
    temp_csv=$(mktemp)
    tr -d '\r' < "$csv_file" | sed 's/^\xEF\xBB\xBF//' > "$temp_csv"

    log_message "INFO" "Processing ${total_lines} records from CSV file..."
    printf "\n"  # Add line for progress bar

    # Process each record in the CSV file
    tail -n +2 "$temp_csv" | while IFS=',' read -r date subscription_id stage_id; do
        ((current_line++))
        
        # Update progress before operations
        show_progress $current_line $total_lines
        
        subscription_id=$(echo "$subscription_id" | tr -cd '0-9')
        stage_id=$(echo "$stage_id" | tr -cd '0-9')

        if create_jobs "$date" "$date" "$subscription_id" "$stage_id"; then
            log_message "SUCCESS" "Created job for Subscription ID: ${subscription_id} (${current_line}/${total_lines})"
        else
            log_message "ERROR" "Failed to create job for Subscription ID: ${subscription_id}"
        fi
        
        # Update progress after operations
        show_progress $current_line $total_lines
    done

    printf "\n"  # New line after progress bar
    rm "$temp_csv"  # Clean up temporary CSV file
    log_message "SUCCESS" "CSV processing complete. Processed ${total_lines} records."
}