# TIL: Provider Invalidation Chain Pattern - Complete Reference

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Applies to**: All data-driven state changes (DB recovery, logout, account switch)

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

---

## 실전 패턴

### 패턴 A: DB 복원

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appContainer = ProviderContainer();

  // DB 복원 감지
  final dbService = DbRecoveryService();
  final wasRecovered = await dbService.checkAndRecover();

  if (wasRecovered) {
    // 무효화 체인 시작
    appContainer.invalidate(sqliteLocalDataSourceProvider);
    appContainer.invalidate(statisticsProvider);
    appContainer.invalidate(diaryListProvider);

    // warm-up (optional: critical data)
    try {
      await appContainer.read(statisticsProvider.future).timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      debugPrint('[Main] Statistics warm-up timeout');
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const MindLogApp(),
    ),
  );
}
```

### 패턴 B: 사용자 로그아웃

```dart
// lib/presentation/controllers/auth_controller.dart
class AuthController extends StateNotifier<AuthState> {
  final ProviderContainer _container;

  Future<void> logout() async {
    // 1. 백엔드에서 로그아웃
    await _authRepository.logout();

    // 2. 로컬 캐시 제거
    await _secureStorage.clear();

    // 3. Provider 무효화 (중요!)
    _container.invalidate(authTokenProvider);
    _container.invalidate(currentUserProvider);
    _container.invalidate(sqliteLocalDataSourceProvider);  // 사용자별 DB
    _container.invalidate(statisticsProvider);  // 사용자별 데이터
    _container.invalidate(diaryListProvider);

    // 4. 상태 업데이트
    state = const AuthState.unauthenticated();
  }
}
```

### 패턴 C: 계정 전환

```dart
// lib/presentation/controllers/account_controller.dart
Future<void> switchAccount(String newUserId) async {
  // 데이터소스가 userId를 기반으로 다른 DB 파일 열음
  userIdProvider.state = newUserId;

  // Provider는 여전히 old userId 기반 캐시 유지
  // 따라서 명시적 무효화 필수
  appContainer.invalidate(sqliteLocalDataSourceProvider);
  appContainer.invalidate(diaryListProvider);
  appContainer.invalidate(statisticsProvider);
}
```

---

## 검증: 무효화 체인이 작동하는지 확인

### 체크리스트

```markdown
## 무효화 체인 검증 (체계적)

### 1. ref.watch() 사용 확인
- [ ] Data Source → Repository: watch ✓
- [ ] Repository → UseCase: watch ✓
- [ ] UseCase → Presentation: watch ✓

### 2. invalidate() 호출 확인
- [ ] DataSource invalidate 호출? ✓
- [ ] autoDispose Provider 명시 invalidate? ✓

### 3. 동작 검증 (수동 테스트)
- [ ] DB 변경 → 데이터 새로고침 확인
- [ ] 화면 전환 후 → 데이터 반영됨?
- [ ] Provider DevTools에서 rebuild 감지?

### 4. 디버그 로그
Console에서 다음 순서대로 출력되어야 함:
```
[Invalidation] sqliteLocalDataSourceProvider cleared
[Repository] DiaryRepositoryImpl 새로 생성
[UseCase] GetDiaryUseCase 새로 생성
[Presentation] diaryListProvider 새로 생성
[Widget] DiaryListScreen rebuild 감지
```
```

### 디버그 코드 추가

```dart
// lib/presentation/providers/infra_providers.dart
final sqliteLocalDataSourceProvider = Provider((ref) {
  debugPrint('[DataSource] SqliteLocalDataSource 생성됨');
  return SqliteLocalDataSourceImpl(...);
});

final diaryRepositoryProvider = Provider((ref) {
  debugPrint('[Repository] DiaryRepository 생성됨');
  return DiaryRepositoryImpl(
    ref.watch(sqliteLocalDataSourceProvider),
  );
});

final getDiaryUseCaseProvider = Provider((ref) {
  debugPrint('[UseCase] GetDiaryUseCase 생성됨');
  return GetDiaryUseCase(
    ref.watch(diaryRepositoryProvider),
  );
});

final diaryListProvider = FutureProvider.autoDispose<List<Diary>>((ref) async {
  debugPrint('[Provider] diaryListProvider 구독됨');
  final useCase = ref.watch(getDiaryUseCaseProvider);
  return await useCase.execute();
});
```

**실행 후 콘솔 출력:**
```
[DataSource] SqliteLocalDataSource 생성됨
[Repository] DiaryRepository 생성됨
[UseCase] GetDiaryUseCase 생성됨
[Provider] diaryListProvider 구독됨
```

---

## 문제 해결 가이드

### 문제 1: invalidate했는데 업데이트 안됨

```
의심 순서:
1. ref.watch() 사용 중인가?
   → ref.read()로 변경되어 있나?

2. 구독 중인 Provider가 있나?
   → autoDispose면 명시적 invalidate?

