#!/bin/bash

# Set up test environment
# Load environment variables from config.env
if [[ -f "../config.env" ]]; then
    source "../config.env"
else
    echo "Error: config.env not found"
    exit 1
fi
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
source "../lib/common.sh"
source "../lib/logging.sh"
source "../lib/validation.sh"
source "../lib/commands/command.sh"
source "../lib/commands/jobs.sh"

echo "Starting jobs command tests..."

# Test help display
run_test "Jobs Help" "jobs_help"

# Test jobs list command
#run_test "Jobs List" "jobs_cmd list --subscription 00120560"

# Test jobs create command
#run_test "Jobs Create" "jobs_cmd create --start 2024-01-01 --end 2024-01-01 --subscription 00120560"

# Test jobs create with stage
#run_test "Jobs Create with Stage" "jobs_cmd create --start 2024-01-01 --end 2024-01-01 --subscription 00120560 --stage 1001"

# Test jobs batch command
#echo "date,subscription_id,stage_id" > test.csv
#echo "2024-01-01,00120560,1001" >> test.csv
#run_test "Jobs Batch" "jobs_cmd batch --file test.csv"

# Test error cases
#run_test "Missing Subscription" "jobs_cmd list" 1
#run_test "Invalid Date" "jobs_cmd create --start 2024-13-01 --end 2024-01-01 --subscription 00120560" 1
#run_test "Missing CSV File" "jobs_cmd batch" 1

# Clean up
rm -f test.csv

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]
