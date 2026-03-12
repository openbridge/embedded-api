#!/usr/bin/env bash
#
# Health check endpoint operations with enhanced filtering and relative dates

set -o errexit
set -o nounset
set -o pipefail

# Guard against multiple inclusion
if [[ -n "${_API_HEALTH_SH:-}" ]]; then
  return
fi
readonly _API_HEALTH_SH=1

# Source required modules
if [[ -z "${_COMMON_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
fi
if [[ -z "${_LOGGING_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../logging.sh"
fi
if [[ -z "${_API_CLIENT_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/client.sh"
fi
if [[ -z "${_API_AUTH_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/auth.sh"
fi
if [[ -z "${_API_USER_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/user.sh"
fi
if [[ -z "${_VALIDATION_SH:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../validation.sh"
fi

if ! declare -p VALID_STATUSES &> /dev/null; then
  declare -a VALID_STATUSES=("healthy" "degraded" "unhealthy")
fi

validate_status() {
  local status="$1"
  local valid=false
  
  for valid_status in "${VALID_STATUSES[@]}"; do
    if [[ "${status}" == "${valid_status}" ]]; then
      valid=true
      break
    fi
  done
  
  if [[ "${valid}" != "true" ]]; then
    error_exit "Invalid status: ${status}. Valid values are: ${VALID_STATUSES[*]}"
  fi
}

build_query_params() {
  local opts="$1"
  local query_params=""
  local status page_size subscription_id modified_gte modified_lte

  status=$(get_query_param_value "$opts" "status" || true)
  page_size=$(get_query_param_value "$opts" "page_size" || true)
  subscription_id=$(get_query_param_value "$opts" "subscription_id" || true)
  modified_gte=$(get_query_param_value "$opts" "modified_at__gte" || true)
  modified_lte=$(get_query_param_value "$opts" "modified_at__lte" || true)

  if [[ -n "$status" ]]; then
    validate_status "$status"
    query_params+="&status=$(urlencode "$status")"
  fi

  if [[ -n "$page_size" ]]; then
    validate_numeric "$page_size" "page size"
    (( page_size <= MAX_PAGE_SIZE )) || error_exit "Page size cannot exceed $MAX_PAGE_SIZE"
    query_params+="&page_size=$page_size"
  fi

  if [[ -n "$subscription_id" ]]; then
    validate_numeric "$subscription_id" "subscription ID"
    query_params+="&subscription_id=$subscription_id"
  fi

  if [[ -n "$modified_gte" ]]; then
    validate_datetime "$modified_gte" "modified_at__gte"
    query_params+="&modified_at__gte=$(urlencode "$modified_gte")"
  fi

  if [[ -n "$modified_lte" ]]; then
    validate_datetime "$modified_lte" "modified_at__lte"
    query_params+="&modified_at__lte=$(urlencode "$modified_lte")"
  fi

  printf "%s" "$query_params"
}

get_healthcheck() {
  local start_page="${1:-1}"
  local end_page="${2:-${start_page}}"
  local opts="${3:-}"
  local account_id
  local query_params

  account_id=$(get_user_id) || {
    log_message "ERROR" "Failed to retrieve account ID for health check"
    return 1
  }

  query_params=$(build_query_params "$opts") || return $?

  for ((current_page=start_page; current_page<=end_page; current_page++)); do
    log_message "INFO" "Fetching page ${current_page} for Account ID: ${account_id}"
    
    local response
    response=$(get_healthcheck_page "${account_id}" "${current_page}" "${query_params}") || {
      log_message "ERROR" "Failed to retrieve page ${current_page} for Account ID: ${account_id}"
      return 1
    }

    if jq -e . >/dev/null 2>&1 <<<"${response}"; then
      jq -C '.' <<<"${response}"
    else
      printf "%s\n" "${response}"
    fi
  done
}

get_healthcheck_page() {
  local account_id="$1"
  local page="${2:-1}"
  local query_params="${3:-}"

  local endpoint="${HEALTHCHECK_ENDPOINT}/${account_id}?page=${page}${query_params}"
  log_message "DEBUG" "Requesting health check from: ${endpoint}"

  api_request "GET" "${endpoint}"
}
