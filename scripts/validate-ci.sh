#!/bin/bash

# NotchUtility CI Validation Script
# Run this script locally to ensure your changes will pass the CI pipeline
# Usage: ./validate-ci.sh [-ui]
#   -ui: Include UI tests in validation (optional)

set -e

# Parse command line arguments
RUN_UI_TESTS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -ui)
            RUN_UI_TESTS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-ui]"
            echo "  -ui: Include UI tests in validation (optional)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-ui]"
            exit 1
            ;;
    esac
done

echo "🚀 NotchUtility CI Validation"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "NotchUtility.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the NotchUtility project root directory"
    exit 1
fi

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "⚠️  SwiftLint not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install swiftlint
    else
        echo "❌ Error: Homebrew not found. Please install SwiftLint manually:"
        echo "   https://github.com/realm/SwiftLint#installation"
        exit 1
    fi
fi

echo ""
echo "🔍 Step 1: Running SwiftLint (treating warnings as errors)..."
echo "------------------------------------------------------------"
if swiftlint lint --strict; then
    echo "✅ SwiftLint passed with no warnings!"
else
    echo "❌ SwiftLint failed. Please fix all warnings and errors above."
    exit 1
fi

echo ""
echo "🏗️  Step 2: Building project (treating warnings as errors)..."
echo "------------------------------------------------------------"
if xcodebuild clean build \
    -project NotchUtility.xcodeproj \
    -scheme NotchUtility \
    -destination 'platform=macOS,arch=arm64' \
    ONLY_ACTIVE_ARCH=NO \
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
    -quiet; then
    echo "✅ Build succeeded with no warnings!"
else
    echo "❌ Build failed. Please fix all build warnings and errors."
    exit 1
fi

echo ""
echo "🧪 Step 3: Running unit tests (treating warnings as errors)..."
echo "-------------------------------------------------------------"
if xcodebuild test \
    -project NotchUtility.xcodeproj \
    -scheme NotchUtility \
    -destination 'platform=macOS,arch=arm64' \
    -only-testing:NotchUtilityTests \
    ONLY_ACTIVE_ARCH=NO \
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
    -quiet; then
    echo "✅ All unit tests passed with no warnings!"
else
    echo "❌ Unit tests failed. Please fix all test failures and build warnings."
    exit 1
fi

echo ""
echo "🖥️  Step 4: UI Tests..."
echo "----------------------"
if [ "$RUN_UI_TESTS" = true ]; then
    echo "Running UI tests (treating warnings as errors)..."
    if xcodebuild test \
        -project NotchUtility.xcodeproj \
        -scheme NotchUtility \
        -destination 'platform=macOS,arch=arm64' \
        -only-testing:NotchUtilityUITests \
        ONLY_ACTIVE_ARCH=NO \
        SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
        -quiet; then
        echo "✅ All UI tests passed with no warnings!"
    else
        echo "❌ UI tests failed. Please fix all test failures and build warnings."
        exit 1
    fi
else
    echo "⏭️  Skipping UI tests (use -ui flag to include them)"
fi

echo ""
echo "🎉 All validation checks passed!"
echo "Your changes are ready for CI pipeline."
echo ""
echo "💡 Next steps:"
echo "   1. Commit your changes: git add . && git commit -m 'Your message'"
echo "   2. Push to your branch: git push origin your-branch-name"
echo "   3. Create a pull request" 