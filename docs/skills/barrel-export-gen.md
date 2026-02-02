# barrel-export-gen

디렉토리 내 Dart 파일들을 묶는 barrel export 파일을 자동 생성하는 스킬

## 목표
- import 문 단순화 (다수 파일 → 단일 배럴 파일)
- 모듈 경계 명확화
- 파일 분해 후 정리 자동화

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/barrel-export-gen [directory]` 명령어
- "배럴 파일 생성해줘" 요청
- `/widget-decompose` 완료 후 자동 실행

## 참조 템플릿
참조: `lib/presentation/widgets/settings/settings_sections.dart`

```dart
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

## 프로세스

### Step 1: 디렉토리 분석
```bash
# 대상 디렉토리 파일 목록
ls -la lib/presentation/widgets/{feature}/

# Dart 파일만 추출
ls lib/presentation/widgets/{feature}/*.dart | grep -v "_test.dart"
```

### Step 2: 배럴 파일 대상 결정
포함 대상:
- 공개 위젯/클래스 파일 (`.dart`)
- 하위 배럴 파일 (서브 디렉토리)

제외 대상:
- 테스트 파일 (`*_test.dart`)
- 프라이빗 파일 (`_*.dart`)
- 기존 배럴 파일 자체

### Step 3: 배럴 파일 생성
```dart
// {feature_name}.dart 또는 {directory_name}.dart

// {Feature} widgets - barrel file
//
// {간단한 설명}

export '{file_1}.dart';
export '{file_2}.dart';
export '{file_3}.dart';
// ... alphabetical order
```

### Step 4: 기존 import 업데이트 (선택)
```dart
// Before: 개별 파일 import
import 'widgets/settings/app_info_section.dart';
import 'widgets/settings/emotion_care_section.dart';
import 'widgets/settings/notification_section.dart';

// After: 배럴 파일 import
import 'widgets/settings/settings_sections.dart';
```

### Step 5: 검증
```bash
# 빌드 확인
flutter analyze

# import 문제 없는지 확인
flutter build apk --debug 2>&1 | head -20
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
                    📦 배럴 파일 생성 완료
═══════════════════════════════════════════════════════════

대상 디렉토리: lib/presentation/widgets/settings/

생성된 배럴 파일: settings_sections.dart

export 항목:
├── app_info_section.dart
├── data_management_section.dart
├── emotion_care_section.dart
├── notification_section.dart
└── support_section.dart

다음 단계:
├── 기존 import 문 업데이트 (선택)
└── flutter analyze (검증)
```

## 네이밍 규칙

| 시나리오 | 배럴 파일명 | 예시 |
|----------|-------------|------|
| 위젯 그룹 | `{group_name}.dart` | `settings_sections.dart` |
| 피처 모듈 | `{feature}.dart` | `statistics.dart` |
| 레이어 | `{layer}.dart` | `providers.dart` |

## 배럴 파일 구조 옵션

### Option A: 단순 export (권장)
```dart
export 'file_a.dart';
export 'file_b.dart';
```

### Option B: show/hide 사용 (선택적 노출)
```dart
export 'file_a.dart' show ClassA, ClassB;
export 'file_b.dart' hide PrivateHelper;
```

### Option C: 재귀 export (서브디렉토리 포함)
```dart
export 'file_a.dart';
export 'subdirectory/subdirectory.dart'; // 하위 배럴
```

## 사용 예시

```
> "/barrel-export-gen lib/presentation/widgets/settings/"

AI 응답:
1. 디렉토리 분석: 5개 Dart 파일 발견
2. 배럴 파일 생성: settings_sections.dart
3. export 문 추가: 5개 파일
4. flutter analyze: ✅ 통과
5. 완료

> "/barrel-export-gen lib/presentation/providers/"

AI 응답:
1. 디렉토리 분석: 12개 Dart 파일 발견
2. 기존 배럴 파일 발견: providers.dart
3. 업데이트: 신규 2개 파일 추가
4. flutter analyze: ✅ 통과
5. 완료
```

## 연관 스킬
- `/widget-decompose` - 위젯 분해 후 배럴 생성
- `/scaffold [name]` - 신규 피처 생성 시 배럴 포함
- `/arch-check` - 모듈 경계 검증

## 주의사항
- 순환 참조 방지: 배럴 파일 간 상호 export 금지
- 알파벳 순서: export 문 정렬 유지
- 주석 포함: 배럴 파일 목적 설명
- 기존 배럴 보존: 덮어쓰기 전 확인

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | quality |
| Dependencies | widget-decompose |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
