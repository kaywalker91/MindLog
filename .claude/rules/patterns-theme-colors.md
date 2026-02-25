---
paths: ["lib/presentation/**"]
---
# Theme Color Migration Pattern

## Color Mapping Table
| Hardcoded | Theme-aware Replacement |
|-----------|----------------------|
| `Colors.white` | `colorScheme.surface` |
| `Colors.black` | `colorScheme.onSurface` |
| `Colors.grey` | `AppColors.textSecondary` |
| `Colors.grey.shade200` | `colorScheme.surfaceContainerHighest` |
| `Colors.grey.withOpacity(0.1)` | `colorScheme.shadow.withValues(alpha: 0.05)` |
| `Colors.red` | `AppColors.error` |

## Access Pattern
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

## Widget Decomposition Threshold
- **> 200 lines**: Must split into separate widget files
- **> 50 lines per method**: Extract to private widget class
- **Display logic on Entity**: Use Extension methods (`lib/presentation/extensions/`)
  - e.g., `diary.emotionEmoji`, `diary.emotionBackgroundColor`
- **Reusable interaction**: Extract to `widgets/common/` (e.g., TappableCard)

## AppTextStyles vs textTheme 사용 가이드라인

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

> **근거**: `AppTextStyles.body`는 `AppColors.textPrimary(#2D2D3A)`로 고정되어 있어
> 다크 모드 배경(`#1E1E1E`)에서 contrast가 충분하지 않을 수 있다.
> `darkTheme.textTheme`은 `Color(0xFFE8E8F0)`으로 정의되어 WCAG AA 기준을 충족한다.

## Grep Command for Audit
```bash
# Find remaining hardcoded colors
grep -rn "Colors\." lib/presentation/ --include="*.dart"

# Find AppTextStyles direct references (to migrate to textTheme)
grep -rn "AppTextStyles\." lib/presentation/screens/ --include="*.dart"
```
