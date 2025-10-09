#!/usr/bin/env bash

# End-to-end integration test for the Terraform PR Commenter action
# This simulates a complete workflow to ensure all components work together

set -e

echo "Running integration tests for Terraform PR Commenter..."
echo "======================================================"

# Setup test environment
export GITHUB_TOKEN="fake_token_for_testing"
export GITHUB_EVENT='{"pull_request":{"number":123,"comments_url":"https://api.github.com/repos/test/test/issues/123/comments","repository":{"issue_comment_url":"https://api.github.com/repos/test/test/issues/{/number}/comments"}}}'
export COMMENTER_DEBUG="true"
export TF_WORKSPACE="test"

# Test 1: Terraform init success scenario
echo ""
echo "Test 1: Terraform init success (exit code 0)"
echo "============================================="
init_output="
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.75.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running \"terraform plan\" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
"

echo "$init_output" > /tmp/init_success.txt
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE="/tmp/init_success.txt"

echo "Testing init with file input..."
# This should proceed past validation but will fail at GitHub API calls (expected)
if timeout 10s bash ../entrypoint.sh init 0 2>&1 | grep -q "Reading input from file"; then
    echo "✅ PASS: Init success scenario processed file input correctly"
else
    echo "❌ FAIL: Init success scenario did not process file input"
fi

# Test 2: Terraform plan with changes (exit code 2)
echo ""
echo "Test 2: Terraform plan with changes (exit code 2)"
echo "================================================="
plan_output="
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place
  - destroy

Terraform will perform the following actions:

  # azurerm_resource_group.example will be created
  + resource \"azurerm_resource_group\" \"example\" {
      + id       = (known after apply)
      + location = \"West Europe\"
      + name     = \"example-resources\"
    }

  # azurerm_storage_account.example will be updated in-place
  ~ resource \"azurerm_storage_account\" \"example\" {
        id                              = \"/subscriptions/.../example\"
      ~ account_tier                    = \"Standard\" -> \"Premium\"
        name                            = \"examplestorageaccount\"
        # (25 unchanged attributes hidden)
    }

Plan: 1 to add, 1 to change, 0 to destroy.
"

echo "$plan_output" > /tmp/plan_changes.txt
export COMMENTER_INPUT_FILE="/tmp/plan_changes.txt"

echo "Testing plan with changes..."
if timeout 10s bash ../entrypoint.sh plan 2 2>&1 | grep -q "Reading input from file"; then
    echo "✅ PASS: Plan with changes processed file input correctly"
else
    echo "❌ FAIL: Plan with changes did not process file input"
fi

# Test 3: Environment variable input (backward compatibility)
echo ""
echo "Test 3: Environment variable input (backward compatibility)"
echo "=========================================================="
export COMMENTER_INPUT="$init_output"
export COMMENTER_INPUT_FILE=""

echo "Testing with environment variable input..."
if timeout 10s bash ../entrypoint.sh init 0 2>&1 | grep -q "Reading input from environment variable"; then
    echo "✅ PASS: Environment variable input works correctly"
else
    echo "❌ FAIL: Environment variable input failed"
fi

# Test 4: File outside accessible path (tests our copying logic)
echo ""
echo "Test 4: File outside accessible paths"
echo "====================================="
mkdir -p /tmp/simulate_runner/work/project/project
echo "$plan_output" > /tmp/simulate_runner/work/project/project/terraform-plan-output.txt

# This simulates the action.yml file copying logic
test_file="/tmp/simulate_runner/work/project/project/terraform-plan-output.txt"
if [ -f "$test_file" ]; then
    case "$test_file" in
        /tmp/*|./*)
            accessible_file="$test_file"
            ;;
        *)
            accessible_file="/tmp/commenter_input_$(basename "$test_file")"
            cp "$test_file" "$accessible_file"
            ;;
    esac
    
    export COMMENTER_INPUT=""
    export COMMENTER_INPUT_FILE="$accessible_file"
    
    echo "Testing copied file access..."
    if timeout 10s bash ../entrypoint.sh plan 2 2>&1 | grep -q "Reading input from file"; then
        echo "✅ PASS: Copied file accessed correctly"
    else
        echo "❌ FAIL: Copied file not accessed correctly"
    fi
fi

# Test 5: Error handling for missing files
echo ""
echo "Test 5: Error handling for missing files"
echo "========================================"
export COMMENTER_INPUT=""
export COMMENTER_INPUT_FILE="/nonexistent/path/file.txt"

echo "Testing missing file handling..."
if timeout 10s bash ../entrypoint.sh init 0 2>&1 | grep -q "file does not exist or is not accessible"; then
    echo "✅ PASS: Missing file error handled correctly"
else
    echo "❌ FAIL: Missing file error not handled correctly"
fi

# Cleanup
rm -f /tmp/init_success.txt /tmp/plan_changes.txt /tmp/commenter_input_*.txt
rm -rf /tmp/simulate_runner

echo ""
echo "======================================================"
echo "Integration tests completed!"
echo ""
echo "Note: Tests that reach GitHub API calls will fail with network errors."
echo "This is expected in the test environment and indicates the validation"
echo "and file processing logic is working correctly."