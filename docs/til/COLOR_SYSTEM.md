# MindLog 컬러 시스템 문서

**최종 업데이트**: 2026-02-24
**연관 태스크**: TASK-UI-003 (REQ-091)

---

## 개요

MindLog는 4개의 컬러 팔레트로 구성되어 있다. 각 팔레트는 **범위(scope)가 분리**되어 있으며 서로 다른 계층에서 관리된다.

---

## 4개 팔레트 역할 및 범위

### 1. `AppColors` — 앱 전역 기본 팔레트
- **위치**: `lib/core/theme/app_colors.dart`
- **범위**: 앱 전체 (전역)
- **역할**: 브랜드 컬러, 감정 컬러, 상태 컬러, 정원/통계 UI 컬러
- **특징**: `const` static 값, 테마 비인식 (라이트/다크 분기 없음)
- **사용 규칙**:
  - 감정 점수 색상: `AppColors.getSentimentColor(score)` 사용
  - 상태 색상 (`success`, `warning`, `error`, `info`): 직접 참조 허용
  - 텍스트 색상 (`textPrimary`, `textSecondary`): 화면에서는 `textTheme` 경유 권장
  - SOS/긴급 컬러 (`sosCardBackground` 등): 직접 참조 허용 (다크 모드 예외 처리 필요)

---

### 2. `StatisticsThemeTokens` — 통계 화면 전용 디자인 토큰 ⭐ 참조 패턴
- **위치**: `lib/core/theme/statistics_theme_tokens.dart`
- **범위**: `StatisticsScreen` 및 관련 위젯 한정
- **역할**: 통계 화면의 모든 색상/타이밍을 라이트/다크 분리하여 정의
- **특징**: `ThemeExtension<StatisticsThemeTokens>` — Material 3 공식 확장 패턴
- **사용 규칙**:
  ```dart
  // 올바른 접근
  final tokens = StatisticsThemeTokens.of(context);
  Container(color: tokens.cardBackground)

  // 잘못된 접근 (범위 위반)
  // 비통계 화면에서 StatisticsThemeTokens 사용 금지
  ```
- **왜 참조 패턴인가**:
  - `light` / `dark` const 분리 → 다크 모드 완전 지원
  - `ThemeExtension` → `Theme.of(context)`로 접근, 위젯 트리 투명
  - `copyWith` + `lerp` → 애니메이션 전환 지원
  - `of(context)` factory → null-safe 폴백

---

### 3. `HealingColorSchemes` — Cheer Me 모달 전용 팔레트
- **위치**: `lib/core/theme/healing_color_schemes.dart`
- **범위**: Cheer Me 격려 모달 전용
- **역할**: 치유/응원 맥락에 맞는 따뜻한 톤 Material 3 `ColorScheme`
- **특징**: `ColorScheme` 완전체 — `Theme(data: ThemeData(colorScheme: ...))` 래핑 사용
- **사용 규칙**:
  ```dart
  // Cheer Me 모달에서만 사용
  Theme(
    data: ThemeData(colorScheme: AppTheme.healingColorScheme()),
    child: CheerMeModal(),
  )
  ```
- **주의**: 라이트 전용 (`Brightness.light` 고정) — 다크 모드 대응 미완성

---

### 4. `CheerMeSectionPalette` — Cheer Me 섹션별 컬러
- **위치**: `lib/core/theme/cheer_me_section_palette.dart`
- **범위**: Cheer Me 화면 내 섹션 구분 색상
- **역할**: 격려 메시지 섹션 배경색 등 Cheer Me 전용 세부 색상
- **특징**: `AppColors`의 서브셋 — 모달/카드 강세 색상 관리
- **사용 규칙**: Cheer Me 관련 위젯에서만 참조

---

## 팔레트 간 관계도

```
AppColors (전역 기본)
    │
    ├── 직접 참조: 감정 색상, 상태 색상, SOS 색상
    │
    ├── StatisticsThemeTokens (통계 전용) ← ThemeExtension
    │       ├── .light  (라이트 모드 정의)
    │       └── .dark   (다크 모드 정의)
    │
    ├── HealingColorSchemes (Cheer Me 모달)
    │       ├── mutedTeal   (기본)
    │       └── pastelComfort
    │
    └── CheerMeSectionPalette (Cheer Me 섹션)
```

---

## 신규 기능 개발 시 팔레트 선택 기준

| 상황 | 선택 |
|------|------|
| 앱 전역 공통 색상 필요 | `AppColors` 추가 |
| 특정 화면 전용 라이트/다크 분리 색상 | `ThemeExtension` 패턴 신규 생성 (`StatisticsThemeTokens` 참조) |
| 모달/팝업 전용 톤 분리 | `HealingColorSchemes` 또는 별도 `ColorScheme` |
| 기존 `AppColors`에 다크 변형 필요 | `AppColors`에 `*Dark` suffix 상수 추가 (단기) 또는 `ThemeExtension` 전환 (장기) |

---

## 다크 모드 대응 현황 (2026-02-24 기준)

| 팔레트 | 다크 모드 지원 |
|--------|-------------|
| `StatisticsThemeTokens` | ✅ 완전 지원 (`.light` / `.dark`) |
| `AppTheme.darkTheme.textTheme` | ✅ TASK-UI-001에서 추가 완료 |
| `HealingColorSchemes` | ⚠️ 라이트 전용 (개선 필요) |
| `AppColors` | ❌ 테마 비인식 (하드코딩) — Phase 2 마이그레이션 대상 |
| `CheerMeSectionPalette` | ❌ 테마 비인식 (하드코딩) |

---

## 관련 파일

- 테마 진입점: `lib/core/theme/app_theme.dart`
- 컬러 마이그레이션 매핑: `.claude/rules/patterns-theme-colors.md`
- Phase 2 마이그레이션 태스크: `docs/tasks.md` TASK-UI-004~005
