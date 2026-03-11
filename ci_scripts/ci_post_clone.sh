#!/bin/bash
# ci_post_clone.sh
# Xcode Cloud post-clone script for SurVibe
# Resolves SPM dependencies and enforces code quality gates

set -euo pipefail

echo "=== SurVibe CI Post-Clone Script ==="
echo "Xcode version: $(xcodebuild -version)"
echo "Swift version: $(swift --version)"

# Navigate to project root
cd "$CI_PRIMARY_REPOSITORY_PATH" || cd "$(dirname "$0")/.."

echo ""
echo "=== Resolving SPM Dependencies ==="

# Resolve package dependencies for the main project
echo "Resolving main project dependencies..."
xcodebuild -resolvePackageDependencies -project SurVibe.xcodeproj -scheme SurVibe

echo ""
echo "=== Resolving Local Package Dependencies ==="

# Resolve each local package
for package_dir in Packages/*/; do
    if [ -f "$package_dir/Package.swift" ]; then
        package_name=$(basename "$package_dir")
        echo "Resolving $package_name..."
        (cd "$package_dir" && swift package resolve) || echo "Warning: Failed to resolve $package_name"
    fi
done

echo ""
echo "=== Running SwiftLint Check (Blocking) ==="

# Run SwiftLint — errors will fail the build
if command -v swiftlint &> /dev/null; then
    echo "SwiftLint found, running lint..."
    swiftlint lint --strict --config .swiftlint.yml --reporter xcode
    echo "SwiftLint: PASSED (zero violations)"
else
    echo "SwiftLint not found in PATH. Install via: brew install swiftlint"
    echo "Skipping lint check — install SwiftLint to enforce locally."
fi

echo ""
echo "=== Running swift-format Check ==="

# Check formatting — report violations but don't auto-fix
# Uses xcrun swift-format (Xcode toolchain) with all files in a single invocation for speed.
SWIFT_FORMAT_CMD=""
if command -v xcrun &> /dev/null; then
    SWIFT_FORMAT_CMD="xcrun swift-format"
elif command -v swift-format &> /dev/null; then
    SWIFT_FORMAT_CMD="swift-format"
fi

if [ -n "$SWIFT_FORMAT_CMD" ]; then
    echo "swift-format found ($SWIFT_FORMAT_CMD), checking formatting..."
    SWIFT_FILES=$(find Packages/*/Sources Packages/*/Tests SurVibe -name '*.swift' -not -path '*/.build/*' 2>/dev/null)
    if [ -n "$SWIFT_FILES" ]; then
        # Pass all files in a single invocation instead of looping — much faster
        # shellcheck disable=SC2086
        FORMAT_OUTPUT=$($SWIFT_FORMAT_CMD lint --configuration .swift-format $SWIFT_FILES 2>&1) || true
        if [ -n "$FORMAT_OUTPUT" ]; then
            FORMAT_ERRORS=$(echo "$FORMAT_OUTPUT" | wc -l | tr -d ' ')
            echo "swift-format: $FORMAT_ERRORS formatting violations found"
            echo "$FORMAT_OUTPUT"
            echo "Run 'xcrun swift-format format --in-place --configuration .swift-format <file>' to fix"
            # TODO(Sprint 1): Make swift-format violations blocking (exit 1)
        else
            echo "swift-format: PASSED (all files formatted correctly)"
        fi
    fi
else
    echo "swift-format not found in PATH or Xcode toolchain."
fi

echo ""
echo "=== CI Post-Clone Complete ==="
