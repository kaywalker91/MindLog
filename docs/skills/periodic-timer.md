# Periodic Timer Skill

Generate a periodic background task that runs at fixed intervals with automatic resource cleanup.

## When to Use

Use this skill when you need:
- Background polling (e.g., check for updates every 6 hours)
- Periodic synchronization (e.g., sync data every 5 minutes)
- Health checks (e.g., verify network connection every 30 seconds)
- Scheduled housekeeping (e.g., cleanup old cache daily)

**Key requirement:** The task runs **only while app is in foreground** (MainScreen active).

## Pattern Overview

### What It Does

1. **Starts a periodic timer** with fixed interval (e.g., 6 hours)
2. **Executes action callback** repeatedly on schedule
3. **Cleans up resources** automatically when app closes or provider disposes
4. **Manages disposal state** to prevent running after disposed

### Architecture Flow

```
MainScreen build()
  ↓
ref.watch(periodicTimerProvider)  // Triggers provider creation
  ↓
Provider.autoDispose<PeriodicTimer>
  ↓
UpdateCheckTimer instance created
  ↓
ref.onDispose(() => timer.dispose())  // Register cleanup
  ↓
timer.start()  // Called manually in MainScreen
  ↓
Timer.periodic(interval, _performCheck)
  ↓
App foreground duration
  ↓
App goes background/closes
  ↓
Provider auto-disposed
  ↓
timer.dispose() called
  ↓
Timer.cancel() + cleanup flag set
```

## Implementation Steps

### Step 1: Create Timer Wrapper Class

Create `lib/presentation/providers/{action}_{entity}_timer_provider.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Periodic background task execution interval
const Duration _{action}{Entity}Interval = Duration(hours: 6);

/// {Action} {Entity} periodic task manager
///
/// - Runs {action} on {entity} at fixed intervals
/// - App foreground only (MainScreen controls lifecycle)
/// - Automatic resource cleanup on app close
class {Action}{Entity}Timer {
  final Ref _ref;
  Timer? _timer;
  bool _isDisposed = false;

  {Action}{Entity}Timer(this._ref);

  /// Start periodic {action} timer
  void start() {
    if (_isDisposed) return;

    _timer?.cancel();
    _timer = Timer.periodic(_{action}{Entity}Interval, (_) => _perform());

    if (kDebugMode) {
      debugPrint(
        '[{Action}{Entity}Timer] Started with interval: $_{action}{Entity}Interval',
      );
    }
  }

  /// Stop periodic timer (can be restarted with start())
  void stop() {
    _timer?.cancel();
    _timer = null;

    if (kDebugMode) {
      debugPrint('[{Action}{Entity}Timer] Stopped');
    }
  }

  /// Clean up resources (called on dispose)
  void dispose() {
    _isDisposed = true;
    stop();
  }

  Future<void> _perform() async {
    if (_isDisposed) return;

    try {
      // TODO: Implement actual action
      // Example: await _ref.read(someProvider.notifier).action();

      if (kDebugMode) {
        debugPrint('[{Action}{Entity}Timer] Periodic {action} completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[{Action}{Entity}Timer] Periodic {action} failed: $e');
      }
    }
  }
}

/// Periodic {action} {entity} provider
final {action}{entity}TimerProvider = Provider.autoDispose<{Action}{Entity}Timer>((ref) {
  final timer = {Action}{Entity}Timer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

**Example for update check:**

```dart
/// Periodic background update check interval (6 hours)
const Duration _updateCheckInterval = Duration(hours: 6);

/// Periodic update check timer manager
///
/// - Runs update check every 6 hours
/// - App foreground only
/// - Auto cleanup on app close
class UpdateCheckTimer {
  final Ref _ref;
  Timer? _timer;
  bool _isDisposed = false;

  UpdateCheckTimer(this._ref);

