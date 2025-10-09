#!/usr/bin/env bash

# Test script to validate file path handling for Docker container accessibility
# This tests the file copying logic added to action.yml to handle files outside mounted paths

set -e

echo "Testing file path handling for Docker accessibility..."
echo "===================================================="

# Function to test file copying logic (simulates action.yml behavior)
test_file_copy_logic() {
    local test_file="$1"
    local description="$2"
    
    echo ""
    echo "Testing: $description"
    echo "Original path: $test_file"
    
    if [ -n "$test_file" ] && [ -f "$test_file" ]; then
        # Simulate the file copying logic from action.yml
        case "$test_file" in
            /tmp/*|./*)
                echo "✅ File is already in accessible location: $test_file"
                accessible_file="$test_file"
                ;;
            *)
                echo "📁 Copying file to accessible location..."
                accessible_file="/tmp/commenter_input_$(basename "$test_file")"
                cp "$test_file" "$accessible_file"
                echo "✅ New accessible location: $accessible_file"
                ;;
        esac
        
        if [ -f "$accessible_file" ]; then
            echo "✅ File is accessible and readable"
            echo "Content preview: $(head -1 "$accessible_file")"
            return 0
        else
            echo "❌ File not accessible after processing"
            return 1
        fi
    else
        echo "❌ Original file not found or not accessible: $test_file"
        return 1
    fi
}

# Test 1: File already in /tmp (should not be copied)
echo ""
echo "Test 1: File already in /tmp"
mkdir -p /tmp/test_outputs
echo "terraform init successful output" > /tmp/test_outputs/init.txt
test_file="/tmp/test_outputs/init.txt"
if test_file_copy_logic "$test_file" "File in /tmp directory"; then
    echo "✅ PASS: /tmp file handled correctly"
else
    echo "❌ FAIL: /tmp file not handled correctly"
fi

# Test 2: Relative path (should not be copied)
echo ""
echo "Test 2: Relative path"
mkdir -p ./test_outputs
echo "terraform plan output" > ./test_outputs/plan.txt
test_file="./test_outputs/plan.txt"
if test_file_copy_logic "$test_file" "Relative path file"; then
    echo "✅ PASS: Relative path handled correctly"
else
    echo "❌ FAIL: Relative path not handled correctly"
fi

# Test 3: Absolute path outside mounted areas (should be copied)
echo ""
echo "Test 3: Absolute path outside mounted areas"
mkdir -p /Users/$(whoami)/test_runner_work/project
echo "terraform validate output from runner" > /Users/$(whoami)/test_runner_work/project/validate.txt
test_file="/Users/$(whoami)/test_runner_work/project/validate.txt"
if test_file_copy_logic "$test_file" "Absolute path outside mounted areas"; then
    echo "✅ PASS: Absolute path copied correctly"
else
    echo "❌ FAIL: Absolute path not copied correctly"
fi

# Test 4: Simulate the exact GitHub Actions scenario
echo ""
echo "Test 4: GitHub Actions runner scenario"
mkdir -p /tmp/github_runner_simulation/work/repo-name/repo-name
echo "
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.75.0

Terraform has been successfully initialized!
" > /tmp/github_runner_simulation/work/repo-name/repo-name/terraform-init-output.txt

test_file="/tmp/github_runner_simulation/work/repo-name/repo-name/terraform-init-output.txt"
if test_file_copy_logic "$test_file" "GitHub Actions runner path simulation"; then
    echo "✅ PASS: GitHub Actions scenario handled correctly"
else
    echo "❌ FAIL: GitHub Actions scenario not handled correctly"
fi

# Test 5: Multiple files with same basename
echo ""
echo "Test 5: Multiple files with same basename"
mkdir -p /Users/$(whoami)/test1 /Users/$(whoami)/test2
echo "first terraform output" > /Users/$(whoami)/test1/output.txt
echo "second terraform output" > /Users/$(whoami)/test2/output.txt

# Test first file
test_file="/Users/$(whoami)/test1/output.txt"
if test_file_copy_logic "$test_file" "First file with common basename"; then
    first_copy="/tmp/commenter_input_output.txt"
    if [ -f "$first_copy" ]; then
        echo "✅ PASS: First file copied successfully"
    fi
fi

# Test second file (should overwrite, which is expected behavior)
test_file="/Users/$(whoami)/test2/output.txt" 
if test_file_copy_logic "$test_file" "Second file with same basename"; then
    second_copy="/tmp/commenter_input_output.txt"
    if [ -f "$second_copy" ] && grep -q "second terraform output" "$second_copy"; then
        echo "✅ PASS: Second file overwrote first (expected behavior)"
    else
        echo "❌ FAIL: Second file did not overwrite correctly"
    fi
fi

# Cleanup
rm -rf /tmp/test_outputs ./test_outputs /Users/$(whoami)/test_runner_work
rm -rf /tmp/github_runner_simulation /Users/$(whoami)/test1 /Users/$(whoami)/test2
rm -f /tmp/commenter_input_*.txt

echo ""
echo "===================================================="
echo "File handling tests completed!"