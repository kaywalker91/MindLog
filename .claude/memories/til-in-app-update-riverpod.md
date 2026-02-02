# TIL: In-App Update Implementation with Riverpod

**Date**: 2026-02-02
**Session**: Flutter App Update Notifications & Clean Architecture
**Category**: State Management + Platform Integration

---

## Executive Summary

Implemented in-app update checking using Android `in_app_update` package integrated with Riverpod + Timer.periodic. Key learning: **isRequired is a computed getter, not a constructor parameter**, and foreground-only status checking prevents unnecessary polling.

---

## 1. In-App Update Package Architecture

### Platform Support Matrix
| Platform | Support | Notes |
|----------|---------|-------|
| **Android** | ✅ Full | Play Store In-App Update API |
| **iOS** | ❌ N/A | App Store auto-updates; no manual trigger API |
| **Web** | ❌ N/A | Not applicable |

### Update Flow Types

**Flexible Update** (Recommended for features)
- User can defer installation
- Prompted at app startup, but skippable
- Safe for new features
- Used when `isRequired == false`

**Immediate Update** (Emergency only)
- Forces update before app continues
- Use for critical security patches
- Blocks app until installed
- Reserved for `isRequired == true`

---

## 2. Critical Code Pattern: UpdateCheckResult Structure

### GOTCHA: isRequired is a Getter, Not Constructor Param

```dart
// ❌ WRONG - This won't compile
UpdateCheckResult(
  updateAvailability: updateAvailability,
  minSupportedVersion: '1.2.0',
  isRequired: true,  // ERROR: isRequired is not a named parameter
  notes: 'Critical security update',
);

// ✅ CORRECT - isRequired is computed from minSupportedVersion
UpdateCheckResult(
  updateAvailability: updateAvailability,
  minSupportedVersion: '1.2.0',  // Compared against current version
  notes: 'Critical security update',
);

// Then use the getter:
bool shouldForceUpdate = result.isRequired;
```

### Why This Design?
The `in_app_update` package compares `minSupportedVersion` against the currently installed version:
- If `minSupportedVersion > currentVersion` → `isRequired = true` (immediate)
- If `minSupportedVersion <= currentVersion` → `isRequired = false` (flexible)

**Implication**: Server-side version policy drives client-side behavior.

---

## 3. Riverpod + Timer.periodic: Resource Management

### Pattern: AutoDispose + Periodic Timer

```dart
// Provider that periodically checks for updates
final updateCheckProvider = FutureProvider.autoDispose<UpdateCheckResult?>((ref) async {
  final lastCheck = ref.watch(lastUpdateCheckProvider);

  // Use Timer.periodic for repeated checks
  final timer = Timer.periodic(Duration(hours: 24), (timer) {
    // Update check logic
  });

  // Cleanup when provider is disposed
  ref.onDispose(() {
    timer.cancel();  // ← CRITICAL: prevents resource leak
  });

  return null;
});
```

### Key Principle: FutureProvider.autoDispose
- **autoDispose**: Automatically invalidates when no widgets listen
- **onDispose callback**: Cancels Timer.periodic, closes streams, etc.
- **Without autoDispose**: Timer runs indefinitely even when app is backgrounded

---

## 4. Timestamp Logic: 24-Hour Check Interval

### Implementation Pattern

```dart
// Store last check in SharedPreferences
final prefs = await SharedPreferences.getInstance();

// Save current timestamp (milliseconds since epoch)
await prefs.setInt('lastUpdateCheck', DateTime.now().millisecondsSinceEpoch);

// Check if 24 hours have passed
final lastCheckMs = prefs.getInt('lastUpdateCheck') ?? 0;
final now = DateTime.now().millisecondsSinceEpoch;
final elapsedMs = now - lastCheckMs;
final elapsed24Hours = elapsedMs >= (24 * 60 * 60 * 1000);

if (elapsed24Hours) {
  // Perform update check
}
```

### Best Practice
- Use `millisecondsSinceEpoch` (not seconds) for consistency with Dart ecosystem
- Always provide null-coalescing default (`?? 0`) for first-time installs
- Store as `int` in SharedPreferences (more reliable than String)

---

## 5. Foreground-Only Status Check

### Why This Matters
In-app updates only work when app is in foreground:
- Backgrounded: User won't see update prompt
- Killed: Timer won't fire

### Implementation

```dart
final inAppUpdateProvider = FutureProvider.autoDispose<void>((ref) async {
  // Check foreground status before initiating update
  final lifecycle = ref.watch(appLifecycleProvider);

  if (lifecycle != AppLifecycle.resumed) {
    return;  // Skip if not in foreground
  }

  // Proceed with update check/download
});
```

### Integration with go_router
```dart
// Listen to app state in main MaterialApp
return MaterialApp.router(
  routerConfig: router,
  // Use WidgetsBinding to detect lifecycle changes
  builder: (context, child) {
    ref.listen(appLifecycleProvider, (previous, next) {
      if (next == AppLifecycle.resumed) {
        ref.invalidate(updateCheckProvider);  // Re-check when resumed
      }
    });
    return child ?? const Scaffold();
  },
);
```

---

## 6. Clean Architecture Integration

### Layer Distribution

**Presentation Layer** (`presentation/`)
- UpdateNotificationWidget
- UpdateDialogs (flexible vs immediate)
- SnackBar feedback

**Domain Layer** (`domain/`)
- UpdateRepository interface
- UpdateCheckUseCase
- UpdateStatus entity

**Data Layer** (`data/`)
- InAppUpdateRepositoryImpl
- SharedPreferences adapter
- RemoteVersionSource (API)

### Example Repository Interface

```dart
// lib/domain/repositories/update_repository.dart
abstract class UpdateRepository {
  Future<UpdateCheckResult> checkForUpdates();
  Future<void> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
}

// lib/data/repositories/in_app_update_repository_impl.dart
class InAppUpdateRepositoryImpl implements UpdateRepository {
  final _inAppUpdate = InAppUpdate.instance;

  @override
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      final info = await _inAppUpdate.checkForUpdate();
      return UpdateCheckResult(
        updateAvailability: info.updateAvailability,
        minSupportedVersion: info.minSupportedVersion,
        notes: info.releaseNotes ?? '',
      );
    } catch (e) {
      throw UpdateCheckFailure(message: e.toString());
    }
  }
}
```

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

- `/til-riverpod-multilayer-invalidation.md` — Multi-level provider dependency chains
- `/til-gorouter-popscope.md` — Navigation lifecycle with PopScope
- `/til-firebase-timezone-handling.md` — Time-sensitive operations in distributed systems

---

**Remember**: In in-app updates, the server version policy is law. Keep it synchronized with backend `/api/version` endpoint.
