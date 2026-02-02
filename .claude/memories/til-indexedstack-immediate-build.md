# TIL: IndexedStack의 Eager Build 특성과 Provider 캐싱

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Topic**: Widget build lifecycle와 Provider 구독 타이밍

---

## 발견 배경

앱 재설치 후 일기 목록은 표시되지만 통계가 안 보이는 버그 디버깅 중 발견.

**의문:**
- 두 화면 모두 같은 invalidation 코드 적용받았는데
- 일기 목록은 복원되는데 통계만 안 됨?

**답:** IndexedStack의 특성 차이

---

## 핵심: IndexedStack은 모든 자식을 Build함

### 코드 구조

```dart
// lib/presentation/screens/main_screen.dart
class MainScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeScreen(),      // [0]
          DiaryListScreen(), // [1]
          StatisticsScreen(),// [2] ← tab 선택 전에도 build됨!
          SettingsScreen(),  // [3]
        ],
      ),
    );
  }
}
```

### 중요한 차이

| 특성 | IndexedStack | TabBarView |
|------|-------------|-----------|
| 모든 자식 Build | ✓ 즉시 | ✗ lazy (tab 클릭 시) |
| 메모리 | 모두 keep alive | on-demand |
| Provider 구독 | 모두 활성 | 현재만 |
| invalidate 효과 | 모두 반영 | 현재만 반영 |

---

## 타이밍 분석

### Timeline: Main Launch

```
T0: main() 시작
T1: DB 복원 감지
    ↓
T2: invalidate(sqliteLocalDataSourceProvider) 호출
T3: MainScreen build() 호출
    ↓
T4: IndexedStack 생성 (모든 자식 build)
    │
    ├─ HomeScreen.build()
    │   ├─ ref.watch(todayEmotionProvider)
    │   ├─ Provider 구독 [ACTIVE]
    │   └─ async 시작 (usecase → repository → datasource)
    │
    ├─ DiaryListScreen.build()
    │   ├─ ref.watch(diaryListControllerProvider)
    │   ├─ Provider 구독 [ACTIVE]
    │   └─ async 시작
    │
    └─ StatisticsScreen.build()
        ├─ ref.watch(statisticsProvider)
        ├─ Provider 구독 [ACTIVE]
        └─ async 시작 ← 여기서 문제!
            ↓
T5: 유저가 탭 선택 (defaultIndex = 0)
    ↓
T6: IndexedStack index: 0 (HomeScreen만 표시)
    │   StatisticsScreen은 여전히 메모리에 있음 (keep alive)
    │
T7: T4에서 시작된 통계 async 작업이 완료됨
    └─ 하지만 화면이 보이지 않음 (index != 2)
```

---

## 왜 일기 목록은 복원되는가?

### DiaryListScreen은 FutureProvider.autoDispose가 아님

```dart
// lib/presentation/providers/diary_list_provider.dart
final diaryListControllerProvider = StateNotifierProvider.family<
  DiaryListController,
  List<DiaryEntity>,
  DiaryFilter,
>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return DiaryListController(repo);
});

// StateNotifierProvider는:
// - autoDispose 아님
// - 캐시 유지 (dispose 안됨)
// - rebuild 시에도 이전 instance 재사용
```

**따라서:**
1. T2: invalidate(diaryRepositoryProvider)
2. T4: DiaryListScreen build → StateNotifier 재생성
3. T5+: 데이터 바뀌어 있음 ✓

### StatisticsScreen은 FutureProvider.autoDispose

```dart
// lib/presentation/providers/statistics_providers.dart
final statisticsProvider = FutureProvider.autoDispose<Statistics>((ref) {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return useCase.execute();
});

// FutureProvider.autoDispose는:
// - T3에서 "이미 구독" 상태라고 판단
// - T2의 invalidate가 **메모리에는 반영 안됨**
// - 대신 **이전 cached instance 사용**
```

---

## 근본 원인: ref.read()의 의존성 미추적

```dart
// lib/presentation/providers/infra_providers.dart (BEFORE)
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.read(statisticsRepositoryProvider);  // ❌ read
  return GetStatisticsUseCase(repo);
});
```

**흐름:**
1. T4: statisticsProvider 구독
2. T4: getStatisticsUseCaseProvider 요청
3. T4: `ref.read(statisticsRepositoryProvider)` 호출
   - 현재 값 반환 (이미 로드된 old instance)
   - **의존성 메타데이터 기록 안함**
4. T2: invalidate(statisticsRepositoryProvider) 실행
   - 하지만 getStatisticsUseCaseProvider는 여전히 old repo 참조
5. T4+: statisticsProvider의 Future 실행 중
   - old repo 사용 중
   - 데이터 로드 완료되지만, DB 복원된 데이터 포함 안됨 ❌

---

## 해결책: ref.watch() 사용

```dart
// lib/presentation/providers/infra_providers.dart (AFTER)
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);  // ✅ watch
  return GetStatisticsUseCase(repo);
});
```

**새로운 흐름:**
1. T4: statisticsProvider 구독
2. T4: getStatisticsUseCaseProvider 요청
3. T4: `ref.watch(statisticsRepositoryProvider)` 호출
   - 현재 값 반환
   - **의존성 메타데이터 기록됨**
