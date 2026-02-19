# integration-test-gen

E2E 통합 테스트를 프로젝트 패턴에 맞게 자동 생성하는 스킬

## 목표
- 사용자 플로우 E2E 테스트 자동화
- 통합 테스트 커버리지 향상
- 회귀 테스트 시간 단축

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "통합 테스트 생성", "integration test" 요청
- `/integration-test [flow_name]` 명령어
- 새 사용자 플로우 추가 후
- E2E 테스트 누락 감지 시

## 테스트 디렉토리 구조
```
integration_test/
├── app_test.dart              # 메인 테스트 진입점
├── flows/
│   ├── diary_flow_test.dart   # 일기 작성 플로우
│   ├── analysis_flow_test.dart # AI 분석 플로우
│   └── settings_flow_test.dart # 설정 플로우
├── robots/
│   ├── diary_robot.dart       # 일기 화면 로봇
│   ├── analysis_robot.dart    # 분석 화면 로봇
│   └── settings_robot.dart    # 설정 화면 로봇
└── utils/
    ├── test_helper.dart       # 테스트 유틸리티
    └── mock_services.dart     # 서비스 Mock
```

## 프로세스

### Step 1: 테스트 대상 플로우 정의
1. 사용자 시나리오 분석
2. 주요 액션 나열
3. 검증 포인트 식별
4. 경계 조건 정의

### Step 2: Robot 클래스 생성
```dart
// integration_test/robots/diary_robot.dart

import 'package:flutter_test/flutter_test.dart';

/// 일기 화면 테스트 로봇
class DiaryRobot {
  final WidgetTester tester;

  DiaryRobot(this.tester);

  // ====== Finders ======
  Finder get contentField => find.byKey(const Key('diary_content_field'));
  Finder get saveButton => find.byKey(const Key('save_button'));
  Finder get analysisResult => find.byKey(const Key('analysis_result'));
  Finder get loadingIndicator => find.byType(CircularProgressIndicator);

  // ====== Actions ======
  Future<void> enterContent(String content) async {
    await tester.enterText(contentField, content);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave() async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> waitForAnalysis({Duration timeout = const Duration(seconds: 10)}) async {
    await tester.pumpAndSettle(timeout);
  }

  // ====== Assertions ======
  void expectContentFieldVisible() {
    expect(contentField, findsOneWidget);
  }

  void expectAnalysisResultVisible() {
    expect(analysisResult, findsOneWidget);
  }

  void expectLoadingVisible() {
    expect(loadingIndicator, findsOneWidget);
  }

  void expectLoadingGone() {
    expect(loadingIndicator, findsNothing);
  }
}
```

### Step 3: 플로우 테스트 작성
```dart
// integration_test/flows/diary_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindlog/main.dart' as app;
import '../robots/diary_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('일기 작성 플로우', () {
    late DiaryRobot diaryRobot;

    setUp(() {
      // 테스트 환경 설정
    });

    testWidgets('사용자가 일기를 작성하고 AI 분석을 받을 수 있다', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();
      diaryRobot = DiaryRobot(tester);

      // Act - 일기 작성
      diaryRobot.expectContentFieldVisible();
      await diaryRobot.enterContent('오늘 좋은 일이 있었어요.');
      await diaryRobot.tapSave();

      // Assert - 분석 결과 확인
      await diaryRobot.waitForAnalysis();
      diaryRobot.expectAnalysisResultVisible();
    });

    testWidgets('빈 내용으로 저장하면 에러가 표시된다', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();
      diaryRobot = DiaryRobot(tester);

      // Act
      await diaryRobot.tapSave();

      // Assert
      expect(find.text('내용을 입력해 주세요'), findsOneWidget);
    });
  });
}
```

### Step 4: Mock 서비스 설정
```dart
// integration_test/utils/mock_services.dart

import 'package:mindlog/domain/repositories/diary_repository.dart';

class MockDiaryRepository implements DiaryRepository {
  bool shouldFail = false;
  Duration delay = const Duration(milliseconds: 500);

  @override
  Future<Diary> saveDiary(Diary diary) async {
    await Future.delayed(delay);
    if (shouldFail) {
      throw Exception('Mock error');
    }
    return diary.copyWith(
      status: DiaryStatus.analyzed,
      analysisResult: _mockAnalysisResult,
    );
  }

  AnalysisResult get _mockAnalysisResult => AnalysisResult(
    keywords: ['행복', '기쁨', '만족'],
    sentimentScore: 80,
    empathyMessage: '좋은 하루를 보내셨네요!',
    actionItems: ['오늘의 기쁨을 기록해보세요'],
  );

  // ... 기타 메서드
}
```

### Step 5: 테스트 실행
```bash
# 통합 테스트 실행
flutter test integration_test

# 특정 테스트 실행
flutter test integration_test/flows/diary_flow_test.dart

# 특정 디바이스에서 실행
flutter test integration_test -d emulator-5554
```

