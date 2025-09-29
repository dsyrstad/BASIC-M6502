#!/bin/bash

# Script to fix all test files to include FileIOManager parameter

# List of test files that need fixing
files=(
    "test/interpreter/data_read_restore_test.dart"
    "test/interpreter/nested_if_test.dart"
    "test/interpreter/run_test.dart"
    "test/interpreter/gosub_return_test.dart"
    "test/interpreter/list_test.dart"
    "test/interpreter/computed_goto_test.dart"
    "test/interpreter/clear_test.dart"
    "test/interpreter/on_statement_test.dart"
    "test/interpreter/print_formatting_test.dart"
    "test/interpreter/input_test.dart"
    "test/interpreter/file_operations_test.dart"
    "test/interpreter/extended_io_test.dart"
    "test/integration/classic_programs_test.dart"
    "test/runtime/line_editor_test.dart"
    "test/runtime/errors_test.dart"
)

for file in "${files[@]}"; do
    echo "Fixing $file..."

    # Add import if not already present
    if ! grep -q "import '../../lib/io/file_io.dart'" "$file" 2>/dev/null; then
        # Find the last import line and add after it
        sed -i '/import.*\/io\/screen\.dart/a import '"'"'../../lib/io/file_io.dart'"'"';' "$file" 2>/dev/null
    fi

    # Add variable declaration if not already present
    if ! grep -q "late FileIOManager fileIO" "$file" 2>/dev/null; then
        # Add after the last late declaration
        sed -i '/late.*Interpreter interpreter;/i \    late FileIOManager fileIO;' "$file" 2>/dev/null
    fi

    # Add initialization before Interpreter constructor
    if ! grep -q "fileIO = FileIOManager()" "$file" 2>/dev/null; then
        sed -i '/screen = Screen();/a \      fileIO = FileIOManager();' "$file" 2>/dev/null
    fi

    # Add parameter to Interpreter constructor
    if ! grep -q "fileIO," "$file" 2>/dev/null; then
        sed -i '/arrays,$/a \        fileIO,' "$file" 2>/dev/null
    fi
done

echo "All files fixed!"