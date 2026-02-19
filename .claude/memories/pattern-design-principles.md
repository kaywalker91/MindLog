# Pattern Design Principles (Feb 2026)

## Session Context

**Session:** app-update-notification-improvement (Feb 2, 2026)

Session에서 3가지 재사용 가능한 패턴이 발견되었고, 2개를 스킬로 정의함.

---

## Pattern 1: Timestamp-based Suppression

**패턴:** 특정 이벤트(dismiss) 시점의 시간을 저장 → 현재 시간과의 차이로 경과 시간 계산 → 임계값 초과 시 재표시

**사용 사례:**
- ✅ Update notification (24h suppress)
- ✅ Help dialog tips (7d suppress)
- ✅ Resubscribe offers (30d suppress)
- ✅ Alert snooze (1h suppress)
- ✅ Marketing popups (never show again + time window)

**핵심 코드:**
```dart
// Store
await prefs.setInt(_suppressedAtKey, DateTime.now().millisecondsSinceEpoch);

// Retrieve
final timestamp = prefs.getInt(_suppressedAtKey);
final suppressedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

// Check
bool get isSuppressed {
  if (suppressedAt == null) return false;
  final elapsed = DateTime.now().difference(suppressedAt!);
  return elapsed < suppressDuration;
}
```

**재사용도:** ⭐⭐⭐⭐⭐ (매우 높음)

**스킬 정의:** `/suppress-pattern [entity] [duration]`

**라인 수:** 250-350줄 (구현 + 예시 + 테스트)

---

## Pattern 2: Periodic Timer with Cleanup

**패턴:** `Timer.periodic` + `Provider.autoDispose` + `ref.onDispose` 조합으로 주기적 작업 실행 및 리소스 정리

**사용 사례:**
- ✅ Update check polling (6h interval)
- ✅ Data sync (5m interval)
- ✅ Network status check (30s interval)
- ✅ Cache cleanup (daily)
- ✅ Analytics batch upload (1h interval)

**핵심 패턴:**
```dart
// Provider setup
final periodicTimerProvider = Provider.autoDispose<PeriodicTimer>((ref) {
  final timer = PeriodicTimer(ref);
  ref.onDispose(() => timer.dispose());  // Auto-cleanup
  return timer;
});

// Lifecycle
void start() {
  _timer = Timer.periodic(_interval, (_) => _perform());
}

void dispose() {
  _isDisposed = true;
  _timer?.cancel();
}

// Safety check
Future<void> _perform() async {
  if (_isDisposed) return;  // Prevent post-dispose execution
  // ...
}
```

**재사용도:** ⭐⭐⭐⭐ (높음)

**스킬 정의:** `/periodic-timer [name] [interval]`

**라인 수:** 200-300줄 (구현 + 예시 + 테스트)

**주의:** `MainScreen.build()`에서 직접 호출 필요
```dart
ref.watch(periodicTimerProvider).start();
```

---

## Pattern 3: Platform-specific Service Wrapper

**패턴:** `Platform.isAndroid` 체크로 플랫폼별 구현 분기

**사용 사례:**
- ✅ In-App Update (Android only)
- ⚠️ Biometric auth (각 플랫폼 다른 API)
- ⚠️ Firebase Dynamic Links (처리 방식 다름)

**현재 코드 문제:**
```dart
// ❌ 문제: 3곳에서 Platform 체크
if (!Platform.isAndroid) return null;  // Service
if (!Platform.isAndroid) { ... }  // Provider
if (Platform.isAndroid) { ... }  // UI
```

**개선안:**
```dart
// ✅ 해결: Service에만 집중화
class InAppUpdateService {
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;  // Only here
    return await InAppUpdate.checkForUpdate();
  }
}

// Provider/UI에서는 null 체크만
if (info == null) { /* not available */ }
```

**재사용도:** ⭐⭐⭐ (중간, Android-only가 대부분)

**스킬화 우선순위:** P3 (낮음, 현재 재사용 사례 1개)

---

## Key Design Principles

### 1. Centralize Responsibility

**원칙:** 같은 관심사는 한 곳에만

**❌ 나쁜 예:**
```dart
// Platform check in 3 places (Service + Provider + UI)
// Timestamp storage in 2 places (DataSource + State)
```

**✅ 좋은 예:**
```dart
// Service: Platform check only
// Provider: null handling only
// UI: null state display only
```

### 2. Resource Cleanup Guarantee

**원칙:** `Provider.autoDispose` + `ref.onDispose` 필수

**패턴:**
```dart
final timerProvider = Provider.autoDispose<Timer>((ref) {
  final timer = Timer(...);
  ref.onDispose(() => timer.dispose());  // Guarantees cleanup
  return timer;
});
```

**이점:**
- App background 시 자동 정리
- 수동 cleanup 불필요
- 메모리 누수 방지

### 3. Immutability with Versioning

**원칙:** State는 불변이지만, 제약은 필요하면 버전으로 관리

**예시:**
```dart
// ✅ suppress-pattern에서 사용
suppressDuration = Duration(hours: 24);  // 재사용 시 변경 가능

// ✅ periodic-timer에서 사용
const Duration _interval = Duration(hours: 6);  // 변경 필요 시 상수 수정
```

### 4. Safety Flags in Async Context

**원칙:** 비동기 작업 후 disposed 상태 확인

**패턴:**
```dart
Future<void> _perform() async {
  if (_isDisposed) return;  // Check before long async operation

  await expensiveAsyncOperation();

  if (_isDisposed) return;  // Check after completion
}
```

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

