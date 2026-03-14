# TIL: Provider Invalidation Chain — Core Patterns

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Applies to**: All data-driven state changes (DB recovery, logout, account switch)
**Split from**: til-provider-invalidation-chain-pattern.md (Part 1/3)

---

## 문제: 부분적 무효화 (Partial Invalidation)

### 정의

```
데이터 소스가 변경되었을 때 (DB 복원, 네트워크 새 데이터)
관련된 모든 Provider를 무효화해야 하는데
일부만 무효화되는 현상
```

### 발생 원인

| 원인 | 영향 | 예시 |
|------|------|------|
| `ref.read()` 사용 | 의존성 미추적 | usecase → repository 참조 |
| autoDispose Provider | 메모리는 유지 | statistics provider 캐시 유지 |
| 명시적 무효화 누락 | 수동으로 호출 필요 | presentation layer 무효화 |
| Provider 간 순환 의존 | 무효화 체인 중단 | A→B→C→A (순환) |

---

## 솔루션: 체계적인 무효화 체인

### 1단계: Provider 계층 분류

```dart
// lib/presentation/providers/providers.dart

// === LAYER 1: DATA SOURCE ===
// 역할: DB 또는 API 접근
// 특성: 가장 하위 계층, 변경 감지 포인트
final sqliteLocalDataSourceProvider = Provider((ref) {
  return SqliteLocalDataSourceImpl(...);
});

// === LAYER 2: REPOSITORY ===
// 역할: 비즈니스 로직 적용
// 특성: DataSource를 watch (의존성 추적)
final diaryRepositoryProvider = Provider((ref) {
  return DiaryRepositoryImpl(
    ref.watch(sqliteLocalDataSourceProvider), // ✅ watch
  );
});

final statisticsRepositoryProvider = Provider((ref) {
  return StatisticsRepositoryImpl(
    ref.watch(sqliteLocalDataSourceProvider), // ✅ watch
  );
});

// === LAYER 3: USE CASE ===
// 역할: Repository를 조합
// 특성: Repository를 watch (의존성 추적)
final getDiaryUseCaseProvider = Provider((ref) {
  return GetDiaryUseCase(
    ref.watch(diaryRepositoryProvider), // ✅ watch
  );
});

final getStatisticsUseCaseProvider = Provider((ref) {
  return GetStatisticsUseCase(
    ref.watch(statisticsRepositoryProvider), // ✅ watch
  );
});

// === LAYER 4: PRESENTATION (FutureProvider) ===
// 역할: 화면 데이터 제공
// 특성: UseCase를 watch + autoDispose
final diaryListProvider = FutureProvider.autoDispose<List<Diary>>((ref) async {
  final useCase = ref.watch(getDiaryUseCaseProvider);
  return await useCase.execute();
});

final statisticsProvider = FutureProvider.autoDispose<Statistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return await useCase.execute();
});

// === LAYER 5: UI (StateNotifierProvider) ===
// 역할: 화면 상태 관리
// 특성: FutureProvider를 의존하거나 UseCase 직접 호출
final diaryListControllerProvider = StateNotifierProvider<
  DiaryListController,
  List<Diary>,
>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return DiaryListController(repo);
});
```

### 2단계: 의존성 체인 시각화

```
[DATA LAYER]
sqliteLocalDataSourceProvider (watch)
  ↑
  ├─→ diaryRepositoryProvider (watch)
  │     ↑
  │     ├─→ getDiaryUseCaseProvider (watch)
  │     │     ↑
  │     │     └─→ diaryListProvider (watch) ← autoDispose
  │     │           ↑
  │     │           └─→ DiaryListScreen (builds)
  │     │
  │     └─→ diaryListControllerProvider (watch)
  │           ↑
  │           └─→ DiaryListScreen (builds)
  │
  └─→ statisticsRepositoryProvider (watch)
        ↑
        └─→ getStatisticsUseCaseProvider (watch)
              ↑
              └─→ statisticsProvider (watch) ← autoDispose
                    ↑
                    └─→ StatisticsScreen (builds)
```

### 3단계: 무효화 시작점

```dart
// lib/core/services/db_recovery_service.dart
Future<void> invalidateAll(ProviderContainer container) async {
  // STEP 1: 최하위 계층 무효화 (발진점)
  // 이것이 모든 위쪽 계층에 자동 전파됨
  container.invalidate(sqliteLocalDataSourceProvider);

  // STEP 2: 명시적 무효화 (autoDispose 대비)
  // autoDispose Provider는 구독 중이면 dispose 안되므로
  // 명시적으로 invalidate
  container.invalidate(statisticsProvider);
  container.invalidate(diaryListProvider);

  // STEP 3: 검증 (optional, 디버그 모드)
  if (kDebugMode) {
    debugPrint('[Invalidation] sqliteLocalDataSourceProvider cleared');
    debugPrint('[Invalidation] statisticsProvider cleared');
    debugPrint('[Invalidation] diaryListProvider cleared');
  }
}
```
