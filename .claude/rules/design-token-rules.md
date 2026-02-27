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