  void start() {
    if (_isDisposed) return;

    _timer?.cancel();
    _timer = Timer.periodic(_updateCheckInterval, (_) => _performCheck());

    if (kDebugMode) {
      debugPrint(
        '[UpdateCheckTimer] Started with interval: $_updateCheckInterval',
      );
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;

    if (kDebugMode) {
      debugPrint('[UpdateCheckTimer] Stopped');
    }
  }

  void dispose() {
    _isDisposed = true;
    stop();
  }

  Future<void> _performCheck() async {
    if (_isDisposed) return;

    try {
      final appInfo = await _ref.read(appInfoProvider.future);
      await _ref.read(updateStateProvider.notifier).check(appInfo.version);

      if (kDebugMode) {
        debugPrint(
          '[UpdateCheckTimer] Periodic check completed for v${appInfo.version}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateCheckTimer] Periodic check failed: $e');
      }
    }
  }
}

final updateCheckTimerProvider = Provider.autoDispose<UpdateCheckTimer>((ref) {
  final timer = UpdateCheckTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

### Step 2: Add to Provider Exports

In `lib/presentation/providers/providers.dart`, add export:

```dart
export '{action}_{entity}_timer_provider.dart';
```

### Step 3: Initialize in MainScreen

In `lib/presentation/screens/main_screen.dart`, add timer initialization:

```dart
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize periodic tasks
    ref.watch(updateCheckTimerProvider).start();

    // Rest of build...
    return Scaffold(
      body: Center(
        child: Text('Main Screen'),
      ),
    );
  }
}
```

**Important:** Call `.start()` only once per build cycle.
- `ref.watch()` is safe to call repeatedly in build
- `.start()` checks `_isDisposed` and cancels previous timer before creating new one

### Step 4: Add to Providers List

In `lib/presentation/providers/providers.dart`, ensure timer provider is accessible:

```dart
// Already exported in Step 2
export 'update_check_timer_provider.dart';
```

### Step 5: Create Unit Tests

In `test/presentation/providers/{action}_{entity}_timer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('{Action}{Entity}Timer', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('start creates periodic timer', () async {
      final timer = {Action}{Entity}Timer(mockRef);

      timer.start();
      expect(timer._timer, isNotNull);

      timer.dispose();
    });

    test('stop cancels timer', () async {
      final timer = {Action}{Entity}Timer(mockRef);

      timer.start();
      final createdTimer = timer._timer;

      timer.stop();
      expect(timer._timer, isNull);

      timer.dispose();
    });

    test('dispose prevents further execution', () async {
      final timer = {Action}{Entity}Timer(mockRef);

      timer.start();
      timer.dispose();

      // Verify _isDisposed flag is set
      expect(timer._isDisposed, true);
    });

    test('start is idempotent (no side effects if called multiple times)', () async {
      final timer = {Action}{Entity}Timer(mockRef);

      timer.start();
      final firstTimer = timer._timer;

      timer.start();
      final secondTimer = timer._timer;

      // Should be same timer instance (not recreated)
      expect(secondTimer, firstTimer);

      timer.dispose();
    });
  });

  group('{action}{entity}TimerProvider', () {
    test('provider creates timer instance', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TestWidget(),
        ),
      );

      // Timer should be created and accessible
      expect(find.byType(TestWidget), findsOneWidget);
    });

    test('provider auto-disposes on scope cleanup', (WidgetTester tester) async {
      final container = ProviderContainer();

      final timer = container.read({action}{entity}TimerProvider);
      expect(timer, isNotNull);

      container.dispose();
      // Timer.dispose() should have been called
    });
  });
}

// Mock classes
class MockRef extends Mock implements Ref {}

// Test widget
class TestWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch({action}{entity}TimerProvider);
    return const SizedBox();
  }
}
```

## Usage Examples

### Example 1: Periodic Update Check (6 hours)

**File:** `lib/presentation/providers/update_check_timer_provider.dart`

```dart
const Duration _updateCheckInterval = Duration(hours: 6);

class UpdateCheckTimer {
  // ... implementation ...

  Future<void> _performCheck() async {
    if (_isDisposed) return;
    try {
      final appInfo = await _ref.read(appInfoProvider.future);
      await _ref.read(updateStateProvider.notifier).check(appInfo.version);
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }
}

final updateCheckTimerProvider = Provider.autoDispose<UpdateCheckTimer>((ref) {
  final timer = UpdateCheckTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

**Initialization in MainScreen:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.watch(updateCheckTimerProvider).start();  // Start checking every 6h
  return Scaffold(...);
}
```

### Example 2: Periodic Data Sync (5 minutes)

```dart
const Duration _syncInterval = Duration(minutes: 5);

class SyncCheckTimer {
  final Ref _ref;
  Timer? _timer;
  bool _isDisposed = false;

  SyncCheckTimer(this._ref);

  void start() {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer.periodic(_syncInterval, (_) => _performSync());
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
  }

  Future<void> _performSync() async {
    if (_isDisposed) return;
    try {
      await _ref.read(localRemoteSyncProvider.notifier).sync();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }
}

final syncCheckTimerProvider = Provider.autoDispose<SyncCheckTimer>((ref) {
  final timer = SyncCheckTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

### Example 3: Network Connectivity Check (30 seconds)

```dart
const Duration _networkCheckInterval = Duration(seconds: 30);

class NetworkStatusTimer {
  final Ref _ref;
  Timer? _timer;
  bool _isDisposed = false;

  NetworkStatusTimer(this._ref);

  void start() {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer.periodic(_networkCheckInterval, (_) => _checkNetwork());
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
  }

  Future<void> _checkNetwork() async {
    if (_isDisposed) return;
    try {
      final connectivityService = _ref.read(connectivityServiceProvider);
      final isOnline = await connectivityService.isOnline();

      _ref.read(networkStatusProvider.notifier).update(isOnline);
    } catch (e) {
      debugPrint('Network check failed: $e');
    }
  }
}

final networkStatusTimerProvider = Provider.autoDispose<NetworkStatusTimer>((ref) {
  final timer = NetworkStatusTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

## Validation Checklist

- [ ] Timer wrapper class created in `lib/presentation/providers/`
- [ ] Timer class has `start()`, `stop()`, `dispose()` methods
- [ ] Timer uses `Timer.periodic()` with correct interval
- [ ] Timer checks `_isDisposed` flag before executing action
- [ ] `_isDisposed` flag is set to `true` in `dispose()`
- [ ] Provider uses `Provider.autoDispose`
- [ ] `ref.onDispose(() => timer.dispose())` is called
- [ ] Timer initialization added to `MainScreen.build()`
- [ ] Export added to `lib/presentation/providers/providers.dart`
- [ ] Unit tests created (4+ test cases)
- [ ] Debug logging present with `[ClassName]` prefix
- [ ] All tests pass: `flutter test`
- [ ] No lint violations: `flutter analyze`

## Common Variations

### Variation 1: Manual Start/Stop Toggle

```dart
class PeriodicTimer {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  void start() {
    if (_isDisposed || _isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _perform());
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }
}

// In UI
FilledButton(
  onPressed: () => ref.read(timerProvider).start(),
  child: const Text('Start'),
),
FilledButton(
  onPressed: () => ref.read(timerProvider).stop(),
  child: const Text('Stop'),
),
```

### Variation 2: Adjustable Interval

```dart
class PeriodicTimer {
  Duration _interval;

  PeriodicTimer(this._ref, {Duration interval = const Duration(hours: 1)})
    : _interval = interval;

  void updateInterval(Duration newInterval) {
    _interval = newInterval;
    stop();
    if (_isRunning) start();
  }

  void start() {
    _timer = Timer.periodic(_interval, (_) => _perform());
  }
}

// Usage
ref.read(timerProvider).updateInterval(Duration(minutes: 30));
```

### Variation 3: Exponential Backoff on Failure

```dart
class PeriodicTimer {
  int _failureCount = 0;
  static const maxBackoffMinutes = 60;

  Duration get _currentInterval {
    final backoffMultiplier = pow(2, _failureCount.clamp(0, 5)).toInt();
    final backoffMinutes = (baseInterval.inMinutes * backoffMultiplier)
        .clamp(1, maxBackoffMinutes);
    return Duration(minutes: backoffMinutes);
  }

  Future<void> _perform() async {
    try {
      await _action();
      _failureCount = 0;  // Reset on success
    } catch (e) {
      _failureCount++;
      // Next interval will be longer
    }
  }
}
```

### Variation 4: Conditional Execution

```dart
class PeriodicTimer {
  Future<void> _perform() async {
    if (_isDisposed) return;

    // Only execute if condition met
    final shouldExecute = await _ref.read(someConditionProvider);
    if (!shouldExecute) return;

    try {
      await _action();
    } catch (e) {
      debugPrint('Action failed: $e');
    }
  }
}
```

## Performance Notes

- **Memory:** Timer uses minimal memory (~1KB per timer instance)
- **CPU:** Callback executes only at scheduled interval, no constant polling
- **Battery:** Foreground-only execution minimizes battery drain
- **Network:** Ensure action has timeout to prevent hang if network unavailable

## Related Patterns

- **Suppress Pattern**: Combine with suppress-pattern for "don't check again for 24h"
- **Async Notifier**: Use `AsyncNotifierProvider` for result-based timing
- **Lifecycle**: `ref.onDispose` ensures cleanup even if provider not explicitly invalidated
- **Error Handling**: Wrap action in try/catch to prevent exception propagation

## Troubleshooting

### Timer not executing

Check:
1. Is MainScreen.build() being called? (timer is watched, not read)
2. Is `.start()` being called? (watch alone doesn't start)
3. Is app in foreground? (autoDispose triggers on background)

### Timer continues after app closes

Check:
1. Is `dispose()` being called? (check Logcat for disposal logs)
2. Is `_isDisposed` flag being checked? (prevents execution after dispose)

### Multiple timers created

Check:
1. Are you calling `.start()` multiple times? (first call cancels previous)
2. Are you reading provider instead of watching? (read doesn't dispose)