3. 의존성 체인이 끊어졌나?
   → Repository에서 DataSource를 watch?

4. 타이밍 이슈?
   → Provider warm-up 필요?
```

### 문제 2: 일부 화면만 업데이트됨

```
진단:
- Home화면: 업데이트 ✓
- Statistics: 업데이트 ✗

원인: statisticsProvider가 ref.read() 사용
해결: ref.watch()로 변경
```

### 문제 3: 앱 시작 시 데이터 안 보임

```
진단: DB 복원 직후 통계 화면 비어있음

체크:
1. invalidate 호출됨? ✓
2. warm-up 필요? (autoDispose)
3. timeout 발생? (async 작업 중단)

해결:
container.invalidate(sqliteLocalDataSourceProvider);
container.invalidate(statisticsProvider);  // 명시적
await container.read(statisticsProvider.future).timeout(5s);
```

---

## 성능 최적화

### 1. 불필요한 invalidate 피하기

```dart
// ❌ DON'T: 모든 Provider invalidate
void invalidateAll(ProviderContainer container) {
  container.invalidate(authProvider);
  container.invalidate(settingsProvider);
  container.invalidate(themeProvider);
  container.invalidate(notificationProvider);
  container.invalidate(statisticsProvider);  // 관계없는데 invalidate
  // ... 50개 이상
}

// ✅ DO: 영향받는 것만
void invalidateOnDbRecovery(ProviderContainer container) {
  container.invalidate(sqliteLocalDataSourceProvider);
  // 관련된 것들 자동 전파
  // - statisticsProvider
  // - diaryListProvider
  // 관계없는 것들은 유지
  // - authProvider
  // - themeProvider
}
```

### 2. 배치 invalidation

```dart
// ❌ 순차 호출 (느림)
container.invalidate(provider1);
container.invalidate(provider2);
container.invalidate(provider3);

// ✅ 함수로 관리
void invalidateDataLayer(ProviderContainer container) {
  // 한 번에
  container.invalidate(sqliteLocalDataSourceProvider);
}
```

### 3. Selective watch

```dart
// ❌ 모든 Repository watch (불필요)
final myProvider = FutureProvider.autoDispose((ref) async {
  await ref.watch(diaryRepositoryProvider).getDiaries();
  await ref.watch(statisticsRepositoryProvider).getStats();
  await ref.watch(settingsRepositoryProvider).getSettings();
  // 3개 모두 watch = 3개 중 하나 변경되면 전체 재계산
});

// ✅ 필요한 것만 watch
final myProvider = FutureProvider.autoDispose((ref) async {
  return await ref.watch(diaryRepositoryProvider).getDiaries();
  // settings 변경되어도 영향 없음
});
```

---

## 테스트 전략

### 단위 테스트 예제

```dart
group('Provider Invalidation Chain', () {
  test('DataSource invalidation should propagate to UseCase', () async {
    final container = ProviderContainer();

    // Arrange: 초기 로드
    final useCase1 = container.read(getDiaryUseCaseProvider);

    // Act: DataSource invalidate
    container.invalidate(sqliteLocalDataSourceProvider);

    // Assert: UseCase가 재생성됨 (watch 덕분)
    final useCase2 = container.read(getDiaryUseCaseProvider);
    expect(identical(useCase1, useCase2), false);  // 다른 instance
  });

  test('autoDispose Provider should be invalidated explicitly', () async {
    final container = ProviderContainer();

    // Arrange
    await container.read(diaryListProvider.future);

    // Act: DataSource invalidate (자동 전파 안됨)
    container.invalidate(sqliteLocalDataSourceProvider);

    // Assert: 명시적 invalidate 필요
    expect(container.exists(diaryListProvider), true);  // 여전히 캐시됨

    // Fix: 명시적 invalidate
    container.invalidate(diaryListProvider);
    expect(container.exists(diaryListProvider), false);  // 제거됨
  });
});
```

---

## 결론

### 무효화 체인의 3가지 원칙

1. **Bottom-up watch**: 모든 의존성을 watch로 연결
2. **Explicit invalidate at root**: DataSource invalidate로 시작
3. **Handle autoDispose**: 화면에 표시되는 Provider는 명시적 invalidate

### 체크리스트 (모든 새 Provider)

- [ ] 이 Provider는 다른 Provider를 의존하나?
  - [ ] Yes → `ref.watch()` 사용 (read 금지)
  - [ ] No → OK

- [ ] 이 Provider는 autoDispose?
  - [ ] Yes → invalidate 호출 시 명시적으로 invalidate
  - [ ] No → OK (자동 전파)

- [ ] 데이터 소스 변경 지점?
  - [ ] Yes → 모든 관련 Provider invalidate
  - [ ] No → OK

### 다음 개선

- [ ] Provider 의존성 문서 자동화
- [ ] invalidation chain 검증 도구 개발
- [ ] 성능 모니터링 (invalidation 횟수)
