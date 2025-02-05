#!/bin/bash

# Set up test environment
export REFRESH_TOKEN="<yourtoken>"
export LOG_LEVEL="INFO"

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
    ((TESTS_RUN++))
    
    echo -e "\n${BLUE}Test $TESTS_RUN: $name${RESET}"
    echo "Command: $command"
    echo "Expected status: $expected_status"
    
    eval "$command"
    local status=$?
    
    if [[ $status -eq $expected_status ]]; then
        echo -e "${GREEN}✓ Test passed${RESET}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Test failed (got status $status)${RESET}"
        ((TESTS_FAILED++))
    fi
}

# Source required files for testing
source lib/common.sh
source lib/logging.sh
source lib/validation.sh
source lib/commands/command.sh
source lib/commands/identity.sh

echo "Starting identity command tests..."

# Test help display
run_test "Identity Help" "identity_help"

# Test identity list command
run_test "Identity List" "identity_cmd list"
run_test "Identity List Invalid Filter" "identity_cmd list --invalid 0"
run_test "Identity List Date Filter" "identity_cmd list --invalidated-before '2024-01-01T00:00:00'"

# Test identity get command
run_test "Identity Get" "identity_cmd get 4832"
run_test "Identity Get with Filters" "identity_cmd get 4832 --invalid 1"

# Test error cases
run_test "Missing ID" "identity_cmd get" 1
run_test "Invalid Status Value" "identity_cmd list --invalid 2" 1
run_test "Invalid Date Format" "identity_cmd list --invalidated-at 'invalid-date'" 1

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]