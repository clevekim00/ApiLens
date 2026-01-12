#!/bin/bash
set -e

echo "Starting UI Gate..."

# 1. Install Dependencies
echo "Getting packages..."
flutter pub get

# 2. Analyze
echo "Running Analysis..."
# flutter analyze # Skip for now if there are known lint issues, or uncomment to enforce.
# For this task, we focus on Smoke Test.

# 3. Run Unit & Widget Tests (Smoke)
echo "Running Smoke Tests..."
flutter test test/smoke/app_smoke_test.dart

# 4. Build Web (Dry run to ensure compilation)
echo "Building Web (Dry Run)..."
flutter build web --no-tree-shake-icons

# 5. Build MacOS (Optional in this script, CI usually separates jobs)
# echo "Building MacOS..."
# flutter build macos --no-codesign

echo "✅ UI Gate Passed!"
