---
paths: ["lib/presentation/**", "lib/core/theme/**"]
description: Design token rules — quick reference for UI work
---

# Design Token Rules

Full reference: `docs/design-guidelines.md`

## 어떤 색상 토큰을 써야 하나? (5-step decision)

1. **배경/Surface인가?** → `colorScheme.surface`
2. **텍스트인가?**
   - 본문/보조 → `colorScheme.onSurface` / `colorScheme.onSurfaceVariant`
   - 키워드/링크 → `AppColors.primaryDark` (#4A90B8)
3. **브랜드 강조(아이콘, 강조선)인가?** → `AppColors.primary` (#87CEEB)
4. **감정 색상인가?** → `AppColors.getSentimentColor(score)` (직접 hex 금지)
5. **오버레이/스크림인가?** → `colorScheme.scrim.withValues(alpha: 0.5)` (Colors.black 금지)

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

## 올바른 vs 잘못된 패턴

```dart
// ❌ Colors.white/black 직접 사용
color: Colors.white
color: Colors.black87

// ✅ theme-aware 대체
color: colorScheme.onSurface
color: colorScheme.scrim.withValues(alpha: 0.87)

// ❌ 텍스트에 primary 사용 (대비 부족 — #87CEEB on white = 1.7:1)
style: TextStyle(color: AppColors.primary)

// ✅ 텍스트용 primaryDark 사용 (WCAG AA — #4A90B8 on white ≈ 3.8:1)
style: TextStyle(color: AppColors.primaryDark)

// ❌ primaryColor 직접 위젯 참조
color: AppTheme.primaryColor

// ✅ 아이콘/강조선에만 primary 직접 사용
color: AppColors.primary  // 아이콘, Accent Stripe BorderSide

// ❌ 인라인 hex
color: Color(0xFF87CEEB)

// ✅ 토큰 참조
color: AppColors.primary
```

## `// design-ok` 이스케이프 규칙

`Colors.white` / `Colors.black`이 기술적으로 불가피한 경우 (BlendMode, 시스템 API 등):

```dart
color: Colors.black  // design-ok: BlendMode.dstIn alpha mask
```

`// design-ok: [이유]` 주석 없는 직접 사용은 `/color-migrate` 또는 `/design-audit` 대상으로 분류됨.

---

## Color Migration Table (Hardcoded → Theme-aware)

| Hardcoded | Theme-aware Replacement |
|-----------|----------------------|
| `Colors.white` | `colorScheme.surface` |
| `Colors.black` | `colorScheme.onSurface` |
| `Colors.grey` | `AppColors.textSecondary` |
| `Colors.grey.shade200` | `colorScheme.surfaceContainerHighest` |
| `Colors.grey.withOpacity(0.1)` | `colorScheme.shadow.withValues(alpha: 0.05)` |
| `Colors.red` | `AppColors.error` |

### Access Pattern
```dart
final colorScheme = Theme.of(context).colorScheme;

// Surface colors
colorScheme.surface          // card/dialog background
colorScheme.surfaceContainerHighest  // elevated surface (cancel button bg)
colorScheme.shadow           // shadow color (use with low alpha)

// Text colors (from AppColors constants)
AppColors.textPrimary
AppColors.textSecondary
AppColors.textHint
```

---

## Widget Decomposition Threshold

- **> 200 lines**: Must split into separate widget files
- **> 50 lines per method**: Extract to private widget class
- **Display logic on Entity**: Use Extension methods (`lib/presentation/extensions/`)
  - e.g., `diary.emotionEmoji`, `diary.emotionBackgroundColor`
- **Reusable interaction**: Extract to `widgets/common/` (e.g., TappableCard)

---

## AppTextStyles vs textTheme 가이드

`AppTextStyles` const는 유지되지만, **화면(Screen/Widget)에서는 `textTheme` 경유를 우선**한다.

| 상황 | 권장 방식 |
|------|----------|
| 화면/위젯 내 일반 텍스트 | `Theme.of(context).textTheme.bodyMedium` |
| 제목 텍스트 | `Theme.of(context).textTheme.titleMedium` |
| 보조 텍스트 | `Theme.of(context).textTheme.bodySmall` |
| 감정 키워드 등 도메인 특화 스타일 | `AppTextStyles.keyword` (직접 참조 허용) |
| 테마 무관 고정 스타일 | `AppTextStyles.*` (직접 참조 허용) |

```dart
// 권장: textTheme 경유 (다크 모드 자동 대응)
Text('내용', style: Theme.of(context).textTheme.bodyMedium)

// 허용: 도메인 특화 스타일
Text('감정키워드', style: AppTextStyles.keyword)

// 지양: 하드코딩 색상 (Dark-on-Dark 문제)
Text('내용', style: AppTextStyles.body) // AppColors.textPrimary 고정 → 다크 모드 버그
```

> `AppTextStyles.body`는 `AppColors.textPrimary(#2D2D3A)`로 고정 → 다크 모드에서 contrast 부족 가능.
> `darkTheme.textTheme`은 `Color(0xFFE8E8F0)` → WCAG AA 기준 충족.

---

## Audit Commands

```bash
# Find remaining hardcoded colors
grep -rn "Colors\." lib/presentation/ --include="*.dart"

# Find AppTextStyles direct references (to migrate to textTheme)
grep -rn "AppTextStyles\." lib/presentation/screens/ --include="*.dart"
```
