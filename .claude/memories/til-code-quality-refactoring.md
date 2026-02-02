# TIL: 코드 품질 리팩토링 (위젯 분해, 색상 마이그레이션, Riverpod 테스트)

**Date**: 2026-02-02
**Session**: settings_sections.dart 분해 + 색상 마이그레이션 + 위젯 테스트 추가

---

## 1. 배럴 파일 패턴 (Barrel Export Pattern)

### 문제
대형 파일(593줄, 5개 클래스)을 분해 후 import 관리가 복잡해짐.

### 해결책
원본 파일을 barrel export 파일로 변환:

```dart
// settings_sections.dart (기존 593줄 → 배럴 파일 9줄)

// Settings screen section widgets - barrel file
//
// Each section has been decomposed into its own file for maintainability.
// Import this file to access all section widgets.

export 'app_info_section.dart';
export 'emotion_care_section.dart';
export 'notification_section.dart';
export 'data_management_section.dart';
export 'support_section.dart';
```

### 효과
- 기존 import 문 변경 불필요 (하위 호환성)
- 단일 import로 모든 섹션 위젯 접근
- 파일 구조 명확화

### Best Practice
| DO | DON'T |
|-----|-------|
| 알파벳 순서로 export 정렬 | export 간 순환 참조 |
| 주석으로 목적 설명 | `///` doc comment 사용 (lint warning) |
| 공개 클래스만 export | 테스트 파일 export |

---

## 2. Theme-Aware 색상 마이그레이션

### 문제
하드코딩된 `Colors.*` 사용으로 다크모드 미지원, 테마 불일치.

### 색상 매핑 규칙
| Before | After | 용도 |
|--------|-------|------|
| `Colors.white` | `colorScheme.surface` | 배경 |
| `Colors.black` | `colorScheme.onSurface` | 텍스트 |
| `Colors.grey.shade600` | `AppColors.textSecondary` | 보조 텍스트 |
| `Colors.orange` | `AppColors.warning` | 경고 |
| `Colors.green` | `AppColors.success` | 성공 |

### 컨텍스트 접근 패턴

```dart
// Pattern 1: build() 메서드 내
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(color: colorScheme.surface);
}

// Pattern 2: private 메서드 (context 파라미터 추가)
Widget _buildCard(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(color: colorScheme.surface);
}

// 호출부
_buildCard(context),
```

### const 제약 해결

```dart
// ❌ Theme.of(context)는 const 불가
const Icon(Icons.star, color: colorScheme.primary)

// ✅ AppColors 상수 사용
const Icon(Icons.star, color: AppColors.textSecondary)

// ✅ 또는 const 제거
Icon(Icons.star, color: colorScheme.primary)
```

---

## 3. Riverpod 위젯 테스트 패턴

### UncontrolledProviderScope 패턴

```dart
group('EmotionCareSection', () {
  late ProviderContainer container;
  late MockSettingsRepository mockSettingsRepo;

  setUp(() {
    mockSettingsRepo = MockSettingsRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
      ],
    );
  });

  tearDown(() {
    mockSettingsRepo.reset();  // 상태 초기화
    container.dispose();        // 메모리 해제
  });

  testWidgets('섹션이 렌더링되어야 한다', (tester) async {
    // Arrange
    mockSettingsRepo.setMockCharacter(AiCharacter.warmCounselor);

    // Act
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(  // 오버플로우 방지
              child: EmotionCareSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();  // 비동기 완료 대기

    // Assert
    expect(find.text('감정 케어'), findsOneWidget);
  });
});
```

### Mock Repository 구현

```dart
class MockSettingsRepository implements SettingsRepository {
  AiCharacter _character = AiCharacter.warmCounselor;

  void setMockCharacter(AiCharacter character) {
    _character = character;
  }

  void reset() {
    _character = AiCharacter.warmCounselor;
  }

  @override
  Future<AiCharacter> getAiCharacter() async => _character;
}
```

### 핵심 포인트
| 항목 | 설명 |
|------|------|
| `UncontrolledProviderScope` | 테스트에서 container 직접 제어 |
| `pumpAndSettle()` | Provider 비동기 완료 대기 |
| `SingleChildScrollView` | 위젯 오버플로우 방지 |
| `tearDown` dispose | 메모리 누수 방지 |

---

## 4. Lint 이슈 해결

### dangling_library_doc_comments

```dart
// ❌ 파일 첫 줄에 doc comment
/// Settings screen section widgets

// ✅ 일반 주석 사용
// Settings screen section widgets
```

### undefined_identifier 'context'

```dart
// ❌ 헬퍼 메서드에서 context 미전달
Widget _buildItem() {
  final color = Theme.of(context).colorScheme.primary;  // Error!
}

// ✅ context 파라미터 추가
Widget _buildItem(BuildContext context) {
  final color = Theme.of(context).colorScheme.primary;
}
```

---

## 결론

### 핵심 교훈
1. **배럴 파일**: 분해 후 import 관리 단순화
2. **Theme-aware 색상**: `colorScheme` + `AppColors` 조합
3. **Riverpod 테스트**: `UncontrolledProviderScope` + Mock 패턴
4. **const 주의**: Theme 접근 시 const 제거 필요

### 자동화 후보 → Skill 생성 완료
- `/color-migrate [file]` - 색상 마이그레이션
- `/barrel-export-gen [dir]` - 배럴 파일 생성
- `/riverpod-widget-test-gen [file]` - Riverpod 위젯 테스트 생성

---

## Metadata

| Property | Value |
|----------|-------|
| Category | refactoring, testing |
| Related Files | settings_sections.dart, sos_card.dart |
| Tests Added | settings_sections_test.dart (8 cases) |
| Skills Created | 3 |
