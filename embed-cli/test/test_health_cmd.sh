#!/bin/bash

# Set up test environment
export REFRESH_TOKEN="<yourtoken>"
export LOG_LEVEL="DEBUG"

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
    local expected_status="${3:-0}"  # 0 = success by default
    ((TESTS_RUN++))
    
    echo -e "\n${BLUE}Test $TESTS_RUN: $name${RESET}"
    echo "Command: $command"
    echo "Expected status: $expected_status"
    
    # Run command and capture status
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
source lib/commands/health.sh

echo "Starting health command tests..."

# Test help display
run_test "Health Help" "health_help"

# Test health check command
run_test "Health Check" "health_cmd check"

# Test health check with pagination
run_test "Health Check with Page" "health_cmd check --page 1"

# Test error case
run_test "Invalid Subcommand" "health_cmd invalid_subcommand" 1

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]
