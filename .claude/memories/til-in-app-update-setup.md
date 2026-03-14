# TIL: In-App Update — Setup & Core Patterns (Riverpod)

**Date**: 2026-02-02
**Session**: Flutter App Update Notifications & Clean Architecture
**Category**: State Management + Platform Integration
**Split from**: til-in-app-update-riverpod.md (Part 1/2)

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
