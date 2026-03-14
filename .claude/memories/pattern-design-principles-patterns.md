# Pattern Design Principles — 3 Core Patterns (Feb 2026)

**Session:** app-update-notification-improvement (Feb 2, 2026)
**Split from**: pattern-design-principles.md (Part 1/2)

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
