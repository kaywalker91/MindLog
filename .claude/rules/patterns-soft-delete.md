---
paths: ["lib/presentation/providers/**", "lib/presentation/screens/**"]
---
# Soft Delete + Undo Pattern

## Architecture
```
User swipes → softDelete() → UI removes item → 5s Timer starts
                                                    ├─ Timer fires → hardDelete (DB)
                                                    └─ User taps "되돌리기" → cancelDelete() → restore item
```

## Controller Implementation
```dart
class _PendingDeletion {
  final Diary diary;
  final int originalIndex;
  final Timer timer;
  _PendingDeletion({required this.diary, required this.originalIndex, required this.timer});
}

// In AsyncNotifier:
final Map<String, _PendingDeletion> _pendingDeletions = {};

Future<void> softDelete(Diary diary) async {
  final currentList = state.valueOrNull ?? [];
  final index = currentList.indexWhere((d) => d.id == diary.id);
  if (index == -1) return;

  // Remove from UI immediately
  final updated = [...currentList]..removeAt(index);
  state = AsyncData(updated);

  // Schedule hard delete
  final timer = Timer(const Duration(seconds: 5), () => _executeDelete(diary.id));
  _pendingDeletions[diary.id] = _PendingDeletion(diary: diary, originalIndex: index, timer: timer);
}

Future<void> cancelDelete(String diaryId) async {
  final pending = _pendingDeletions.remove(diaryId);
  if (pending == null) return;
  pending.timer.cancel();

  // Restore to original position
  final currentList = [...(state.valueOrNull ?? [])];
  final insertAt = pending.originalIndex.clamp(0, currentList.length);
  currentList.insert(insertAt, pending.diary);
  state = AsyncData(currentList);
}
```

## UI (SnackBar with Undo)
```dart
ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
    content: const Text('일기가 삭제되었습니다'),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: '되돌리기',
      onPressed: () => controller.cancelDelete(diary.id),
    ),
  ));
```

## Key Points
- Timer duration (5s) must match SnackBar duration
- `hideCurrentSnackBar()` before showing new one (prevents stacking)
- `clamp()` the restore index (list may have changed)
- Dismissible `onDismissed` triggers softDelete, NOT hardDelete
