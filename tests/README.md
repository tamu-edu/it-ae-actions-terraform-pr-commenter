# Test Suite for Terraform PR Commenter

This directory contains test scripts to validate the functionality of the Terraform PR Commenter GitHub Action, with comprehensive coverage of file handling, input validation, and integration scenarios.

## Test Files

### `test_validation.sh`
Tests the input validation logic in `entrypoint.sh`, including:
- Missing input detection
- Non-existent file handling
- Environment variable vs. file input validation
- Empty content detection
- Improved error messages for Docker accessibility

### `test_file_handling.sh`
Tests the file path handling and copying logic from `action.yml`, including:
- Files already in accessible locations (`/tmp`, relative paths)
- Files requiring copying to accessible locations
- GitHub Actions runner path simulation
- Multiple files with same basename handling

### `test_integration.sh`
End-to-end integration tests that simulate complete workflows:
- Terraform init success scenarios
- Terraform plan with changes
- Backward compatibility with environment variables
- File copying from inaccessible paths
- Error handling validation

## Running the Tests

Make the test scripts executable and run them from the `tests` directory:

```bash
cd tests
chmod +x *.sh

# Run individual tests
./test_validation.sh
./test_file_handling.sh
./test_integration.sh

# Or run all tests
for test in test_*.sh; do
    echo "Running $test..."
    ./"$test"
    echo "---"
done
```

## Context

These tests validate the robust file handling capabilities of the GitHub Action, ensuring that users can specify file paths anywhere on the filesystem and the action will automatically handle accessibility within its Docker container environment.

## Fixes Tested

1. **Improved validation logic** in `entrypoint.sh`:
   - Better error messages explaining Docker accessibility constraints
   - Separate validation for file existence vs. content availability

2. **Automatic file copying** in `action.yml`:
   - Files outside `/tmp` and relative paths are automatically copied to accessible locations
   - Ensures backward compatibility while fixing accessibility issues

3. **Enhanced documentation** in `README.md`:
   - Clear explanation of file path constraints
   - Best practices for file-based inputs

## Expected Test Outcomes

- **Validation tests**: Should pass all checks for proper error detection and messaging
- **File handling tests**: Should demonstrate successful copying and accessibility
- **Integration tests**: Should process inputs correctly (may fail at GitHub API calls in test environment, which is expected)

## Contributing

When modifying the action's file handling or validation logic, please:
1. Update relevant test scripts
2. Add new test cases for new functionality
3. Ensure all tests pass before submitting changes
4. Update this README if adding new test files