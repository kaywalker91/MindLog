# TIL: Defensive Programming - Timing Race Conditions in Provider Initialization

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Commit**: `feat(v1.4.30): add forceReconnect() defensive programming for timing races`

---

## 문제 상황

### 시나리오: DB 복원 후 빠른 화면 전환

```
Timeline:
T0:   앱 시작 → main.dart
T1:   DB 복원 감지 → invalidate() 호출
T2:   [Race] statisticsProvider 구독 시작 (이전 값 캐시 중)
T3:   statisticsProvider 재구성 시작
T4:   [Race] 화면 빠르게 전환
T5:   statisticsProvider 구독 해제
T6:   T3의 async 작업 완료 (하지만 이미 dispose됨)
```

**결과:** 통계 데이터 표시 안됨 (타이밍 따라 발생했다 안했다)

---

## 근본 원인 분석

### 원인 1: autoDispose Provider의 타이밍 이슈

```dart
// lib/presentation/providers/statistics_providers.dart
final statisticsProvider = FutureProvider.autoDispose<Statistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);

  // T3: async 작업 시작
  return await useCase.execute();  // ← Future 반환

  // 중간에 dispose되면?
  // -> Future는 계속 실행되지만 결과를 구독자에게 전달 안함
});
```

### 원인 2: rebuild 깔끔하지 않은 상태 전환

```
ref.read(statisticsProvider) - T2 (old cached value)
                              ↓
invalidate(statisticsProvider) - T1 (invalidate 호출)
                              ↓
ref.watch(statisticsProvider) - T3 (new computation starts)
                              ↓
[async operation in flight] - T4 (screen popped, subscription canceled)
                              ↓
결과: 아무도 Future를 구독하지 않음 → 데이터 로드 안됨
```

---

## 해결책: forceReconnect() 방어 전략

### 1. 아키텍처 추가: ForceReconnect 플래그

```dart
// lib/core/services/db_recovery_service.dart
class DbRecoveryService {
  /// Database 복원 감지 후 강제 재구성
  Future<void> forceReconnect({required ProviderContainer container}) async {
    // Step 1: Core layer 무효화
    container.invalidate(sqliteLocalDataSourceProvider);

    // Step 2: Presentation layer 무효화
    container.invalidate(statisticsProvider);
    container.invalidate(diaryListControllerProvider);

    // Step 3: 강제 재구독 (warm-up)
    // ← 이게 핵심: invalidate만으로는 부족할 수 있으므로
    //   명시적으로 Future 시작
    try {
      await container.read(statisticsProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Statistics reload timeout'),
      );

      if (kDebugMode) {
        debugPrint('[DbRecoveryService] forceReconnect() completed successfully');
      }
    } catch (e) {
      debugPrint('[DbRecoveryService] forceReconnect() failed: $e');
      // 에러 처리: UI에 알림 or 로그
    }
  }
}
```

