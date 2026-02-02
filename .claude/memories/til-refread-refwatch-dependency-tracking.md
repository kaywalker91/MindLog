# TIL: Riverpod ref.read() vs ref.watch() 의존성 추적

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Commits**:
- `feat(v1.4.30): statistics restoration with ref.watch conversion`
- `chore: convert ref.read to ref.watch in infra_providers for auto-invalidation`

---

## 핵심 발견

### ref.read()의 위험성: 의존성 추적 불가
```dart
// ❌ 문제 코드
class GetStatisticsUseCase {
  final StatisticsRepository _repo = ref.read(statisticsRepositoryProvider);

  Future<Statistics> execute() async {
    // _repo는 초기화 시점의 old instance 캐시됨
    // upstream (statisticsRepositoryProvider)이 invalidate되어도
    // _repo는 여전히 old instance 참조
    return _repo.getStatistics();
  }
}
```

**왜 발생하는가?**
1. `ref.read(X)` 호출 시 X의 **현재 값**만 반환
2. Riverpod은 "X가 변경되면 나도 변경"이라는 의존성 메타데이터 기록 **안함**
3. Provider 무효화 시 **자동 전파가 중단**됨

### ref.watch()의 장점: 자동 의존성 추적
```dart
// ✅ 올바른 코드
class GetStatisticsUseCase {
  final statisticsRepoProvider = ref.watch(statisticsRepositoryProvider);

  Future<Statistics> execute() async {
    // Riverpod이 자동으로 의존성 기록:
    // "GetStatisticsUseCase는 statisticsRepositoryProvider에 의존한다"
    return statisticsRepoProvider.getStatistics();
  }
}
```

**동작:**
1. `ref.watch(X)` → X의 값 반환 + 의존성 메타데이터 기록
2. X가 invalidate되면 watch하는 모든 Provider도 **자동 invalidate**
3. 명시적 무효화 코드 불필요

---

## 적용 패턴

### 패턴 1: UseCase에서 Repository 참조 (이번 세션 수정)

**변경 전 (ref.read):**
```dart
// lib/domain/usecases/get_statistics_usecase.dart
final class GetStatisticsUseCase {
  GetStatisticsUseCase(this._repository);
  final StatisticsRepository _repository;
}

// lib/presentation/providers/infra_providers.dart
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.read(statisticsRepositoryProvider);  // ❌ 의존성 미추적
  return GetStatisticsUseCase(repo);
});
```

**변경 후 (ref.watch):**
```dart
// lib/presentation/providers/infra_providers.dart
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);  // ✅ 자동 의존성 추적
  return GetStatisticsUseCase(repo);
});
```

**적용 범위** (10개 UseCase Provider 변경):
- `getStatisticsUseCaseProvider`
- `getDiaryUseCaseProvider`
- `analyzeEmotionUseCaseProvider`
- `getTopKeywordsUseCaseProvider`
- `getSafetyCheckUseCaseProvider`
- 등등 (모든 core layer UseCase Provider)

### 패턴 2: Provider에서 또 다른 Provider 의존

**일반적 규칙:**
```dart
// ✅ DO: 같은 레이어 내에서 최상위 Provider 호출
final diaryListProvider = FutureProvider.autoDispose((ref) async {
  final useCase = ref.watch(getDiaryUseCaseProvider);  // watch
  return useCase.execute();
});

// ❌ DON'T: 같은 레이어 내 Provider를 read로 참조
final diaryListProvider = FutureProvider.autoDispose((ref) async {
  final useCase = ref.read(getDiaryUseCaseProvider);  // ❌ no tracking
  return useCase.execute();
});
```

### 패턴 3: 복잡한 Provider 체인

**시각화:**
```
Data Layer (ref.watch 필수)
  sqliteLocalDataSourceProvider
    ↑ (watch)
repositoryProvider
  ↑ (watch)
useCaseProvider
  ↑ (watch)
businessLogicProvider (FutureProvider)
  ↑ (watch)
uiLayerProvider (StateNotifier or computed)
```

**모든 연결이 watch여야 invalidation chain이 작동**

---

## 주의사항

### 1. ref.read()가 적절한 경우 (제한적)

