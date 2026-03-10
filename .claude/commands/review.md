# /review — Architecture review against SurVibe best practices

Review code changes against the project's architecture rules and Apple best practices.

## Steps

1. Find what changed:
   ```
   git diff --name-only HEAD
   ```
   If no unstaged changes, check staged:
   ```
   git diff --cached --name-only
   ```
   If the user specified files or a PR, review those instead.

2. For each changed `.swift` file, read it and check against these rules:

### Concurrency (CRITICAL)
- [ ] No `@unchecked Sendable` — must use `@MainActor` or value types
- [ ] No `DispatchQueue.main.async` — must use `@MainActor`
- [ ] Managers/singletons are `@MainActor`
- [ ] Pure computation is `nonisolated static`
- [ ] Closures crossing isolation boundaries are `@Sendable`
- [ ] NotificationCenter closures extract Sendable values before `Task { @MainActor in }`

### Architecture
- [ ] No `ObservableObject`/`@Published` — must use `@Observable`
- [ ] No `VersionedSchema` — manual schema versioning only
- [ ] No circular package dependencies
- [ ] No direct PostHog imports outside SVCore
- [ ] New files in the correct package

### Data Model
- [ ] `@Model` fields have defaults or are optional
- [ ] Completion flags are one-way (`private(set)` + guard)
- [ ] XP/scores use additive patterns

### Audio
- [ ] Single AVAudioEngine via `AudioEngineManager.shared`
- [ ] `AVAudioPCMBuffer` with `.loops` for looping (not recursive scheduleFile)
- [ ] SwarUtility for note conversion (not duplicated arrays)

### Quality
- [ ] Public types/methods have `///` documentation
- [ ] Interactive elements have `.accessibilityLabel()`
- [ ] Tests exist for new public types

3. Report findings organized by severity: CRITICAL, HIGH, MEDIUM, LOW
4. Suggest specific fixes for each finding

## Output format
```
## Review: <file list>

### CRITICAL
- [file:line] Issue description → Fix suggestion

### HIGH
- ...

### Summary
X files reviewed, Y issues found (Z critical)
```
