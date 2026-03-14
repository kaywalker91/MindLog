# TIL: IndexedStack Eager Build — Core Concepts & Root Cause

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Topic**: Widget build lifecycle와 Provider 구독 타이밍
**Split from**: til-indexedstack-immediate-build.md (Part 1/2)

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
