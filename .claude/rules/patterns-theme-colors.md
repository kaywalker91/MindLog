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

## Grep Command for Audit
```bash
# Find remaining hardcoded colors
grep -rn "Colors\." lib/presentation/ --include="*.dart"
```
