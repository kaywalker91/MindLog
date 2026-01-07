# lint-fix

린트 위반 사항을 자동으로 수정하고 리포트를 생성하는 스킬

## 목표
- 코드 품질 자동 유지
- 린트 위반 자동 수정
- 수정 불가 항목 리포트

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "린트 수정", "lint fix" 요청
- `/lint-fix` 명령어
- PR 생성 전
- 커밋 전 검증

## 프로젝트 린트 설정
참조: `analysis_options.yaml`

### 활성화된 규칙
| 카테고리 | 규칙 수 | 대표 규칙 |
|---------|--------|----------|
| 성능 | 5개 | prefer_const_constructors, prefer_final_locals |
| 코드 품질 | 8개 | avoid_print, use_key_in_widget_constructors |
| null 안전성 | 3개 | prefer_null_aware_operators |
| 타입 안전성 | 3개 | always_declare_return_types |
| 가독성 | 7개 | curly_braces_in_flow_control_structures |

### 제외 파일
```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

## 프로세스

### Step 1: 린트 분석 실행
```bash
flutter analyze --fatal-infos
```

### Step 2: 자동 수정 적용
```bash
# Dart 자동 수정
dart fix --apply

# 포맷팅
dart format .
```

### Step 3: 수정 결과 분석
```
자동 수정됨:
├── prefer_const_constructors: 12개
├── unnecessary_this: 5개
└── prefer_final_locals: 3개

수동 수정 필요:
├── avoid_print (lib/main.dart:45)
└── missing_required_param (lib/presentation/widgets/card.dart:12)
```

### Step 4: 리포트 생성

```markdown
## Lint Fix Report

### 자동 수정 (20개)
| 규칙 | 수정 수 | 파일 |
|------|--------|------|
| prefer_const_constructors | 12 | 8개 파일 |
| unnecessary_this | 5 | 3개 파일 |
| prefer_final_locals | 3 | 2개 파일 |

### 수동 수정 필요 (2개)
| 규칙 | 위치 | 설명 |
|------|------|------|
| avoid_print | lib/main.dart:45 | debugPrint 사용 권장 |
| missing_required_param | lib/widgets/card.dart:12 | key 파라미터 추가 필요 |

### 최종 상태
✅ flutter analyze: 0 issues
```

## 출력 형식

```
🔧 린트 수정 완료

자동 수정: 20개
├── prefer_const_constructors: 12
├── unnecessary_this: 5
└── prefer_final_locals: 3

수동 수정 필요: 2개
├── avoid_print (lib/main.dart:45)
└── missing_required_param (lib/widgets/card.dart:12)

📊 최종 상태:
   └─ flutter analyze: ✅ 0 issues
```

## 사용 예시

```
> "/lint-fix"

AI 응답:
1. flutter analyze 실행
2. 발견된 이슈: 22개
3. dart fix --apply 실행
4. 자동 수정: 20개
5. 수동 수정 필요: 2개
   - lib/main.dart:45 - avoid_print
   - lib/widgets/card.dart:12 - missing_required_param
6. 수정 가이드 제공
```

## CI 연동
```yaml
# .github/workflows/ci.yml
- name: Analyze Code
  run: flutter analyze --fatal-infos
```

## 주의사항
- `*.g.dart`, `*.freezed.dart`는 생성 코드이므로 제외
- `avoid_print`는 `debugPrint` 또는 로깅 서비스로 대체
- `dart fix`는 안전한 수정만 적용 (수동 검토 권장)
