# flutter-advanced

Flutter/Riverpod 심화 패턴 및 생산성 도구 (`/flutter-advanced [action]`)

## 목표
- Riverpod async state 패턴 심화
- freezed 모델 효율적 활용
- go_router 고급 패턴
- 성능 최적화 기법

## 트리거 조건
- `/flutter-advanced [action]` 명령어
- 복잡한 상태 관리 로직 구현 시
- 성능 이슈 해결 필요 시
- 고급 네비게이션 패턴 적용 시

## 핵심 패턴

### 1. Riverpod Async State Pattern

```dart
// ✅ 권장: AsyncValue를 활용한 상태 관리
@riverpod
class DiaryList extends _$DiaryList {
  @override
  Future<List<Diary>> build() async {
    return ref.watch(diaryRepositoryProvider).getAllDiaries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(diaryRepositoryProvider).getAllDiaries()
    );
  }

  Future<void> addDiary(Diary diary) async {
    final previous = state;
    // Optimistic update
    state = AsyncData([...?state.valueOrNull, diary]);

    try {
      await ref.read(diaryRepositoryProvider).saveDiary(diary);
    } catch (e, st) {
      // Rollback on failure
      state = previous;
      state = AsyncError(e, st);
    }
  }
}
```

### 2. Provider Invalidation Chain

```dart
// ✅ 데이터 변경 시 연쇄 무효화
Future<void> saveDiary(Diary diary) async {
  await _repository.saveDiary(diary);

  // 연관 Provider 무효화
  ref.invalidate(diaryListProvider);
  ref.invalidate(statisticsProvider);
  ref.invalidate(todayEmotionProvider);
}
```

### 3. Freezed Model Pattern

```dart
// ✅ 권장: Union types for states
@freezed
class DiaryState with _$DiaryState {
  const factory DiaryState.initial() = _Initial;
  const factory DiaryState.loading() = _Loading;
  const factory DiaryState.loaded(List<Diary> diaries) = _Loaded;
  const factory DiaryState.error(String message) = _Error;
}

// ✅ 권장: copyWith for immutable updates
diary.copyWith(
  content: newContent,
  updatedAt: DateTime.now(),
);
```

### 4. go_router Advanced Patterns

```dart
// ✅ 권장: Typed routes with parameters
@TypedGoRoute<DiaryDetailRoute>(
  path: '/diary/:id',
)
class DiaryDetailRoute extends GoRouteData {
  final int id;
  const DiaryDetailRoute({required this.id});

  @override
  Widget build(context, state) => DiaryDetailScreen(diaryId: id);
}

// ✅ 권장: Redirect with authentication
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider).isLoggedIn;
  final isOnboarding = state.matchedLocation == '/onboarding';

  if (!isLoggedIn && !isOnboarding) {
    return '/onboarding';
  }
  return null;
}
```

## Actions

### audit-providers
Provider 구조 및 의존성 감사
1. Provider 의존성 그래프 생성
2. 순환 의존성 탐지
3. 과도한 리빌드 식별
4. 최적화 권고사항 제시

```bash
> /flutter-advanced audit-providers

Provider 감사 결과:
├── 총 Provider: 42개
├── Async Provider: 15개
├── 순환 의존성: 없음 ✅
├── 과도한 watch: 3건 발견
└── 권장 조치: ref.watch → ref.read 변환 (3건)
```

### optimize-rebuilds
위젯 리빌드 최적화
1. 불필요한 리빌드 패턴 탐지
2. const 위젯 활용 검사
3. select/selectAsync 적용 제안
4. 분리 가능한 위젯 식별

```dart
// ❌ 비효율적: 전체 객체 watch
final diary = ref.watch(diaryProvider);
Text(diary.title);

// ✅ 효율적: select로 필요한 부분만
final title = ref.watch(diaryProvider.select((d) => d.title));
Text(title);
```

### async-patterns
비동기 패턴 가이드 제공
1. AsyncValue 활용법
2. FutureProvider vs StreamProvider
3. Error/Loading 상태 처리
4. Retry 패턴

```dart
// ✅ AsyncValue 패턴 활용
asyncValue.when(
  data: (data) => ListView.builder(...),
  loading: () => const LoadingIndicator(),
  error: (e, st) => ErrorWidget(
    message: e.toString(),
    onRetry: () => ref.invalidate(provider),
  ),
);
```

### navigation-patterns
고급 네비게이션 패턴
1. Deep linking 설정
2. Nested navigation
3. Route guards
4. Modal/Dialog routes

## 성능 최적화 체크리스트

### 빌드 최적화
- [ ] const 생성자 최대 활용
- [ ] 큰 리스트에 ListView.builder 사용
- [ ] Image caching (cached_network_image)
- [ ] build() 내 expensive 연산 금지

### 상태 관리 최적화
- [ ] ref.watch vs ref.read 구분
- [ ] select로 필요한 부분만 구독
- [ ] 적절한 invalidation 범위
- [ ] keepAlive 적절히 사용

### 메모리 최적화
- [ ] dispose 패턴 준수
- [ ] 대용량 리스트 pagination
- [ ] 이미지 메모리 캐시 제한
- [ ] Stream 구독 해제

## Riverpod Provider 패턴 가이드

### Provider 선택 가이드

| 상황 | Provider 타입 |
|------|---------------|
| 단순 값/설정 | `Provider` |
| 변경 가능한 상태 | `StateProvider` |
| 단일 비동기 데이터 | `FutureProvider` |
| 실시간 데이터 | `StreamProvider` |
| 복잡한 상태 로직 | `NotifierProvider` |
| 비동기 + 복잡한 로직 | `AsyncNotifierProvider` |

### ref.watch vs ref.read

```dart
// watch: 값이 변경될 때 리빌드 필요
// 주로 build() 내에서 사용
final diaries = ref.watch(diaryListProvider);

// read: 일회성 읽기, 리빌드 불필요
// 주로 콜백/이벤트 핸들러에서 사용
onPressed: () {
  ref.read(diaryControllerProvider.notifier).save();
}
```

## 출력 형식

```
Flutter Advanced 감사 결과
=========================

📊 Provider 분석:
├── 총 Provider: 42개
├── 타입 분포: Async(15), Notifier(12), State(10), Other(5)
├── 의존성 깊이: 최대 4단계
└── 순환 의존성: 없음 ✅

🔍 최적화 기회:
├── [WARN] diaryListProvider: 과도한 watch 발견
├── [INFO] statisticsProvider: select 적용 권장
└── [OK] 전반적 구조 양호

📋 권장 조치:
1. diaryListProvider watch → select 변환
2. statisticsProvider keepAlive 추가 검토
3. calendarProvider 캐싱 전략 개선

다음 단계:
└── /flutter-advanced optimize-rebuilds
```

## 연관 스킬
- `/provider-centralize` - Provider 중앙화
- `/provider-invalidation-audit` - 무효화 감사
- `/widget-decompose` - 위젯 분해

## 주의사항
- Provider 의존성은 명확히 문서화
- 순환 의존성 절대 금지
- AsyncNotifier의 build()에서 ref.watch 사용 주의
- keepAlive 남용 시 메모리 누수 가능

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | development / flutter |
| Dependencies | provider-centralize |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
