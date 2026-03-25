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
    "${API_DIR}/jobs.sh"
    "${API_DIR}/history.sh"
    "${COMMANDS_DIR}/command.sh"
    "${COMMANDS_DIR}/jobs.sh"
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
echo "Starting jobs command tests..."

# Test help display
run_test "Jobs Help" "jobs_help"

# Test no-subcommand shows help instead of crashing
run_test "Jobs No Subcommand" "jobs_cmd" 0

# Error cases - expect status 255 for error_exit calls
run_test "Missing Subscription on List" "jobs_cmd list" 255
run_test "Invalid Subcommand" "jobs_cmd invalid_subcommand" 255
run_test "Batch Missing File" "jobs_cmd batch" 255
run_test "Create-Product No Args" "jobs_cmd create-product" 255

# Print summary
echo -e "\nTest Summary:"
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${RESET}"

# Exit with failure if any tests failed
[[ $TESTS_FAILED -eq 0 ]]
