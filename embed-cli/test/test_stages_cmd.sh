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
source lib/commands/stages.sh

echo "Starting stages command tests..."

# Test help display
run_test "Stages Help" "stages_help"

# Test stages list command
run_test "Stages List" "stages_cmd list --product 70"

# Test error cases
run_test "Missing Product ID" "stages_cmd list" 1
run_test "Invalid Subcommand" "stages_cmd invalid_subcommand" 1

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]
