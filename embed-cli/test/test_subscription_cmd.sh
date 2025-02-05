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
source lib/commands/subscription.sh

echo "Starting subscription command tests..."

# Test help display
run_test "Subscription Help" "subscription_help"

# Test subscription list command
#run_test "List All Subscriptions" "subscription_cmd list"
#run_test "List Active Subscriptions" "subscription_cmd list --status active"
#run_test "List With Page Size" "subscription_cmd list --page-size 50"
run_test "List With Date Filter" 'subscription_cmd list --created-after "2024-10-01T00:00:00"'

# # Test subscription update command
# run_test "Update Status" "subscription_cmd update --id 123456 --status active"
# run_test "Update Storage Group" "subscription_cmd update --id 123456 --storage-group 1289"

# # Test error cases
# run_test "Invalid Status" "subscription_cmd list --status invalid" 1
# run_test "Missing ID" "subscription_cmd update --status active" 1
# run_test "Invalid Storage Group" "subscription_cmd update --id 123456 --storage-group invalid" 1
# run_test "Invalid Subcommand" "subscription_cmd invalid_subcommand" 1
# run_test "Invalid Update Type" "subscription_cmd update --id 123456 --invalid type" 1

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]