```dart
// ✅ 일회성 초기화 (UI 계층의 이벤트 핸들러)
onPressed: () {
  final controller = ref.read(diaryListControllerProvider.notifier);
  controller.addDiary(form);
  // read 사용 가능: 이 callback은 invalidation chain과 무관
}

// ❌ Provider 정의 내부에서 의존성 참조
final myProvider = Provider((ref) {
  // read 금지: Provider 초기화 시에는 watch 사용
  final dep = ref.read(someProvider);
});
```

**구분:**
- **Provider 정의 내부** → `ref.watch()` (의존성 추적 필수)
- **UI event handler (onPressed, onChanged 등)** → `ref.read()` 가능
- **StateNotifier 액션 메서드** → `ref.read()` 가능

### 2. autoDispose Provider 주의

```dart
final expensiveComputation = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(repositoryProvider);  // watch 필수
  return repo.fetchLargeData();
});

// 화면 진입 전 구독 안함 → 처음 구독 시 계산됨
// 화면 벗어나면 자동 dispose → 메모리 효율적
// 하지만 invalidate 시 명시적으로 invalidate(expensiveComputation) 필요할 수도
```

**해결:**
```dart
// main.dart (Composition Root)
if (wasRecovered) {
  appContainer.invalidate(sqliteLocalDataSourceProvider);
  // ↓ 자동 전파 (watch chain 덕분)
  // repositoryProvider → useCaseProvider → expensiveComputation
  // 모두 자동 재생성
}
```

### 3. 성능: watch vs read 오버헤드

```dart
// 성능 고려: ref.watch()는 미세한 오버헤드 있음
// (의존성 메타데이터 기록, 리스너 등록)

// 현실: 무시할 수준 (< 1ms)
// 권장: 항상 watch 사용 → 유지보수성 우선
```

---

## 실전 디버깅

### 문제: "invalidate했는데 Provider가 갱신 안됨"

**체크리스트:**
```
1. invalidate 호출 확인
   ✓ appContainer.invalidate(myProvider) 실행됨?

2. 의존성 체인 확인
   ✓ myProvider 내부에서 ref.watch() 사용?
   ✓ 참조 대상 Provider도 watch인지 확인

3. autoDispose Provider 확인
   ✓ autoDispose면 구독 안될 때 자동 dispose됨
   ✓ 명시적으로도 invalidate 필요

4. UI 레이어 확인
   ✓ Widget이 invalidate된 Provider를 ref.watch?
   ✓ 아니면 한 번 읽기만 하는 상태?
```

### 디버그 로그 추가

```dart
// infra_providers.dart
final statisticsRepositoryProvider = Provider((ref) {
  debugPrint('[Repository] StatisticsRepository 생성');
  return StatisticsRepositoryImpl(ref.watch(sqliteLocalDataSourceProvider));
});

final getStatisticsUseCaseProvider = Provider((ref) {
  debugPrint('[UseCase] GetStatisticsUseCase 생성 (watch applied)');
  return GetStatisticsUseCase(ref.watch(statisticsRepositoryProvider));
});

// main.dart
if (wasRecovered) {
  debugPrint('[Main] DB recovery detected - invalidating sqliteLocalDataSourceProvider');
  appContainer.invalidate(sqliteLocalDataSourceProvider);
  // 콘솔에서 다음이 순차 출력되어야 함:
  // [Repository] StatisticsRepository 생성
  // [UseCase] GetStatisticsUseCase 생성 (watch applied)
}
```

---

## 결론 및 권장사항

### 핵심 규칙 (Golden Rules)

1. **Provider 정의 내에서는 항상 ref.watch()**
   - 예외: 절대 없음 (명시적으로 필요한 경우도 watch 사용)

2. **UI event handler에서만 ref.read() 허용**
   - `onPressed()`, `onChanged()`, StateNotifier 액션 메서드

3. **의존성 체인은 모두 watch로 연결**
   - 깨진 링크 하나 = invalidation chain 중단

### 앞으로의 코드 리뷰 기준
- [ ] Provider 정의 내 ref.read() 발견 → 즉시 watch로 변경
- [ ] autoDispose Provider의 invalidation chain 확인
- [ ] main.dart에서 모든 관련 Provider 무효화 명시 여부

### 유사 버그 방지
- 다음 구현 시 "usecase 패턴" 템플릿 사용
- `infra_providers.dart` 검토 시 ref.read 스캔 자동화 가능
