#!/usr/bin/env bash

# Test script to validate the entrypoint.sh validation logic
# This tests the input validation improvements made to handle Docker file accessibility

set -e

echo "Testing entrypoint.sh validation logic..."
echo "========================================"

# Set common environment variables
export GITHUB_TOKEN="test"
export GITHUB_EVENT='{"pull_request":{"number":123,"comments_url":"test","repository":{"issue_comment_url":"test"}}}'

# Test 1: No input provided at all
echo ""
echo "Test 1: No input provided"
echo "Expected: Should fail with validation error about missing input"
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE=""
if timeout 5s bash ../entrypoint.sh init 0 2>&1 | grep -q "Either COMMENTER_INPUT environment variable or COMMENTER_INPUT_FILE must be provided"; then
    echo "✅ PASS: Correctly detected missing input"
else
    echo "❌ FAIL: Did not detect missing input"
fi

# Test 2: Input file provided but doesn't exist
echo ""
echo "Test 2: Non-existent input file"
echo "Expected: Should fail with helpful error about file accessibility"
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE="/nonexistent/file.txt"
if timeout 5s bash ../entrypoint.sh init 0 2>&1 | grep -q "file does not exist or is not accessible"; then
    echo "✅ PASS: Correctly detected non-existent file"
else
    echo "❌ FAIL: Did not detect non-existent file"
fi

# Test 3: Valid environment variable input
echo ""
echo "Test 3: Valid environment variable input"
echo "Expected: Should proceed past validation (may fail later for other reasons)"
export COMMENTER_INPUT="test terraform output"
export COMMENTER_INPUT_FILE=""
if timeout 5s bash ../entrypoint.sh init 0 2>&1 | grep -q "Either COMMENTER_INPUT environment variable or COMMENTER_INPUT_FILE must be provided"; then
    echo "❌ FAIL: Should not have validation error with valid input"
else
    echo "✅ PASS: Validation passed with environment variable input"
fi

# Test 4: Valid file input
echo ""
echo "Test 4: Valid file input"
echo "Expected: Should proceed past validation (may fail later for other reasons)"
echo "test terraform init output" > /tmp/test_input.txt
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE="/tmp/test_input.txt"
if timeout 5s bash ../entrypoint.sh init 0 2>&1 | grep -q "Either COMMENTER_INPUT environment variable or COMMENTER_INPUT_FILE must be provided"; then
    echo "❌ FAIL: Should not have validation error with valid file"
else
    echo "✅ PASS: Validation passed with file input"
fi

# Test 5: Empty file content
echo ""
echo "Test 5: Empty file content"
echo "Expected: Should fail with error about no input content"
echo "" > /tmp/empty_input.txt
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE="/tmp/empty_input.txt"
if timeout 5s bash ../entrypoint.sh init 0 2>&1 | grep -q "No input content available"; then
    echo "✅ PASS: Correctly detected empty content"
else
    echo "❌ FAIL: Did not detect empty content"
fi

# Cleanup
rm -f /tmp/test_input.txt /tmp/empty_input.txt

echo ""
echo "========================================"
echo "Validation tests completed!"