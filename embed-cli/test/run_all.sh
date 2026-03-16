#!/bin/bash

# Colors for output
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
BOLD="\033[1m"
RESET="\033[0m"

# Initialize counters for overall results
TOTAL_TESTS_RUN=0
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0
FAILED_TEST_FILES=()

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}${BOLD}$1${RESET}"
    echo -e "${BLUE}${BOLD}$(printf '=%.0s' {1..50})${RESET}\n"
}

# Function to print final summary
print_summary() {
    echo -e "\n${BOLD}${BLUE}FINAL TEST SUMMARY${RESET}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${RESET}"
    echo -e "Total Test Files Run: ${BOLD}$(ls test_*.sh | wc -l)${RESET}"
    echo -e "Total Tests Run: ${BOLD}$TOTAL_TESTS_RUN${RESET}"
    echo -e "Total Tests Passed: ${GREEN}${BOLD}$TOTAL_TESTS_PASSED${RESET}"
    echo -e "Total Tests Failed: ${RED}${BOLD}$TOTAL_TESTS_FAILED${RESET}"
    
    if [ ${#FAILED_TEST_FILES[@]} -gt 0 ]; then
        echo -e "\n${RED}${BOLD}Failed Test Files:${RESET}"
        for file in "${FAILED_TEST_FILES[@]}"; do
            echo -e "${RED}- $file${RESET}"
        done
    fi
}

# Function to extract test results from a test file's output
parse_test_results() {
    local output=$1
    local file=$2
    
    # Extract test counts using grep and awk
    local tests_run=$(echo "$output" | grep "Tests Run:" | awk '{print $NF}')
    local tests_passed=$(echo "$output" | grep "Tests Passed:" | awk '{print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
    local tests_failed=$(echo "$output" | grep "Tests Failed:" | awk '{print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
    
    # Add to totals if numbers are valid
    if [[ $tests_run =~ ^[0-9]+$ ]]; then
        TOTAL_TESTS_RUN=$((TOTAL_TESTS_RUN + tests_run))
        TOTAL_TESTS_PASSED=$((TOTAL_TESTS_PASSED + tests_passed))
        TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + tests_failed))
        
        # If any tests failed in this file, add it to the failed files array
        if [ "$tests_failed" -gt 0 ]; then
            FAILED_TEST_FILES+=("$file")
        fi
    fi
}

# Main execution

# First, check if we're in the test directory
if [[ ! $(pwd) =~ /test$ ]]; then
    if [[ -d "test" ]]; then
        cd test
        echo -e "${YELLOW}Changed directory to: $(pwd)${RESET}"
    else
        echo -e "${RED}Error: Please run this script from the project root or test directory${RESET}"
        exit 1
    fi
fi

# Check if config.env exists in parent directory
if [[ ! -f "../config.env" ]]; then
    echo -e "${RED}Error: config.env not found in parent directory${RESET}"
    exit 1
fi

print_header "Starting Test Suite Execution"

# Run each test file
for test_file in test_*.sh; do
    if [[ -f "$test_file" ]]; then
        print_header "Running $test_file"
        
        # Make sure the test file is executable
        chmod +x "$test_file"
        
        # Run the test and capture output
        output=$(./"$test_file" 2>&1)
        exit_code=$?
        
        # Print the output
        echo "$output"
        
        # Parse and add results to totals
        parse_test_results "$output" "$test_file"
        
        # Add spacing between test files
        echo
    fi
done

# Print final summary
print_summary

# Exit with failure if any tests failed
if [ $TOTAL_TESTS_FAILED -gt 0 ]; then
    exit 1
fi

exit 0