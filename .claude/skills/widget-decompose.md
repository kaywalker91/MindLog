# widget-decompose

대형 위젯을 모듈화된 컴포넌트로 분해하는 자동화 스킬 (`/widget-decompose [file]`)

## 목표
- 50줄 이상의 대형 위젯 식별 및 분해
- 관심사 분리 원칙에 따른 컴포넌트 추출
- 유지보수성과 테스트 용이성 향상

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "/widget-decompose [file]" 명령어
- "대형 위젯 분해해줘" 요청
- 위젯 파일이 300줄 이상일 때 권장

## 참조 템플릿
참조: `lib/presentation/widgets/settings/` (분해 결과 예시)

```dart
// 분해 전: settings_screen.dart (1,264줄)
// 분해 후:
// ├── settings_screen.dart (~150줄, 조립만)
// └── settings/
//     ├── app_info_section.dart
//     ├── notification_section.dart
//     ├── emotion_care_section.dart
//     ├── data_management_section.dart
//     └── support_section.dart
```

## 프로세스

### Step 1: 위젯 분석
```bash
# 파일 라인 수 확인
wc -l [target_file]

# 메서드/빌더 패턴 분석
grep -n "Widget _build\|Widget build" [target_file]
```

분석 항목:
- 총 라인 수 (300줄 이상 시 분해 권장)
- `_build*` 프라이빗 메서드 개수
- 논리적 섹션 구분점 식별

### Step 2: 분해 계획 수립
섹션별 분리 기준:
| 기준 | 분리 단위 |
|------|----------|
| UI 영역 | header, body, footer |
| 기능 단위 | settings, profile, actions |
| 데이터 의존성 | 독립 Provider 사용 영역 |
| 재사용성 | 다른 화면에서 사용 가능 여부 |

### Step 3: 디렉토리 구조 생성
```
lib/presentation/widgets/{feature}/
├── {section_1}.dart
├── {section_2}.dart
├── ...
└── dialogs/           # 다이얼로그가 있는 경우
    └── {dialog_name}.dart
```

### Step 4: 컴포넌트 추출
각 섹션 위젯 생성 규칙:
- `ConsumerWidget` 또는 `ConsumerStatefulWidget` 사용
- Props는 생성자 매개변수로 전달
- 콜백은 `VoidCallback` 또는 `ValueChanged<T>` 타입
- 내부 상태가 필요하면 `StatefulWidget`

```dart
// 추출된 컴포넌트 템플릿
class {SectionName}Section extends ConsumerWidget {
  const {SectionName}Section({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider 구독
    // UI 렌더링
  }
}
```

### Step 5: 원본 파일 리팩토링
원본 Screen에서 import 후 조립:
```dart
import 'widgets/{feature}/{section_1}.dart';
import 'widgets/{feature}/{section_2}.dart';

class {Feature}Screen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        children: const [
          {Section1}Section(),
          {Section2}Section(),
          // ...
        ],
      ),
    );
  }
}
```

### Step 6: 검증
```bash
# 빌드 확인
flutter analyze

# 테스트 실행
flutter test

# 라인 수 확인 (각 파일 200줄 이하 목표)
wc -l lib/presentation/widgets/{feature}/*.dart
```

## 출력 형식

```
🔍 분석 결과: settings_screen.dart (1,264줄)

식별된 섹션:
├── AppInfoSection (80줄) - 앱 정보 표시
├── NotificationSection (120줄) - 알림 설정
├── EmotionCareSection (60줄) - 감정 케어 설정
├── DataManagementSection (40줄) - 데이터 관리
└── SupportSection (50줄) - 지원/피드백

생성된 파일:
lib/presentation/widgets/settings/
├── app_info_section.dart
├── notification_section.dart
├── emotion_care_section.dart
├── data_management_section.dart
├── support_section.dart
└── dialogs/
    ├── user_name_dialog.dart
    └── ai_character_sheet.dart

다음 단계:
└── /widget-test widgets/settings/*.dart
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 섹션 위젯 | `{Name}Section` | `AppInfoSection` |
| 카드 위젯 | `{Name}Card` | `EmotionInsightCard` |
| 다이얼로그 | `{Name}Dialog` | `UserNameDialog` |
| BottomSheet | `{Name}Sheet` | `AiCharacterSheet` |
| 디렉토리 | `snake_case` | `settings/`, `result_card/` |

## 사용 예시

```
> "/widget-decompose lib/presentation/screens/settings_screen.dart"

AI 응답:
1. 파일 분석: 1,264줄, 6개 빌드 메서드 발견
2. 5개 섹션 + 2개 다이얼로그로 분해 계획
3. widgets/settings/ 디렉토리 생성
4. 7개 컴포넌트 파일 생성
5. settings_screen.dart 리팩토링 (150줄로 축소)
6. flutter analyze: ✅ 통과
7. 완료
```

## 연관 스킬
- `/widget-test [file]` - 분해된 위젯에 대한 테스트 생성
- `/lint-fix` - 분해 후 린트 오류 자동 수정
- `/review [file]` - 분해 결과 코드 리뷰

## 주의사항
- 상태 관리: 분해 시 Provider 의존성 정확히 분리
- 콜백 전파: 부모-자식 간 콜백 체인 확인
- 테마 일관성: 추출된 컴포넌트에서 `Theme.of(context)` 사용
- 성능: 불필요한 rebuild 방지를 위한 `const` 생성자 활용

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | - |
| Created | 2026-01-26 |
| Updated | 2026-01-26 |
