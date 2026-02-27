# MindLog Design Guidelines

> Primary color: sky blue (#87CEEB). 이전 퍼플(#6B5B95)은 완전 폐기.

---

## Color Palette

### Primary 계열 (세 토큰의 역할 분리)

| 토큰 | Hex | 이름 | 역할 |
|------|-----|------|------|
| `AppColors.primary` | `#87CEEB` | 파스텔 하늘 | 아이콘, 강조선(Accent Stripe), 브랜드 터치포인트 |
| `AppColors.primaryLight` | `#B3E5FC` | 베이비 블루 | hover 상태, 소프트 강조, 배경 틴트 |
| `AppColors.primaryDark` | `#4A90B8` | 아주르 블루 | 키워드 텍스트, 링크 텍스트 (WCAG AA ≈3.8:1 on white) |
| `AppTheme.primaryColor` | `#7EC8E3` | — | AppBar 배경, 버튼, ColorScheme 시드 — theme 경유 참조만 허용 |

**혼용 방지 규칙:**
- `AppColors.primary` (#87CEEB): 텍스트 색상으로 직접 사용 금지 (배경 대비 부족)
- `AppColors.primaryDark` (#4A90B8): 텍스트 색상으로만 사용 (아이콘/강조선 용도 금지)
- `AppTheme.primaryColor` (#7EC8E3): 위젯 `color:` 속성에 직접 참조 금지 — 반드시 theme 경유

### 감정 색상

| 토큰 | Hex | 설명 |
|------|-----|------|
| `AppColors.sentimentVeryPositive` | `#FFD54F` | 매우 긍정 (앰버 옐로) |
| `AppColors.sentimentPositive` | — | `AppColors.getSentimentColor(score)` 경유 |
| `AppColors.sentimentNeutral` | — | `AppColors.getSentimentColor(score)` 경유 |
| `AppColors.sentimentNegative` | — | `AppColors.getSentimentColor(score)` 경유 |
| `AppColors.sentimentVeryNegative` | `#5C6BC0` | 매우 부정 (인디고) |

감정 색상은 `AppColors.getSentimentColor(score)` 메서드를 통해서만 참조.
점수별 직접 색상 코드 하드코딩 금지.

### 기능별 액센트

| 토큰 | Hex | 설명 |
|------|-----|------|
| `AppColors.cheerMeAccent` | `#FFA726` | Cheer Me 앰버 — 응원/독려 UX |
| `AppColors.mindcareAccent` | `#26A69A` | 마음케어 틸 — 케어/안정 UX |
| `AppColors.statsPrimaryDark` | `#5BA4C9` | 통계 탭 진한 하늘 (`StatisticsThemeTokens` 경유) |

---

## Quick Token Table

| 필요한 것 | 올바른 토큰 |
|-----------|-----------|
| 카드/화면 배경 | `colorScheme.surface` |
| 브랜드 액센트 (아이콘, 강조선) | `AppColors.primary` (#87CEEB) |
| 키워드/링크 텍스트 | `AppColors.primaryDark` (#4A90B8) |
| AppBar 배경 | theme 경유 (AppTheme.primaryColor 직접 참조 금지) |
| 본문 텍스트 | `colorScheme.onSurface` |
| 보조 텍스트 | `colorScheme.onSurfaceVariant` |
| 오버레이 스크림 | `colorScheme.scrim.withValues(alpha: 0.5)` |
| 감정 색상 | `AppColors.getSentimentColor(score)` |
| 통계 탭 색상 | `StatisticsThemeTokens.of(context).*` |
| hover/소프트 강조 | `AppColors.primaryLight` (#B3E5FC) |

---

## Typography

### 원칙
- `Theme.of(context).textTheme.*` 우선 — 화면 내 일반 텍스트의 기본
- `AppTextStyles.*` 직접 참조는 도메인 특화 스타일에만 허용 (감정 메시지, 키워드 등)

### AppTextStyles 토큰

| 토큰 | Size | Weight | 비고 |
|------|------|--------|------|
| `headline` | 24 | bold | 주요 화면 제목 |
| `title` | 20 | w600 | 섹션 제목 |
| `subtitle` | 16 | w500 | 부제목 |
| `body` | 16 | normal | 본문 |
| `bodySmall` | 14 | normal | 보조 본문 |
| `hint` | 14 | normal | 힌트/플레이스홀더 |
| `button` | 16 | w600 | 버튼 레이블 |
| `label` | 12 | w500 | 태그/라벨 |
| `empathyMessage` | 18 | w400/italic | AI 공감 메시지 |
| `keyword` | 14 | w500 | 키워드 — color: `AppColors.primaryDark` |

### Supplemental 토큰

| 토큰 | Size | Weight | 비고 |
|------|------|--------|------|
| `tooltipText` | 12 | normal | 툴팁 |
| `statValue` | 28 | bold | 통계 수치 강조 |
| `calendarDate` | 11 | w500 | 캘린더 날짜 셀 |
| `chartLabel` | 10 | normal | 차트 축/레이블 |

---

## Component Patterns

### 카드
```dart
Card(
  color: colorScheme.surface,
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: ...,
)
```

### 버튼
- 배경: `AppTheme.primaryColor` (theme 경유, 직접 참조 금지)
- 전경: `AppColors.onDarkSurface` (또는 `colorScheme.onPrimary`)

### 바텀시트
- Snap points: `[0.5, 0.75, 0.95]`
- 열릴 때 햅틱: `HapticFeedback.mediumImpact()`
- 드래그 핸들: `Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))`

### Accent Stripe
```dart
Container(
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(color: AppColors.primary, width: 4),
    ),
  ),
  child: ...,
)
// IntrinsicHeight 사용 금지 — RenderFlex overflow 원인
```

---

## 다크모드 대응 규칙

### 강제 사용
| 용도 | 올바른 토큰 |
|------|-----------|
| Surface/배경 | `colorScheme.surface` |
| 주요 텍스트 | `colorScheme.onSurface` |
| 보조 텍스트 | `colorScheme.onSurfaceVariant` |
| 오버레이 스크림 | `colorScheme.scrim.withValues(alpha: 0.5)` |
| 구분선 | `colorScheme.outlineVariant` |

### 예외 허용 (`// design-ok` 주석 필수)
```dart
// design-ok: alpha mask for BlendMode.dstIn gradient
color: Colors.black,
```
`// design-ok: [이유]` 주석 없는 `Colors.white` / `Colors.black` 직접 사용은 `/color-migrate` 대상.

### Theme-aware 색상 매핑 (마이그레이션 참조)

| 구 패턴 | 올바른 패턴 |
|---------|-----------|
| `Colors.black87` | `colorScheme.scrim.withValues(alpha: 0.87)` |
| `Colors.black54` | `colorScheme.shadow.withValues(alpha: 0.54)` |
| `Colors.white` | `colorScheme.onSurface` 또는 `colorScheme.onPrimary` |
| `Colors.grey[900]` | `colorScheme.surfaceContainerLowest` |
| `Colors.grey[600]` | `colorScheme.onSurfaceVariant` |

---

## 금지 패턴

```dart
// ❌ 금지 — 다크모드 깨짐
color: Colors.white
color: Colors.black

// ❌ 금지 — 토큰 없는 인라인 hex
color: Color(0xFF87CEEB)

// ❌ 금지 — 텍스트에 primary 사용 (대비 부족)
style: TextStyle(color: AppColors.primary)

// ❌ 금지 — primaryColor 직접 위젯 참조
color: AppTheme.primaryColor

// ✅ 올바른 패턴
color: colorScheme.surface
color: colorScheme.scrim.withValues(alpha: 0.5)
style: TextStyle(color: AppColors.primaryDark)   // 텍스트
color: AppColors.primary                          // 아이콘/강조선

// ✅ 정당한 예외
color: Colors.black  // design-ok: BlendMode.dstIn alpha mask
```

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/core/theme/app_colors.dart` | 색상 토큰 정의 |
| `lib/core/theme/app_text_styles.dart` | 텍스트 스타일 토큰 |
| `lib/core/theme/app_theme.dart` | ThemeData, primaryColor, ColorScheme 시드 |
| `lib/presentation/statistics/theme/statistics_theme_tokens.dart` | 통계 탭 전용 토큰 |
| `.claude/rules/design-token-rules.md` | AI 컨텍스트용 빠른 참조 |
| `memory/a11y-backlog.md` | 접근성 Sprint 3 백로그 |
