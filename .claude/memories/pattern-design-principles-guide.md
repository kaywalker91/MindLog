# Pattern Design Principles — Code Organization, Testing & Guidelines (Feb 2026)

**Session:** app-update-notification-improvement (Feb 2, 2026)
**Split from**: pattern-design-principles.md (Part 2/2)

---

## Code Organization

### DataSource Layer

**책임:** Raw storage/retrieval (no business logic)

**suppress-pattern 예시:**
```dart
// ✅ Raw get/set
Future<String?> getDismissedUpdateVersion() async {
  return prefs.getString(_dismissedUpdateVersionKey);
}

Future<void> setDismissedUpdateVersionWithTimestamp(String version) async {
  await prefs.setString(_dismissedUpdateVersionKey, version);
  await prefs.setInt(_dismissedUpdateTimestampKey, DateTime.now().millisecondsSinceEpoch);
}
```

### Repository Layer

**책임:** Interface definition + error handling

**suppress-pattern 예시:**
```dart
abstract class SettingsRepository {
  Future<String?> getDismissedUpdateVersion();
  Future<void> setDismissedUpdateVersionWithTimestamp(String version);
  // ...
}
```

### State Layer

**책임:** Domain logic (calculations, conditionals)

**suppress-pattern 예시:**
```dart
class UpdateState {
  static const Duration suppressDuration = Duration(hours: 24);

  bool get shouldShowBadge {
    if (dismissedAt == null) return result != null;
    final elapsed = DateTime.now().difference(dismissedAt!);
    return elapsed >= suppressDuration;
  }
}
```

### Notifier Layer

**책임:** State mutations + side effects

**suppress-pattern 예시:**
```dart
class UpdateStateNotifier {
  Future<void> dismiss() async {
    await _settingsRepository.setDismissedUpdateVersionWithTimestamp(version);
    state = state.copyWith(
      dismissedVersion: version,
      dismissedAt: DateTime.now(),
    );
  }
}
```

---

## Testing Strategy

### Unit Tests

**suppress-pattern:**
```dart
// Test 1: Within suppress duration → should be suppressed
// Test 2: After suppress duration → should show
// Test 3: No suppression → should show
// Test 4: Partial suppression (no timestamp) → should show
```

**periodic-timer:**
```dart
// Test 1: start() creates timer
// Test 2: stop() cancels timer
// Test 3: dispose() sets flag and stops
// Test 4: Multiple start() calls don't duplicate
// Test 5: Execution stops after dispose
```

### Widget Tests

**Not required** for these patterns (pure logic)

### Integration Tests

**Consider for:** Actual SharedPreferences read/write + timer execution

---

## Common Gotchas

### 1. Multiple Timer Instances

**문제:** `ref.watch(timerProvider)` in build() 여러 번 호출 → 타이머 중복 생성?

**답:** NO - 같은 timer instance, 추가 start() 호출만 (cancels previous)

```dart
// Safe to call multiple times
ref.watch(timerProvider).start();  // Line 100
ref.watch(timerProvider).start();  // Line 200 - same instance, previous cancelled
```

### 2. Suppress Duration Precision

**문제:** 23시간 59분 후 여전히 suppress 중 (1분 단위 차이)

**답:** 예상된 동작

```dart
DateTime.now().difference(suppressedAt!) < suppressDuration;
// Returns false only when >= suppressDuration (정확히 24h or more)
```

### 3. SharedPreferences Key Conflicts

**문제:** 두 pattern이 같은 키 사용?

**답:** 각 entity마다 고유 키 필요

```dart
// ✅ Good
_dismissedUpdateTimestampKey
_dismissedNotificationTimestampKey
_dismissedTipTimestampKey

// ❌ Bad (conflict)
_dismissedTimestampKey  // Multiple entities use same key
```

---

## When to Create New Pattern

### Criteria

1. **Reusable in 3+ features** (suppress-pattern: update, tips, offers)
2. **Well-defined structure** (Timer + Provider + cleanup)
3. **No existing pattern covers it** (check skill-catalog.md first)
4. **Non-trivial boilerplate** (> 50 lines to implement)

### Examples

- ✅ suppress-pattern (reusable 3+ times)
- ✅ periodic-timer (reusable 3+ times)
- ❌ platform-service (only 1-2 use cases, plugins handle most)
- ❌ single-use pattern (specific to one feature)

---

## Memory Retention

- **Suppress-pattern skill**: Ready to use (`.claude/skills/suppress-pattern.md`)
- **Periodic-timer skill**: Ready to use (`.claude/skills/periodic-timer.md`)
- **Skill catalog**: Updated with 2 new entries
- **Next patterns**: Check for auth flows, caching strategies, validation chains
