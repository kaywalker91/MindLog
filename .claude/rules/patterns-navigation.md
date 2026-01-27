---
paths: ["lib/presentation/**"]
---
# Navigation Patterns (go_router)

## Route Types
| Context | Method | Example |
|---------|--------|---------|
| Root transition (replace stack) | `context.go()` | splash → home |
| Sub-screen (push to stack) | `context.push()` | list → detail |
| Back navigation (page) | `context.pop()` | detail → list |
| Dialog/BottomSheet dismiss | `context.pop()` or `Navigator.pop()` | dialog close |

## Critical Rule
- `showDialog()` / `showModalBottomSheet()` use **overlay routes**
- These MUST use `context.pop()` — never `context.go()` (which replaces the whole stack)
- go_router's `context.pop()` works correctly for both page routes and overlay routes

## Extension Pattern (app_router.dart)
```dart
extension AppRouterExtension on BuildContext {
  void goHome() => go(AppRoutes.home);
  void goNewDiary() => push(AppRoutes.newDiary);
  void goDiaryDetail(Diary diary) => push(AppRoutes.diaryDetail(diary.id), extra: diary);
}
```

## Navigator.push Migration Checklist
1. Remove direct screen imports (e.g., `import 'diary_screen.dart'`)
2. Add `import '../router/app_router.dart'`
3. Replace `Navigator.push(MaterialPageRoute(...))` → `context.push()`
4. Replace `Navigator.pop()` → `context.pop()`
5. Replace `Navigator.pushAndRemoveUntil()` → `context.go()`