4. T2: invalidate(statisticsRepositoryProvider) 실행
   - Riverpod이 자동으로 감지
   - getStatisticsUseCaseProvider 무효화
   - statisticsProvider 무효화
5. T4+: 무효화된 statisticsProvider 재구성
   - new repo instance 사용
   - DB 복원된 데이터 포함 ✓

---

## IndexedStack의 또 다른 이슈들

### 1. 메모리 누수 위험

```dart
// ❌ 위험: IndexedStack이 모든 화면 keep alive
IndexedStack(
  index: selectedIndex,
  children: [
    expensiveScreen1(),  // 항상 메모리에
    expensiveScreen2(),  // 항상 메모리에
    expensiveScreen3(),  // 항상 메모리에
    heavyDataScreen(),   // 항상 메모리에 (50MB)
  ],
);

// ✅ 개선: autoDispose + 주기적 cleanup
final screen3Provider = FutureProvider.autoDispose((ref) async {
  // 화면 나가면 자동 dispose + 메모리 해제
  return await heavyScreen();
});
```

### 2. Provider 구독 증가

```dart
// IndexedStack이 N개 자식이 있으면
// 각 자식이 subscribe하는 Provider도 N개 구독 상태 유지

// 예: Statistics + Diary + Home = 9개 Provider 동시 구독
// vs TabBarView = 1개만 구독
```

### 3. autoDispose와의 상호작용

```dart
final statsProvider = FutureProvider.autoDispose<Stats>((ref) async {
  // IndexedStack 덕분에 화면이 안 보여도
  // 자동으로 dispose 안됨 (여전히 "구독 중"이므로)

  return await expensive();
});

// 해결: 명시적으로 invalidate 필요
container.invalidate(statsProvider);
```

---

## 실전 패턴

### 패턴 1: MainScreen의 올바른 구조

```dart
class MainScreen extends ConsumerWidget {
  const MainScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          // 모든 화면이 watch를 사용해야 invalidation 작동
          HomeScreen(),              // watch 사용
          DiaryListScreen(),         // watch 사용
          const StatisticsScreen(),  // watch 사용 ← const는 build 최소화
          SettingsScreen(),          // watch 사용
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: [/* items */],
      ),
    );
  }
}
```

### 패턴 2: 무거운 화면은 lazy loading

```dart
// ❌ IndexedStack으로 모든 화면 build (비효율)
IndexedStack(
  index: selectedIndex,
  children: [
    HomeScreen(),
    DiaryListScreen(),
    StatisticsScreen(),  // 50ms build time
    AnalyticsScreen(),   // 200ms build time (무거움)
  ],
);

// ✅ lazy: PageView나 TabBarView 사용 + preload
TabBarView(
  children: [
    HomeScreen(),
    DiaryListScreen(),
    // StatisticsScreen은 탭 선택 시 build
    // AnalyticsScreen은 탭 선택 시 build
  ],
);

// 또는: 필요시 preload (선택사항)
Future.delayed(Duration(milliseconds: 500), () {
  ref.read(analyticsProvider.future);  // 미리 로드
});
```

### 패턴 3: 부분 preload

```dart
// 앱 시작 시 필수 화면만 preload
Future<void> preloadEssentialScreens(WidgetRef ref) async {
  await Future.wait([
    ref.read(homeScreenDataProvider.future),         // 필수
    ref.read(diaryListControllerProvider.notifier),  // 필수
  ]);

  // analytics는 필요 시에만
  // heavy_screen은 lazy
}
```

---

## 테스트 시나리오

### 시나리오: IndexedStack + invalidate

```dart
testWidgets('IndexedStack should apply invalidation to all children', (tester) async {
  final container = ProviderContainer();

  // Arrange
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MainScreen(),
    ),
  );

  // 모든 화면이 build됨 → Provider 구독됨
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(StatisticsScreen), findsOneWidget);

  // Act: invalidate 호출
  container.invalidate(sqliteLocalDataSourceProvider);

  // Assert: 모든 자식 화면의 Provider가 재생성됨
  await tester.pumpWidget(rebuild);
  // stats도 새 데이터로 업데이트되어야 함
});
```

---

## 결론

### IndexedStack 사용 시 체크리스트

- [ ] 모든 자식 화면이 const constructor 사용? (불필요한 rebuild 최소화)
- [ ] 모든 Provider 참조가 ref.watch()? (invalidation 전파)
- [ ] autoDispose Provider에 명시적 invalidate? (메모리 관리)
- [ ] 무거운 화면 있나? (lazy loading 고려)
- [ ] 메모리 사용량 모니터링? (DevTools)

### 주의사항

1. **IndexedStack은 eager builder** → 모든 자식이 T0에 build됨
2. **모든 Provider가 활성** → invalidation이 모두 반영되어야 함
3. **ref.read() 사용 금지** → 의존성 미추적
4. **autoDispose 동작 이해** → keep-alive되면서도 무효화 필요

### 다음 개선

- [ ] 앱 구조 재검토 (IndexedStack vs TabBarView)
- [ ] Provider 의존성 맵 문서화
- [ ] 메모리 프로파일링 (각 화면의 메모리 사용)
- [ ] lazy loading 도입 (무거운 feature들)
