# TIL: Provider Invalidation Chain — Real-World Patterns & Validation

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Split from**: til-provider-invalidation-chain-pattern.md (Part 2/3)

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
