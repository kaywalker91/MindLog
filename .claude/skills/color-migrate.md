# color-migrate

하드코딩된 `Colors.*` 색상을 theme-aware `colorScheme` 또는 `AppColors`로 마이그레이션하는 스킬

## 목표
- Material 3 ColorScheme 기반 테마 시스템 일관성 확보
- 다크모드/라이트모드 자동 대응
- 하드코딩 색상으로 인한 시각적 불일치 제거

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/color-migrate [file|directory]` 명령어
- "하드코딩 색상 마이그레이션해줘" 요청
- `/arch-check` 실행 후 색상 위반 발견 시

## 참조 템플릿
참조: `.claude/rules/design-token-rules.md` (Color Migration Table 섹션)

```dart
// Before
Container(color: Colors.white)
Text('Hello', style: TextStyle(color: Colors.black))
Icon(Icons.star, color: Colors.grey)

// After
Container(color: Theme.of(context).colorScheme.surface)
Text('Hello', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
Icon(Icons.star, color: AppColors.textSecondary)
```

## 색상 매핑 테이블

### 기본 매핑
| Before | After | 용도 |
|--------|-------|------|
| `Colors.white` | `colorScheme.surface` | 배경색 |
| `Colors.black` | `colorScheme.onSurface` | 텍스트/아이콘 |
| `Colors.grey` | `AppColors.textSecondary` | 보조 텍스트 |
| `Colors.grey.shade200` | `colorScheme.surfaceContainerHighest` | 연한 배경 |
| `Colors.grey.shade600` | `AppColors.textSecondary` | 중간 회색 |

### 시맨틱 컬러
| Before | After | 용도 |
|--------|-------|------|
| `Colors.red` | `colorScheme.error` | 에러 |
| `Colors.green` | `AppColors.success` | 성공 |
| `Colors.orange` | `AppColors.warning` | 경고 |
| `Colors.blue` | `colorScheme.primary` | 주요 액션 |

### 투명도 패턴
| Before | After |
|--------|-------|
| `Colors.white.withOpacity(0.5)` | `colorScheme.surface.withValues(alpha: 0.5)` |
| `Colors.black.withOpacity(0.3)` | `colorScheme.onSurface.withValues(alpha: 0.3)` |

## 프로세스

### Step 1: 대상 파일 스캔
```bash
# 하드코딩 색상 검색
grep -rn "Colors\." lib/presentation/ --include="*.dart" | head -30

# 파일별 카운트
grep -rn "Colors\." lib/presentation/ --include="*.dart" | cut -d: -f1 | sort | uniq -c | sort -rn
```

분석 결과 예시:
```
12 lib/presentation/widgets/sos_card.dart
 7 lib/presentation/widgets/result_card/sentiment_dashboard.dart
 5 lib/presentation/widgets/update_prompt_dialog.dart
...
```

### Step 2: 우선순위 결정
| 우선순위 | 기준 |
|----------|------|
| HIGH | 10건 이상 또는 핵심 UI 컴포넌트 |
| MEDIUM | 5-9건 |
| LOW | 4건 이하 |

### Step 3: 파일별 마이그레이션
```dart
// 1. 파일 읽기
final file = await Read(filePath);

// 2. context 접근 가능 여부 확인
//    - build() 메서드 내: 직접 사용
//    - 헬퍼 메서드: context 파라미터 추가 필요

// 3. colorScheme 변수 추출 (반복 사용 시)
final colorScheme = Theme.of(context).colorScheme;

// 4. 매핑 테이블 기반 치환
```

### Step 4: 헬퍼 메서드 처리
```dart
// Before: context 없는 private 메서드
Widget _buildCard() {
  return Container(color: Colors.white);
}

// After: context 파라미터 추가
Widget _buildCard(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(color: colorScheme.surface);
}

// 호출부 수정
_buildCard(context),
```

### Step 5: 검증
```bash
# 린트 체크
flutter analyze

# 테스트 실행
flutter test

# 남은 하드코딩 색상 확인
grep -rn "Colors\." lib/presentation/ --include="*.dart" | wc -l
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
                    🎨 색상 마이그레이션 완료
═══════════════════════════════════════════════════════════

스캔 결과:
├── 대상 파일: 27개
├── 총 하드코딩 색상: 96건
└── 마이그레이션 완료: 41건

파일별 현황:
├── sos_card.dart: 12/12 완료 ✅
├── sentiment_dashboard.dart: 7/7 완료 ✅
├── action_items_section.dart: 5/5 완료 ✅
├── mindlog_app_bar.dart: 4/4 완료 ✅
└── ... (나머지 55건 미완료)

다음 단계:
├── flutter analyze (린트 확인)
├── flutter test (테스트 실행)
└── /color-migrate lib/presentation/widgets/ (계속 진행)
```

## 주의사항

### const 제약
```dart
// ❌ const 위젯에서는 Theme.of(context) 사용 불가
const Icon(Icons.star, color: Colors.grey)

// ✅ AppColors 상수 사용
const Icon(Icons.star, color: AppColors.textSecondary)

// ✅ 또는 const 제거
Icon(Icons.star, color: colorScheme.onSurfaceVariant)
```

### Builder 패턴
```dart
// 콜백 내 context 접근 시
Container(
  decoration: BoxDecoration(
    color: Builder(
      builder: (context) => Theme.of(context).colorScheme.surface,
    ), // ❌ 잘못된 사용
  ),
)

// 올바른 방법: 상위에서 colorScheme 추출
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    decoration: BoxDecoration(color: colorScheme.surface),
  );
}
```

### IconTheme 상속
```dart
// Before (const)
const IconThemeData(color: Colors.white)

// After (non-const, 테마 연동)
IconThemeData(color: colorScheme.onPrimary)
```

## 사용 예시

```
> "/color-migrate lib/presentation/widgets/sos_card.dart"

AI 응답:
1. 파일 분석: 12개 하드코딩 색상 발견
2. 매핑 적용:
   - Colors.grey.shade600 → AppColors.textSecondary (4건)
   - Colors.white → colorScheme.onError (3건)
   - Colors.black → colorScheme.onSurface (2건)
   - Colors.red → colorScheme.error (2건)
   - Colors.white70 → colorScheme.onError.withValues(alpha: 0.7) (1건)
3. _buildContactCard에 context 파라미터 추가
4. flutter analyze: ✅ 통과
5. 완료

> "/color-migrate lib/presentation/"

AI 응답:
1. 스캔: 27개 파일, 96건 발견
2. 우선순위 정렬: HIGH 3개, MEDIUM 8개, LOW 16개
3. 순차 마이그레이션 진행...
4. 완료: 41/96 (미완료 파일은 다음 세션에서 계속)
```

## 연관 스킬
- `/arch-check` - 색상 하드코딩 포함 아키텍처 위반 검사
- `/lint-fix` - 마이그레이션 후 린트 자동 수정
- `/widget-decompose` - 대형 위젯 분해 (색상 마이그레이션과 병행)

## 참조 파일
- `.claude/rules/design-token-rules.md` - 전체 색상 매핑 가이드 (Color Migration Table 섹션)
- `lib/core/theme/app_colors.dart` - AppColors 정의

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | - |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