## Robot 패턴 가이드

### Robot 클래스 구조
```dart
class ScreenRobot {
  final WidgetTester tester;

  ScreenRobot(this.tester);

  // 1. Finders - 위젯 찾기
  Finder get element => find.byKey(Key('element'));

  // 2. Actions - 사용자 액션
  Future<void> doSomething() async {
    await tester.tap(element);
    await tester.pumpAndSettle();
  }

  // 3. Assertions - 상태 검증
  void expectElementVisible() {
    expect(element, findsOneWidget);
  }
}
```

### Key 네이밍 규칙
```dart
// 화면 요소 Key 패턴
const Key('screen_element_type')

// 예시
const Key('diary_content_field')
const Key('diary_save_button')
const Key('analysis_result_card')
const Key('settings_theme_toggle')
```

## 출력 형식

```
🧪 Integration Test 생성 완료

플로우: [테스트 대상 플로우]

생성된 파일:
├── integration_test/robots/diary_robot.dart
│   └── DiaryRobot 클래스
│       ├── Finders: 5개
│       ├── Actions: 4개
│       └── Assertions: 6개
├── integration_test/flows/diary_flow_test.dart
│   └── 테스트 케이스: 3개
└── integration_test/utils/mock_services.dart
    └── MockDiaryRepository

테스트 케이스:
├── ✅ 일기 작성 후 분석 결과 확인
├── ✅ 빈 내용 저장 시 에러 표시
└── ✅ 네트워크 에러 시 재시도 버튼 표시

📝 실행 방법:
   flutter test integration_test

🔧 필요한 Key 추가:
   └── lib/presentation/screens/diary_screen.dart
       (위젯에 Key 속성 추가 필요)
```

## 테스트 시나리오 템플릿

### Happy Path (정상 플로우)
```dart
testWidgets('사용자가 정상적으로 [기능]을 수행할 수 있다', (tester) async {
  // Arrange - 앱 시작
  app.main();
  await tester.pumpAndSettle();

  // Act - 사용자 액션
  await robot.enterData('테스트 데이터');
  await robot.tapSubmit();

  // Assert - 결과 확인
  robot.expectSuccessMessageVisible();
});
```

### Error Path (에러 플로우)
```dart
testWidgets('[에러 조건]에서 적절한 에러 메시지가 표시된다', (tester) async {
  // Arrange - 에러 조건 설정
  mockService.shouldFail = true;
  app.main();
  await tester.pumpAndSettle();

  // Act - 에러 트리거
  await robot.tapSubmit();

  // Assert - 에러 처리 확인
  robot.expectErrorMessageVisible();
});
```

### Edge Case (경계 조건)
```dart
testWidgets('[경계 조건]에서 올바르게 동작한다', (tester) async {
  // Arrange - 경계 조건 설정
  // ...

  // Act - 경계 상황 트리거
  // ...

  // Assert - 예상 동작 확인
  // ...
});
```

## 사용 예시

### 일기 플로우 테스트 생성
```
> "/integration-test diary_flow"

AI 응답:
1. 플로우 분석:
   - 일기 작성 → 저장 → AI 분석 → 결과 표시
2. Robot 생성:
   - DiaryRobot (Finders, Actions, Assertions)
3. 테스트 케이스:
   - 정상 저장 및 분석
   - 빈 내용 에러
   - 네트워크 에러 처리
4. 파일 생성 완료

실행:
   flutter test integration_test/flows/diary_flow_test.dart
```

### 설정 플로우 테스트 생성
```
> "/integration-test settings_flow"

AI 응답:
1. 플로우 분석:
   - 설정 화면 진입 → 옵션 변경 → 저장 확인
2. Robot 생성:
   - SettingsRobot
3. 테스트 케이스:
   - AI 캐릭터 변경
   - 알림 토글
   - 테마 변경
4. 파일 생성 완료
```

## CI/CD 연동

### GitHub Actions
```yaml
# .github/workflows/integration-test.yml
name: Integration Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  integration-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - name: Run integration tests
        run: flutter test integration_test
```

### Firebase Test Lab
```yaml
- name: Run on Firebase Test Lab
  run: |
    flutter build apk --debug
    gcloud firebase test android run \
      --type instrumentation \
      --app build/app/outputs/apk/debug/app-debug.apk \
      --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
```

## 연관 스킬
- `/test-unit-gen` - 단위 테스트 생성
- `/widget-test` - 위젯 테스트 생성
- `/mock` - Mock 클래스 생성

## 주의사항
- 통합 테스트는 실제 디바이스/에뮬레이터 필요
- 테스트 속도를 위해 Mock 서비스 사용 권장
- Key 기반 위젯 찾기로 안정성 확보
- 네트워크 의존 테스트는 타임아웃 설정 필수
- CI에서 실행 시 헤드리스 모드 사용
- 테스트 간 상태 격리 중요 (setUp/tearDown)
- 비동기 작업은 pumpAndSettle로 대기
