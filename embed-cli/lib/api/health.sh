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

if ! declare -p VALID_STATUSES &> /dev/null; then
  declare -a VALID_STATUSES=("healthy" "degraded" "unhealthy")
fi

calculate_relative_date() {
  local days="$1"
  local time="${2:-start}"  # start or end

  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    if [[ "${time}" == "start" ]]; then
      date -d "${days} days ago 00:00:00" "+%Y-%m-%d %H:%M:%S"
    else
      date -d "${days} days ago 23:59:59" "+%Y-%m-%d %H:%M:%S"
    fi
  else
    # BSD date (macOS)
    if [[ "${time}" == "start" ]]; then
      date -v "-${days}d" -v 0H -v 0M -v 0S "+%Y-%m-%d %H:%M:%S"
    else
      date -v "-${days}d" -v 23H -v 59M -v 59S "+%Y-%m-%d %H:%M:%S"
    fi
  fi
}

validate_datetime() {
  local datetime="$1"
  local label="$2"
  
  if [[ ! "${datetime}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    error_exit "Invalid ${label} format. Use: YYYY-MM-DD HH:MM:SS"
  fi
}

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

urlencode() {
  local string="$1"
  local strlen="${#string}"
  local encoded=""
  local pos c o

  for ((pos=0; pos<strlen; pos++)); do
    c="${string:${pos}:1}"
    case "${c}" in
      [-_.~a-zA-Z0-9]) o="${c}" ;;
      *) printf -v o '%%%02x' "'${c}" ;;
    esac
    encoded+="${o}"
  done
  printf "%s" "${encoded}"
}

build_query_params() {
  local params=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)
        validate_status "$2"
        params+=("status=$(urlencode "$2")")
        shift 2
        ;;
      --start-date)
        validate_datetime "$2" "start date"
        params+=("start_time=$(urlencode "$2")")
        shift 2
        ;;
      --end-date)
        validate_datetime "$2" "end date"
        params+=("end_time=$(urlencode "$2")")
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  printf "&%s" "${params[@]}"
}

get_healthcheck() {
  local start_page="${1:-1}"
  local end_page="${2:-${start_page}}"
  local opts=("${@:3}")
  local account_id
  local query_params

  account_id=$(get_user_id) || {
    log_message "ERROR" "Failed to retrieve account ID for health check"
    return 1
  }

  query_params=$(build_query_params "${opts[@]}")

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