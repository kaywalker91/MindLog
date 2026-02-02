# riverpod-widget-test-gen

Riverpod Provider를 사용하는 위젯에 대한 테스트 코드를 자동 생성하는 스킬

## 목표
- ConsumerWidget/ConsumerStatefulWidget 테스트 자동화
- Mock Repository + ProviderContainer 패턴 적용
- AAA(Arrange-Act-Assert) 패턴 준수

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/riverpod-widget-test-gen [file]` 명령어
- "Riverpod 위젯 테스트 생성해줘" 요청
- `/widget-decompose` 완료 후 테스트 생성 권장 시

## 참조 템플릿
참조: `test/presentation/widgets/settings/settings_sections_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  group('MyWidget', () {
    late ProviderContainer container;
    late MockXxxRepository mockRepo;

    setUp(() {
      mockRepo = MockXxxRepository();
      container = ProviderContainer(
        overrides: [
          xxxRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      mockRepo.reset();
      container.dispose();
    });

    testWidgets('위젯이 올바르게 렌더링되어야 한다', (tester) async {
      // Arrange
      mockRepo.setMockData(testData);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: MyWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

## 핵심 패턴

### UncontrolledProviderScope 패턴
```dart
// ProviderContainer를 테스트에서 직접 제어
final container = ProviderContainer(
  overrides: [
    // Provider를 Mock으로 교체
    settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
    diaryRepositoryProvider.overrideWithValue(mockDiaryRepo),
  ],
);

// 위젯 트리에 주입
UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: MyScreen()),
)
```

### Mock Repository 패턴
```dart
class MockSettingsRepository implements SettingsRepository {
  AiCharacter _character = AiCharacter.warmCounselor;
  NotificationSettings _notificationSettings = NotificationSettings.defaults();

  void setMockCharacter(AiCharacter character) {
    _character = character;
  }

  void setMockNotificationSettings(NotificationSettings settings) {
    _notificationSettings = settings;
  }

  void reset() {
    _character = AiCharacter.warmCounselor;
    _notificationSettings = NotificationSettings.defaults();
  }

  @override
  Future<AiCharacter> getAiCharacter() async => _character;

  @override
  Future<NotificationSettings> getNotificationSettings() async => _notificationSettings;
}
```

## 프로세스

### Step 1: 대상 위젯 분석
```bash
# Provider 의존성 확인
grep -n "ref.watch\|ref.read\|ref.listen" [target_file]

# 사용 중인 Provider 목록
grep -oP "(\w+Provider)" [target_file] | sort | uniq
```

분석 항목:
- `ConsumerWidget` vs `ConsumerStatefulWidget`
- `ref.watch()` 대상 Provider 목록
- UI 렌더링 조건

### Step 2: Mock Repository 확인/생성
```bash
# 기존 Mock 확인
ls test/mocks/mock_repositories.dart
```

Mock이 없으면 생성:
```dart
class MockXxxRepository implements XxxRepository {
  // 상태 필드
  // setter 메서드
  // reset() 메서드
  // @override 메서드
}
```

### Step 3: 테스트 파일 생성
```
test/presentation/widgets/{feature}/{widget}_test.dart
```

테스트 케이스 유형:
| 유형 | 예시 |
|------|------|
| 렌더링 | "위젯이 올바르게 렌더링되어야 한다" |
| 상태 반영 | "데이터가 화면에 표시되어야 한다" |
| 상호작용 | "버튼 탭 시 다이얼로그가 표시되어야 한다" |
| 에러 처리 | "에러 상태에서 에러 메시지가 표시되어야 한다" |
| 로딩 상태 | "로딩 중 인디케이터가 표시되어야 한다" |

### Step 4: 테스트 실행
```bash
# 단일 파일 테스트
flutter test test/presentation/widgets/{feature}/{widget}_test.dart

# 전체 테스트
flutter test
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
                🧪 Riverpod 위젯 테스트 생성 완료
═══════════════════════════════════════════════════════════

대상 위젯: EmotionCareSection

분석 결과:
├── 위젯 타입: ConsumerWidget
├── Provider 의존성: settingsRepositoryProvider
└── UI 요소: 2개 ListTile

생성된 테스트:
├── 파일: test/presentation/widgets/settings/emotion_care_section_test.dart
├── 테스트 케이스: 3개
│   ├── "AI 캐릭터 섹션이 렌더링되어야 한다"
│   ├── "AI 캐릭터 라벨이 올바르게 표시되어야 한다"
│   └── "AI 캐릭터 탭 시 BottomSheet가 표시되어야 한다"
└── Mock 사용: MockSettingsRepository

다음 단계:
├── flutter test [test_file] (테스트 실행)
└── /coverage (커버리지 확인)
```

## 템플릿 코드

### 기본 테스트 구조
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/{feature}/{widget}.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  group('{WidgetName}', () {
    late ProviderContainer container;
    late Mock{Xxx}Repository mockRepo;

    setUp(() {
      mockRepo = Mock{Xxx}Repository();
      container = ProviderContainer(
        overrides: [
          {xxx}RepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      mockRepo.reset();
      container.dispose();
    });

    testWidgets('위젯이 올바르게 렌더링되어야 한다', (tester) async {
      // Arrange
      mockRepo.setMockData(testData);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: {WidgetName}(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Expected'), findsOneWidget);
    });
  });
}
```

### 다이얼로그 테스트
```dart
testWidgets('버튼 탭 시 다이얼로그가 표시되어야 한다', (tester) async {
  // Arrange
  await tester.pumpWidget(/* ... */);
  await tester.pumpAndSettle();

  // Act
  await tester.tap(find.text('버튼 텍스트'));
  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('다이얼로그 제목'), findsOneWidget);
});
```

### Switch 상태 테스트
```dart
testWidgets('토글 상태가 올바르게 표시되어야 한다', (tester) async {
  // Arrange
  mockRepo.setMockSettings(Settings(enabled: false));
  await tester.pumpWidget(/* ... */);
  await tester.pumpAndSettle();

  // Assert
  final switchFinder = find.byType(Switch).first;
  final switchWidget = tester.widget<Switch>(switchFinder);
  expect(switchWidget.value, false);
});
```

## 사용 예시

```
> "/riverpod-widget-test-gen lib/presentation/widgets/settings/emotion_care_section.dart"

AI 응답:
1. 위젯 분석: ConsumerWidget, settingsRepositoryProvider 사용
2. Mock 확인: MockSettingsRepository 존재
3. 테스트 생성: 3개 테스트 케이스
4. 파일 저장: test/presentation/widgets/settings/emotion_care_section_test.dart
5. flutter test: ✅ 3/3 통과
6. 완료
```

## 연관 스킬
- `/widget-decompose` - 위젯 분해 후 테스트 생성
- `/widget-test [file]` - 일반 위젯 테스트 생성
- `/coverage` - 테스트 커버리지 확인
- `/mock-gen [repository]` - Mock Repository 생성

## 주의사항
- `pumpAndSettle()` 사용: 비동기 Provider 완료 대기
- `SingleChildScrollView` 래핑: 오버플로우 방지
- `tearDown`에서 `container.dispose()`: 메모리 누수 방지
- Mock `reset()`: 테스트 간 상태 격리

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | testing |
| Dependencies | widget-test-gen, mock-gen |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
