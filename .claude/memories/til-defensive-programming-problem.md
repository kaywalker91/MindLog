# TIL: Defensive Programming — Timing Race Problem & forceReconnect Solution

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Commit**: `feat(v1.4.30): add forceReconnect() defensive programming for timing races`
**Split from**: til-defensive-programming-timing-races.md (Part 1/2)

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
