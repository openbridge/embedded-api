#!/bin/bash

# First, establish the base paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="${BASE_DIR}/lib"
COMMANDS_DIR="${LIB_DIR}/commands"
API_DIR="${LIB_DIR}/api"

# Set up test environment
if [[ -f "${BASE_DIR}/config.env" ]]; then
    source "${BASE_DIR}/config.env"
else
    echo "Error: config.env not found"
    exit 1
fi

# Set up logging variables
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export LOG_FILE="${LOG_FILE:-}"
export NO_COLOR="${NO_COLOR:-false}"

# Colors for test output
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"
BLUE="\033[34m"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
run_test() {
    local name="$1"
    local command="$2"
    local expected_status="${3:-0}"
    
    echo -e "\n${BLUE}Running test: $name${RESET}"
    ((TESTS_RUN++))
    
    # Run command with error handling
    {
        output=$(eval "$command" 2>&1)
        status=$?
    } || {
        status=$?
    }
    
    # Show command output
    echo "Command output:"
    echo "$output"
    echo "Exit status: $status"
    
    if [[ $status -eq $expected_status ]]; then
        echo -e "${GREEN}✓ Test passed${RESET}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Test failed (got status $status)${RESET}"
        ((TESTS_FAILED++))
    fi
}

echo "Sourcing required files..."

# Source files in correct dependency order using absolute paths
source_files=(
    "${LIB_DIR}/common.sh"
    "${LIB_DIR}/logging.sh"
    "${LIB_DIR}/validation.sh"
    "${API_DIR}/client.sh"
    "${API_DIR}/auth.sh"
    "${API_DIR}/user.sh"
    "${API_DIR}/subscription.sh"
    "${COMMANDS_DIR}/command.sh"
    "${COMMANDS_DIR}/subscription.sh"
)

for file in "${source_files[@]}"; do
    echo "Sourcing: $file"
    if [[ ! -f "$file" ]]; then
        echo "Error: Cannot find $file"
        exit 1
    fi
    source "$file" || {
        echo "Error sourcing $file"
        exit 1
    }
done

# Temporarily disable strict error handling for tests
set +e
set +u
set +o pipefail

echo "Finished sourcing files"
echo "Starting subscription command tests..."

# Basic command tests - expect success (0)
run_test "Subscription Help" "subscription_help" 0
run_test "List All Subscriptions" "subscription_cmd list" 0
run_test "List With Status Filter" "subscription_cmd list --status invalid" 0
run_test "List With Date Filter" "subscription_cmd list --created-after \"2024-10-01T00:00:00\"" 0

# Error cases - expect status 255 for error_exit calls
run_test "Missing ID" "subscription_cmd update --status active" 255
run_test "Invalid Subcommand" "subscription_cmd invalid_subcommand" 255

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]