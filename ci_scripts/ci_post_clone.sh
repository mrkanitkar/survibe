#!/bin/bash
# ci_post_clone.sh
# Xcode Cloud post-clone script for SurVibe
# Resolves all Swift Package Manager dependencies

set -e

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
echo "=== Running SwiftLint Check ==="

# Run SwiftLint if available (installed via SPM plugin, but fallback to brew)
if command -v swiftlint &> /dev/null; then
    echo "SwiftLint found, running lint..."
    swiftlint lint --config .swiftlint.yml --reporter xcode || echo "SwiftLint warnings found (non-blocking)"
else
    echo "SwiftLint not found in PATH. SPM Build Tool Plugin will handle linting during build."
fi

echo ""
echo "=== CI Post-Clone Complete ==="
