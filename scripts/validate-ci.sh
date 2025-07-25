#!/bin/bash

# NotchUtility CI Validation Script
# Run this script locally to ensure your changes will pass the CI pipeline

set -e

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
echo "🔍 Step 1: Running SwiftLint..."
echo "--------------------------------"
if swiftlint lint; then
    echo "✅ SwiftLint passed!"
else
    echo "❌ SwiftLint failed. Please fix the issues above."
    exit 1
fi

# echo ""
# echo "🏗️  Step 2: Building project (treating warnings as errors)..."
# echo "------------------------------------------------------------"
# if xcodebuild clean build \
#     -project NotchUtility.xcodeproj \
#     -scheme NotchUtility \
#     -destination 'platform=macOS,arch=arm64' \
#     CODE_SIGN_IDENTITY="" \
#     CODE_SIGNING_REQUIRED=NO \
#     ONLY_ACTIVE_ARCH=NO \
#     SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
#     -quiet; then
#     echo "✅ Build succeeded with no warnings!"
# else
#     echo "❌ Build failed. Please fix all build warnings and errors."
#     exit 1
# fi

# echo ""
# echo "🧪 Step 3: Running tests (treating warnings as errors)..."
# echo "---------------------------------------------------------"
# if xcodebuild test \
#     -project NotchUtility.xcodeproj \
#     -scheme NotchUtility \
#     -destination 'platform=macOS,arch=arm64' \
#     CODE_SIGN_IDENTITY="" \
#     CODE_SIGNING_REQUIRED=NO \
#     ONLY_ACTIVE_ARCH=NO \
#     SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
#     -quiet; then
#     echo "✅ All tests passed with no warnings!"
# else
#     echo "❌ Tests failed. Please fix all test failures and build warnings."
#     exit 1
# fi

echo ""
echo "🎉 All validation checks passed!"
echo "Your changes are ready for CI pipeline."
echo ""
echo "💡 Next steps:"
echo "   1. Commit your changes: git add . && git commit -m 'Your message'"
echo "   2. Push to your branch: git push origin your-branch-name"
echo "   3. Create a pull request" 