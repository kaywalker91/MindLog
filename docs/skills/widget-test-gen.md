# widget-test-gen

Flutter 위젯/화면에 대한 테스트를 프로젝트 패턴에 맞게 자동 생성하는 스킬

## 목표
- UI 컴포넌트 테스트 커버리지 향상
- 일관된 위젯 테스트 패턴 유지
- 화면 레벨 테스트 자동화

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "위젯 테스트 생성", "widget test 만들어줘" 요청
- `/widget-test [파일경로]` 명령어
- 새 Screen/Widget 생성 후
- 테스트 커버리지 분석 시 presentation 레이어 미커버 감지

## 참조 템플릿
참조: `test/widget_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/presentation/screens/{screen}.dart';
import 'package:mindlog/presentation/providers/providers.dart';

// Mock Provider overrides
final mockDiaryRepository = MockDiaryRepository();
final testProviderOverrides = [
  diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
];

void main() {
  group('{WidgetName}', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: testProviderOverrides);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: {WidgetName}(),
          ),
        ),
      );

      expect(find.byType({WidgetName}), findsOneWidget);
    });

    testWidgets('displays initial state', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: {WidgetName}(),
          ),
        ),
      );

      // 초기 상태 검증
      expect(find.text('예상 텍스트'), findsOneWidget);
    });

    testWidgets('handles user interaction', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: {WidgetName}(),
          ),
        ),
      );

      // 사용자 상호작용 시뮬레이션
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // 결과 검증
      expect(find.text('변경된 텍스트'), findsOneWidget);
    });
  });
}
```

## 프로세스

### Step 1: 대상 위젯 분석
1. Screen/Widget 클래스 읽기
2. 의존성 식별 (Provider, Repository)
3. 상태 관리 패턴 확인 (ConsumerWidget, ConsumerStatefulWidget)
4. 사용자 상호작용 요소 파악

### Step 2: Mock/Stub 생성
```dart
// Repository Mock (test-unit-gen 스킬 참조)
class MockDiaryRepository implements DiaryRepository {
  // ... Mock 구현
}

// Provider Overrides
final testProviderOverrides = [
  diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
  // 추가 Provider overrides
];
```

### Step 3: 테스트 그룹 구성
1. **렌더링 테스트**
   - 위젯이 정상적으로 렌더링되는지
   - 초기 상태 표시 확인
2. **상태 테스트**
   - 데이터 로딩 상태
   - 에러 상태 표시
   - 빈 상태 표시
3. **상호작용 테스트**
   - 버튼 탭
   - 텍스트 입력
   - 스크롤/스와이프
4. **네비게이션 테스트**
   - 화면 전환 검증

### Step 4: 테스트 작성
파일: `test/presentation/screens/{screen}_test.dart`

## 출력 형식

```
🧪 위젯 테스트 생성 완료

✅ test/presentation/screens/{screen}_test.dart

테스트 그룹:
├── 렌더링 테스트 (2개)
│   ├── renders correctly
│   └── displays initial state
├── 상태 테스트 (3개)
│   ├── shows loading indicator
│   ├── displays error message on failure
│   └── shows empty state when no data
└── 상호작용 테스트 (2개)
    ├── handles button tap
    └── navigates to detail screen

Mock 클래스:
├── MockDiaryRepository
└── Provider overrides 설정

📝 실행 방법:
   flutter test test/presentation/screens/{screen}_test.dart
```

## 테스트 유형

### Screen 테스트
```dart
testWidgets('DiaryListScreen shows diary entries', (tester) async {
  mockRepository.mockDiaries = [testDiary1, testDiary2];

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DiaryListScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(DiaryCard), findsNWidgets(2));
});
```

### Widget 테스트
```dart
testWidgets('ResultCard displays sentiment correctly', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: ResultCard(
          sentimentScore: 80,
          energyLevel: 3,
        ),
      ),
    ),
  );

  expect(find.text('80'), findsOneWidget);
  expect(find.byIcon(Icons.sentiment_satisfied), findsOneWidget);
});
```

### 상호작용 테스트
```dart
testWidgets('tapping delete button shows confirmation dialog', (tester) async {
  await tester.pumpWidget(/* ... */);

  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);
});
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 테스트 파일 | `{원본파일명}_test.dart` | `diary_list_screen_test.dart` |
| 테스트 경로 | `test/presentation/screens/` | |
| 테스트 그룹 | `{WidgetClassName}` | `DiaryListScreen` |
| 테스트 설명 | 영문, 동사형 | `shows loading indicator` |

## 기존 화면 목록
참조: `lib/presentation/screens/`

| Screen | 테스트 상태 | 우선순위 |
|--------|----------|---------|
| MainScreen | 미생성 | P1 |
| DiaryListScreen | 미생성 | P1 |
| DiaryScreen | 미생성 | P1 |
| SettingsScreen | 미생성 | P2 |
| StatisticsScreen | 미생성 | P2 |
| SplashScreen | 미생성 | P3 |

## Riverpod 테스트 패턴

### ProviderContainer 사용
```dart
late ProviderContainer container;

setUp(() {
  container = ProviderContainer(overrides: [
    diaryRepositoryProvider.overrideWithValue(mockRepository),
  ]);
});

tearDown(() {
  container.dispose();
});
```

### UncontrolledProviderScope 사용
```dart
await tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: TestWidget()),
  ),
);
```

## 연관 스킬
- `/test-unit-gen [파일]` - UseCase/Repository 단위 테스트
- `/mock [repository]` - Mock 클래스 생성
- `/coverage` - 테스트 커버리지 리포트

## 주의사항
- Riverpod `ProviderScope`는 테스트에서 `UncontrolledProviderScope` 사용
- `pumpAndSettle()`은 애니메이션 완료까지 대기
- Golden 테스트는 별도 설정 필요
- 비동기 상태는 `pump()` 후 상태 변화 확인
- Mock 클래스는 테스트 파일 내 정의 또는 `test/mocks/` 디렉토리 사용
