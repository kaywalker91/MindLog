# TIL: In-App Update — Pitfalls, Testing & Key Insights (Riverpod)

**Date**: 2026-02-02
**Session**: Flutter App Update Notifications & Clean Architecture
**Split from**: til-in-app-update-riverpod.md (Part 2/2)

---

## 7. Common Pitfalls & Solutions

### Pitfall 1: Timer Runs in Background
**Problem**: Timer fires even when app is backgrounded, wasting battery
**Solution**: Use foreground lifecycle check + autoDispose

### Pitfall 2: UpdateCheckResult Constructor Error
**Problem**: Attempting to pass `isRequired` as parameter
**Solution**: Understand that `isRequired` is a computed getter based on version comparison

### Pitfall 3: SharedPreferences Race Conditions
**Problem**: Multiple check calls within same second
**Solution**: Add debounce or use `once` flag

```dart
bool _checkingUpdate = false;

Future<void> checkUpdates() async {
  if (_checkingUpdate) return;
  _checkingUpdate = true;
  try {
    // Check logic
  } finally {
    _checkingUpdate = false;
  }
}
```

### Pitfall 4: Provider Invalidation Chain
**Problem**: Updating one provider doesn't cascade to dependents
**Solution**: Use `invalidate()` with explicit dependency tracking

```dart
// When timestamp changes, invalidate update check
ref.watch(lastUpdateCheckProvider).whenData((_) {
  ref.invalidate(updateCheckProvider);
});
```

---

## 8. Testing Considerations

### Unit Test Template
```dart
test('should determine isRequired based on minSupportedVersion', () {
  // Assume current version is 1.4.0
  final result = UpdateCheckResult(
    updateAvailability: UpdateAvailability.updateAvailable,
    minSupportedVersion: '1.5.0',  // Higher than current
    notes: 'Critical update',
  );

  expect(result.isRequired, true);  // ✅ isRequired is computed
});

test('should skip update check if not in foreground', () async {
  // Mock lifecycle provider
  final lifecycle = ValueNotifier(AppLifecycle.paused);

  // Verify update check is skipped
  expect(() => checkForUpdates(), returnsNull);
});
```

---

## 9. Key Insights for Other Developers

### 1. Version Policy Drives UX
Server-side `minSupportedVersion` is the single source of truth for update urgency. No client-side hardcoding.

### 2. Async/Resource Lifecycle Matters
With Riverpod + Timer, always use:
- `FutureProvider.autoDispose` for periodic operations
- `ref.onDispose()` to clean up timers
- Lifecycle listeners to avoid background polling

### 3. Platform Differences Are Significant
In-app updates are Android-specific. Plan iOS strategy separately (check App Store version, deep linking to app page).

### 4. Timestamp Precision
Use `millisecondsSinceEpoch` consistently. Mixing seconds/milliseconds causes subtle bugs.

---

## 10. Reference Code Snippets

### Complete Minimal Example
```dart
// Provider with 24-hour check interval
final updateCheckProvider = FutureProvider.autoDispose<UpdateCheckResult?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastCheckMs = prefs.getInt('lastUpdateCheck') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  if (now - lastCheckMs < (24 * 60 * 60 * 1000)) {
    return null;  // Too recent, skip
  }

  // Perform check
  final repository = ref.watch(updateRepositoryProvider);
  final result = await repository.checkForUpdates();

  // Save timestamp
  await prefs.setInt('lastUpdateCheck', now);

  // Cleanup on dispose
  ref.onDispose(() {
    print('Update check provider disposed');
  });

  return result;
});
```

---

## 11. Next Steps for MindLog

1. ✅ Integrate in-app updates with existing notification system
2. ✅ Add version endpoint to backend (returns `minSupportedVersion`)
3. ✅ Test on Android emulator with Play Services
4. ⏳ Plan iOS App Store redirect (not in-app)
5. ⏳ Add analytics tracking for update flow

---

## Related TILs

- `til-provider-invalidation-chain-core.md` — Multi-level provider dependency chains
- `til-defensive-programming-problem.md` — Timing race conditions in provider initialization

**Remember**: In in-app updates, the server version policy is law. Keep it synchronized with backend `/api/version` endpoint.
