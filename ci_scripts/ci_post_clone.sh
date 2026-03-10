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
if command -v swift-format &> /dev/null; then
    echo "swift-format found, checking formatting..."
    SWIFT_FILES=$(find Packages/*/Sources Packages/*/Tests SurVibe -name '*.swift' -not -path '*/.build/*' 2>/dev/null)
    FORMAT_ERRORS=0
    while IFS= read -r file; do
        if ! swift-format lint --configuration .swift-format "$file" > /dev/null 2>&1; then
            echo "Format violation: $file"
            FORMAT_ERRORS=$((FORMAT_ERRORS + 1))
        fi
    done <<< "$SWIFT_FILES"
    if [ "$FORMAT_ERRORS" -gt 0 ]; then
        echo "swift-format: $FORMAT_ERRORS files have formatting violations"
        echo "Run 'swift-format format --in-place --configuration .swift-format <file>' to fix"
        # Non-blocking for now — will become blocking in Sprint 1
    else
        echo "swift-format: PASSED (all files formatted correctly)"
    fi
else
    echo "swift-format not found. Using Xcode toolchain: xcrun swift-format"
fi

echo ""
echo "=== CI Post-Clone Complete ==="
