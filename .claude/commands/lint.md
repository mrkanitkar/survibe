# /lint — Run SwiftLint on changed or specified files

Run SwiftLint on the project to check for violations.

## Steps

1. Run `/opt/homebrew/bin/swiftlint lint --quiet --config .swiftlint.yml 2>&1 | grep -v '\.build/' | grep -v 'DerivedData'` from the project root
2. If the user specified files, run SwiftLint on those specific files instead
3. Parse the output:
   - Count errors vs warnings
   - Group violations by file
   - For each error, read the file and suggest a fix
4. If there are zero violations, report "SwiftLint: PASSED — zero violations"
5. If there are errors, list them with suggested fixes
6. If there are only warnings, list them but note they won't block commits

## Auto-fix option

If the user says `/lint --fix`, run:
```
/opt/homebrew/bin/swiftlint lint --fix --config .swiftlint.yml
```
Then re-run lint to show remaining issues that couldn't be auto-fixed.
