# /format — Run swift-format on changed or specified files

Check and optionally fix code formatting using Apple's swift-format.

## Steps

1. If the user specified files, use those. Otherwise, find changed files:
   ```
   git diff --name-only --diff-filter=ACM HEAD | grep '\.swift$'
   ```
   If no changed files, check all source files:
   ```
   find Packages/*/Sources Packages/*/Tests SurVibe SurVibeTests -name '*.swift' -not -path '*/.build/*'
   ```

2. For each file, run:
   ```
   xcrun swift-format lint --configuration .swift-format <file>
   ```

3. Report results:
   - Files with formatting issues
   - Files that pass

4. If the user says `/format --fix` or `/format --in-place`, auto-fix all files:
   ```
   xcrun swift-format format --in-place --configuration .swift-format <file>
   ```
   Then verify by re-running lint.

## Notes
- swift-format ships with Xcode toolchain — use `xcrun swift-format`
- Configuration is in `.swift-format` at project root
- 4-space indentation, 120-char line length, ordered imports