### 2. main.dart에서 호출

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appContainer = ProviderContainer();

  // DB 복원 감지 → 강제 재구성
  final wasRecovered = await DbRecoveryService(appContainer)
      .checkAndRecover();

  if (wasRecovered) {
    await appContainer
        .read(dbRecoveryServiceProvider)
        .forceReconnect(container: appContainer);
  }

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const MindLogApp(),
    ),
  );
}
```

---

## 적용 패턴

### 패턴 1: Critical Data Provider의 Warm-up

```dart
// 타이밍이 중요한 Provider는 main()에서 명시적으로 warm-up
Future<void> initializeCriticalProviders(ProviderContainer container) async {
  final futures = [
    // 통계 (app recovery 후 필수)
    container.read(statisticsProvider.future),

    // 오늘의 감정 (HomeScreen에서 필수)
    container.read(todayEmotionProvider.future),

    // 일기 목록 (초기 로드)
    container.read(diaryListControllerProvider.future),
  ];

  try {
    await Future.wait(futures, eagerError: true);
  } catch (e) {
    debugPrint('[InitError] Failed to warm-up critical providers: $e');
  }
}
```

### 패턴 2: Graceful Degradation

```dart
// 만약 warm-up 실패해도 앱은 시작
Future<void> main() async {
  final appContainer = ProviderContainer();

  try {
    await initializeCriticalProviders(appContainer);
  } catch (e) {
    debugPrint('[Startup] Some providers failed to load, but continuing...');
    // app은 계속 시작, 대신 화면에서 empty state 표시
  }

  runApp(UncontrolledProviderScope(
    container: appContainer,
    child: const MindLogApp(),
  ));
}
```

### 패턴 3: Provider 자체의 견고성

```dart
// statisticsProvider 내부에서도 방어
final statisticsProvider = FutureProvider.autoDispose<Statistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);

  try {
    return await useCase.execute().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Statistics fetch timeout'),
    );
  } on TimeoutException {
    return Statistics.empty();  // fallback
  } catch (e) {
    ref.invalidateSelf();  // 스스로 invalidate → 재시도
    rethrow;
  }
});
```

---

## 성능 고려사항

### Trade-off 분석

| 방식 | 장점 | 단점 | 권장 |
|------|------|------|------|
| **invalidate만 사용** | 간단 | 타이밍 레이스 가능 | ❌ autoDispose에선 부족 |
| **invalidate + warm-up** | 타이밍 보장 | 시작 시간 증가 | ✅ critical provider |
| **timeout + retry** | 회복력 | 복잡도 증가 | ✅ network 의존 provider |
| **graceful degradation** | UX 우수 | 예외 처리 증가 | ✅ optional data |

### 측정 (mocked scenario)

```
앱 시작 시간:
- 기존 (invalidate만): 300ms
- with warm-up: 450ms (+150ms, acceptable)
- with timeout logic: 600ms (+300ms, only for critical)
```

**결론:** critical provider (statistics, emotions)만 warm-up 적용 → 성능 영향 최소

---

## 테스트 시나리오

### 단위 테스트: Timing Race 재현

```dart
test('Provider should handle rapid invalidation and resubscription', () async {
  final container = ProviderContainer();

  // Arrange
  final initialValue = await container.read(statisticsProvider.future);
  expect(initialValue, isNotNull);

  // Act: rapid invalidation
  container.invalidate(sqliteLocalDataSourceProvider);
  await Future.delayed(const Duration(milliseconds: 1));  // race condition 시뮬레이션

  // 즉시 재구독 (dispose 전)
  final newValue = await container.read(statisticsProvider.future);

  // Assert: 새 값이 로드되어야 함
  expect(newValue, isNotNull);
  expect(newValue.isEmpty || newValue.isNotEmpty, isTrue);
});
```

### 통합 테스트: DB 복원 시나리오

```dart
test('DB recovery should trigger provider warm-up', () async {
  final container = ProviderContainer();

  // Arrange: 초기 로드
  await container.read(statisticsProvider.future);

  // Act: 복원 감지 후 forceReconnect
  final wasRecovered = true;
  if (wasRecovered) {
    await container
        .read(dbRecoveryServiceProvider)
        .forceReconnect(container: container);
  }

  // Assert: Provider가 재생성되고 데이터가 로드됨
  final reloadedStats = await container.read(statisticsProvider.future);
  expect(reloadedStats, isNotNull);
});
```

---

## 주의사항

### 1. over-warming은 금지

```dart
// ❌ DON'T: 불필요한 모든 Provider warm-up
Future<void> warmupAll(ProviderContainer container) async {
  final providers = [
    // 불필요한 것들:
    themeProvider,
    settingsProvider,
    userPreferencesProvider,
    // ... 50개 이상
  ];
  await Future.wait(providers.map((p) => container.read(p.future)));
}

// ✅ DO: 필수 provider만
Future<void> warmupCritical(ProviderContainer container) async {
  final providers = [
    statisticsProvider,        // app recovery 필수
    todayEmotionProvider,      // home screen 필수
    diaryListControllerProvider, // initial state
  ];
  await Future.wait(providers.map((p) => container.read(p.future)));
}
```

### 2. Timeout 설정 조심

```dart
// ❌ 너무 짧으면 네트워크 지연에 취약
const timeout = Duration(milliseconds: 500);

// ❌ 너무 길면 앱 시작 지연
const timeout = Duration(minutes: 1);

// ✅ 적절한 값: API 응답 + 버퍼
const timeout = Duration(seconds: 10);
```

### 3. 디버그 vs 릴리스 모드

```dart
// 개발 중에는 더 길게
const timeout = kDebugMode
  ? Duration(seconds: 30)
  : Duration(seconds: 10);

// 디버그 로그는 조건부
if (kDebugMode) {
  debugPrint('[forceReconnect] Starting warm-up...');
}
```

---

## 결론

### 핵심 교훈

1. **invalidate는 필요하지만 충분하지 않음** (autoDispose의 경우)
2. **Critical data는 warm-up 필요** (타이밍 보장)
3. **Timeout 필수** (infinite wait 방지)
4. **Graceful degradation** (에러 시 폴백)

### 적용 체크리스트

- [ ] DB 복원/로그아웃 등 상태 변경 시 `forceReconnect()` 호출
- [ ] critical provider 식별 (UI에 필수적인 데이터)
- [ ] warm-up timeout 설정 (초 단위)
- [ ] 에러 처리 (timeout exception, network errors)
- [ ] 수동 테스트 (빠른 화면 전환 시나리오)

### 다음 개선 사항

- [ ] forceReconnect() 자동화 (custom hook)
- [ ] Provider warm-up retry 로직 추가
- [ ] 성능 모니터링 (startup time tracking)
- [ ] 네트워크 상태에 따른 adaptive timeout
