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

echo "Starting embed-cli integration tests..."

# Basic command tests
run_test "Show Version" "bin/embed-cli --version"
run_test "Show Help" "bin/embed-cli --help"

# User commands
run_test "User Info" "bin/embed-cli user info"
run_test "User ID" "bin/embed-cli user id"

# Health commands
run_test "Health Check" "bin/embed-cli health check"

# Jobs commands
run_test "Jobs List" "bin/embed-cli jobs list --subscription 00120560"
run_test "Jobs Create" "bin/embed-cli jobs create --start 2024-01-01 --end 2024-01-01 --subscription 00120560"

# Stages commands
run_test "Stages List" "bin/embed-cli stages list --product 70"

# Error cases
run_test "Invalid Command" "bin/embed-cli invalid_command" 1
run_test "Missing Command" "bin/embed-cli jobs list" 1

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]
