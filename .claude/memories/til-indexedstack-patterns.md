# TIL: IndexedStack Eager Build — Additional Issues, Patterns & Conclusion

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Split from**: til-indexedstack-immediate-build.md (Part 2/2)

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
