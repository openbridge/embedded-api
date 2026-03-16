#!/bin/bash
#
# Logging functionality and output formatting

# Guard against multiple inclusion
[[ -n "${_LOGGING_SH:-}" ]] && return
readonly _LOGGING_SH=1

# Source common functions if not already sourced
[[ -n "${_COMMON_SH:-}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Color definitions
declare -r RESET="\033[0m"
declare -r BOLD="\033[1m"
declare -r DIM="\033[2m"
declare -r RED="\033[31m"
declare -r GREEN="\033[32m"
declare -r YELLOW="\033[33m"
declare -r BLUE="\033[34m"
declare -r CYAN="\033[36m"
declare -r GRAY="\033[37m"

# Log levels and their numeric values (higher = more severe)
get_log_level_value() {
    local level="$1"
    case "$level" in
        "DEBUG") echo 0 ;;
        "INFO") echo 1 ;;
        "WARNING") echo 2 ;;
        "ERROR") echo 3 ;;
        "SUCCESS") echo 1 ;; # Same as INFO level
        *) echo 1 ;; # Default to INFO if invalid
    esac
}

# Current log level
readonly CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"

should_log() {
    local msg_level="$1"
    local current_level
    local msg_level_num
    
    current_level=$(get_log_level_value "$CURRENT_LOG_LEVEL")
    msg_level_num=$(get_log_level_value "$msg_level")
    
    [[ $msg_level_num -ge $current_level ]]
}

log_message() {
    local level="$1"
    local message="$2"
    
    # Skip if message shouldn't be logged at current level
    should_log "$level" || return 0
    
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # First check if we're in a terminal and if we want color output
    if [[ -t 2 ]] && [[ "${NO_COLOR:-}" != "true" ]]; then
        case $level in
            "DEBUG")   printf "%b │ %bDEBUG%b │ %b%s%b\n" "${DIM}${timestamp}" "${GRAY}${BOLD}" "${RESET}" "${GRAY}" "$message" "${RESET}" ;;
            "INFO")    printf "%b │ %bINFO%b │ %b%s%b\n" "${DIM}${timestamp}" "${BLUE}${BOLD}" "${RESET}" "${CYAN}" "$message" "${RESET}" ;;
            "WARNING") printf "%b │ %bWARN%b │ %b%s%b\n" "${DIM}${timestamp}" "${YELLOW}${BOLD}" "${RESET}" "${YELLOW}" "$message" "${RESET}" ;;
            "ERROR")   printf "%b │ %bERROR%b │ %b%s%b\n" "${DIM}${timestamp}" "${RED}${BOLD}" "${RESET}" "${RED}${BOLD}" "$message" "${RESET}" ;;
            "SUCCESS") printf "%b │ %bOK%b │ %b%s%b\n" "${DIM}${timestamp}" "${GREEN}${BOLD}" "${RESET}" "${GREEN}" "$message" "${RESET}" ;;
            *)        printf "%b │ %b%s%b │ %s\n" "${DIM}${timestamp}" "${GRAY}" "$level" "${RESET}" "$message" ;;
        esac
    else
        # No color output
        printf "%s - [%s] - %s\n" "${timestamp}" "${level}" "${message}"
    fi >&2

    # Always log to file without color codes if LOG_FILE is set
    if [[ -n "${LOG_FILE:-}" ]]; then
        printf "%s - [%s] - %s\n" "${timestamp}" "${level}" "${message}" >> "${LOG_FILE}"
    fi
}

error_message() {
    local message="$1"
    log_message "ERROR" "$message"
}

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    # Save cursor position
    printf "\e[s"
    # Move to start of line and clear it
    printf "\e[0G\e[K"
    # Print progress bar
    printf "%bProgress: %b[" "${BLUE}" "${RESET}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %b%d%%%b" "${CYAN}" "$percentage" "${RESET}"
    # Restore cursor position
    printf "\e[u\e[B"
}

show_spinner() {
    local pid=$1
    local message="${2:-Loading...}"
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r%b%s %b%s%b" "${BLUE}" "${message}" "${BOLD}" "${spin:$i:1}" "${RESET}"
        sleep .1
    done
    printf "\r"
}