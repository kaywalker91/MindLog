# Suppress Pattern Skill

Generate time-based suppression logic for features like "dismiss for 24 hours", "don't show this tip again for 7 days", etc.

## When to Use

Use this skill when you need:
- Dismiss notifications/prompts and show them again after N hours/days
- "Don't show this tip again for 7 days" functionality
- Resubscribe offers that reappear after 30 days
- Temporary suppress of alerts with automatic re-activation

## Pattern Overview

### What It Does

1. **Stores suppression timestamp** in SharedPreferences when user dismisses
2. **Calculates elapsed time** by comparing current time with stored timestamp
3. **Auto re-displays** when suppress duration expires
4. **Cleans up** when user re-engages or suppression expires

### Architecture Flow

```
UI (dismiss action)
  ↓
StateNotifier.suppress()
  ↓
SettingsRepository.setSuppressedAt{Entity}(version)
  ↓
PreferencesLocalDataSource.setInt(key, timestamp)
  ↓
SharedPreferences (persistent storage)

---

On display check:
UI (mount)
  ↓
StateNotifier._loadSuppressedState()
  ↓
SettingsRepository.getSuppressedAt{Entity}()
  ↓
State.shouldShow { elapsed >= duration }
  ↓
Conditional rendering
```

## Implementation Steps

### Step 1: Add SharedPreferences Keys

In `lib/data/datasources/local/preferences_local_datasource.dart`, add constants:

```dart
class PreferencesLocalDataSource {
  static const String _dismissed{Entity}VersionKey = 'dismissed_{entity}_version';
  static const String _dismissed{Entity}TimestampKey = 'dismissed_{entity}_timestamp';

  // ... other methods
}
```

**Example for notifications:**
```dart
static const String _dismissedNotificationVersionKey = 'dismissed_notification_version';
static const String _dismissedNotificationTimestampKey = 'dismissed_notification_timestamp';
```

### Step 2: Add DataSource Methods

In `preferences_local_datasource.dart`, add getter/setter:

```dart
/// Get suppressed {entity} version
Future<String?> getDismissedNotificationVersion() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_dismissedNotificationVersionKey);
}

/// Get suppressed {entity} timestamp
Future<int?> getDismissedNotificationTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_dismissedNotificationTimestampKey);
}

/// Save suppressed version with current timestamp
Future<void> setDismissedNotificationVersionWithTimestamp(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_dismissedNotificationVersionKey, version);
  await prefs.setInt(
    _dismissedNotificationTimestampKey,
    DateTime.now().millisecondsSinceEpoch,
  );
}

/// Clear suppression
Future<void> clearDismissedNotificationVersion() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_dismissedNotificationVersionKey);
  await prefs.remove(_dismissedNotificationTimestampKey);
}
```

### Step 3: Extend Repository Interface

In `lib/domain/repositories/settings_repository.dart`, add:

```dart
abstract class SettingsRepository {
  // ... existing methods

  /// Get suppressed {entity} version
  Future<String?> getDismissedNotificationVersion();

  /// Get suppressed {entity} timestamp
  Future<int?> getDismissedNotificationTimestamp();

  /// Save suppressed version with timestamp (24-hour suppress)
  Future<void> setDismissedNotificationVersionWithTimestamp(String version);

  /// Clear suppression
  Future<void> clearDismissedNotificationVersion();
}
```

### Step 4: Implement Repository

In `lib/data/repositories/settings_repository_impl.dart`, add:

```dart
@override
Future<String?> getDismissedNotificationVersion() =>
    _dataSource.getDismissedNotificationVersion();

@override
Future<int?> getDismissedNotificationTimestamp() =>
    _dataSource.getDismissedNotificationTimestamp();

@override
Future<void> setDismissedNotificationVersionWithTimestamp(String version) =>
    _dataSource.setDismissedNotificationVersionWithTimestamp(version);

@override
Future<void> clearDismissedNotificationVersion() =>
    _dataSource.clearDismissedNotificationVersion();
```

### Step 5: Add State Class with Suppress Duration

Create or update state class in your provider file:

```dart
/// Suppress state for {entity}
class {Entity}SuppressState {
  final String? dismissedVersion;
  final DateTime? dismissedAt;

  /// Suppress duration - adjust as needed
  static const Duration suppressDuration = Duration(hours: 24);  // or days: 7, etc

  const {Entity}SuppressState({
    this.dismissedVersion,
    this.dismissedAt,
  });

  /// Check if suppression is still active
  bool get isSuppressed {
    if (dismissedAt == null) return false;
    final elapsed = DateTime.now().difference(dismissedAt!);
    return elapsed < suppressDuration;
  }

  /// Check if should show badge/alert
  /// Returns true if no suppression OR suppression expired
  bool get shouldShow => !isSuppressed;

  {Entity}SuppressState copyWith({
    String? dismissedVersion,
    DateTime? dismissedAt,
    bool clearDismissed = false,
  }) {
    return {Entity}SuppressState(
      dismissedVersion: clearDismissed ? null : (dismissedVersion ?? this.dismissedVersion),
      dismissedAt: clearDismissed ? null : (dismissedAt ?? this.dismissedAt),
    );
  }
}
```

### Step 6: Add StateNotifier Methods

In your StateNotifier class, add:

```dart
/// Load suppression state from storage
Future<void> _loadDismissedState() async {
  final dismissed = await _settingsRepository.getDismissedNotificationVersion();
  final timestamp = await _settingsRepository.getDismissedNotificationTimestamp();

  if (mounted) {
    state = state.copyWith(
      dismissedVersion: dismissed,
      dismissedAt: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
    );
  }
}

/// Dismiss notification for 24 hours
Future<void> dismiss() async {
  final version = state.currentVersion;  // Get current version
  if (version == null) return;

  await _settingsRepository.setDismissedNotificationVersionWithTimestamp(version);
  state = state.copyWith(
    dismissedVersion: version,
    dismissedAt: DateTime.now(),
  );
}

/// Clear suppression (for manual re-check)
Future<void> clearSuppression() async {
  await _settingsRepository.clearDismissedNotificationVersion();
  state = state.copyWith(clearDismissed: true);
}
```

### Step 7: Create Unit Tests

In `test/presentation/providers/{entity}_suppress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('NotificationSuppressState', () {
    test('isSuppressed returns true when within suppress duration', () {
      final now = DateTime.now();
      final dismissedAt = now.subtract(const Duration(hours: 12));

      final state = {Entity}SuppressState(
        dismissedVersion: '1.0.0',
        dismissedAt: dismissedAt,
      );

      expect(state.isSuppressed, true);
      expect(state.shouldShow, false);
    });

    test('isSuppressed returns false when suppress duration expires', () {
      final now = DateTime.now();
      final dismissedAt = now.subtract(const Duration(hours: 25));

      final state = {Entity}SuppressState(
        dismissedVersion: '1.0.0',
        dismissedAt: dismissedAt,
      );

      expect(state.isSuppressed, false);
      expect(state.shouldShow, true);
    });

    test('shouldShow returns true when never suppressed', () {
      final state = const {Entity}SuppressState();
      expect(state.shouldShow, true);
    });

    test('copyWith with clearDismissed removes suppression', () {
      final state = {Entity}SuppressState(
        dismissedVersion: '1.0.0',
        dismissedAt: DateTime.now(),
      );

      final cleared = state.copyWith(clearDismissed: true);
      expect(cleared.dismissedVersion, null);
      expect(cleared.dismissedAt, null);
    });
  });

  group('NotificationStateNotifier', () {
    test('dismiss saves timestamp and updates state', () async {
      // Mock repository
      final mockRepo = Mock{Entity}Repository();

      final notifier = {Entity}StateNotifier(mockRepo);
      await notifier.dismiss();

      verify(mockRepo.setDismissedNotificationVersionWithTimestamp(any))
          .called(1);
      expect(notifier.state.isSuppressed, true);
    });

    test('clearSuppression resets state', () async {
      final mockRepo = Mock{Entity}Repository();

      final notifier = {Entity}StateNotifier(mockRepo);
      await notifier.dismiss();
      await notifier.clearSuppression();

      verify(mockRepo.clearDismissedNotificationVersion()).called(1);
      expect(notifier.state.dismissedVersion, null);
    });
  });
}
```

## Usage Examples

### Example 1: Update Notification (24-hour suppress)

```dart
// In state class
class UpdateState {
  final UpdateCheckResult? result;
  final String? dismissedVersion;
  final DateTime? dismissedAt;

  static const Duration suppressDuration = Duration(hours: 24);

  bool get shouldShowBadge {
    if (result == null) return false;
    if (result!.isUpToDate) return false;
    if (result!.latestVersion != dismissedVersion) return true;

    if (dismissedAt != null) {
      final elapsed = DateTime.now().difference(dismissedAt!);
      if (elapsed >= suppressDuration) return true;
    }
    return false;
  }
}

// In UI
if (state.shouldShowBadge) {
  UpdateBadge()  // Show badge
}

// User action
onRemindLater: () => updateNotifier.dismiss(),
```

### Example 2: Help Dialog Tip (7-day suppress)

```dart
// In help_dialog_state
class HelpDialogState {
  final String? dismissedTipId;
  final DateTime? dismissedAt;

  static const Duration suppressDuration = Duration(days: 7);

  bool get shouldShow {
    if (dismissedTipId == null) return true;
    if (dismissedAt == null) return true;

    final elapsed = DateTime.now().difference(dismissedAt!);
    return elapsed >= suppressDuration;
  }
}

// In notifier
Future<void> dismissTip(String tipId) async {
  await settingsRepository.setDismissedTipWithTimestamp(tipId);
  state = state.copyWith(
    dismissedTipId: tipId,
    dismissedAt: DateTime.now(),
  );
}

// In widget
if (helpState.shouldShow) {
  showDialog(
    context: context,
    builder: (_) => HelpDialog(
      onDismiss: () => ref.read(helpProvider.notifier).dismissTip('tip_001'),
    ),
  );
}
```

### Example 3: Resubscribe Offer (30-day suppress)

```dart
class SubscriptionOfferState {
  final bool isOfferEligible;
  final DateTime? lastUnsubscribedAt;

  static const Duration offerCooldown = Duration(days: 30);

  bool get shouldShowResubscribeOffer {
    if (lastUnsubscribedAt == null) return false;

    final elapsed = DateTime.now().difference(lastUnsubscribedAt!);
    return elapsed >= offerCooldown;
  }
}

// In notifier
Future<void> unsubscribe() async {
  await subscriptionRepo.unsubscribe();
  await settingsRepo.setUnsubscriptionTimestamp(DateTime.now().millisecondsSinceEpoch);
  state = state.copyWith(lastUnsubscribedAt: DateTime.now());
}

// In widget (shown on home screen)
if (subscriptionState.shouldShowResubscribeOffer) {
  ResubscribeOfferBanner(
    onResubscribe: () => resubscribe(),
  )
}
```

## Validation Checklist

- [ ] SharedPreferences keys added to PreferencesLocalDataSource
- [ ] DataSource getter/setter methods added (4 methods)
- [ ] Repository interface extended with 4 new methods
- [ ] Repository implementation added
- [ ] State class has `suppressDuration` constant
- [ ] State class has `isSuppressed` and/or `shouldShow` getter
- [ ] StateNotifier has `_loadDismissedState()` call in constructor
- [ ] StateNotifier has `dismiss()` method
- [ ] StateNotifier has `clearSuppression()` method (if needed)
- [ ] Unit tests created (4+ test cases)
- [ ] All tests pass: `flutter test`
- [ ] No lint violations: `flutter analyze`

## Common Variations

### Variation 1: Version-based Suppression (Multiple versions)

```dart
// Suppress specific version, but allow showing for newer versions
bool get shouldShow {
  if (result?.latestVersion == dismissedVersion) {
    if (dismissedAt != null) {
      final elapsed = DateTime.now().difference(dismissedAt!);
      return elapsed >= suppressDuration;
    }
    return false;
  }
  return true;  // New version available, always show
}
```

### Variation 2: User-controlled Duration

```dart
// Let user choose suppress duration
enum SuppressDuration {
  oneHour(Duration(hours: 1)),
  oneDay(Duration(days: 1)),
  oneWeek(Duration(days: 7)),
  never(Duration(days: 365 * 10));  // 10 years = never

  final Duration value;
  const SuppressDuration(this.value);
}

// In state
Future<void> dismiss({required SuppressDuration duration}) async {
  await repo.saveSuppressInfo(version: currentVersion, duration: duration.value);
  state = state.copyWith(suppressDuration: duration.value);
}
```

### Variation 3: Suppress with Reasons

```dart
// Track why user suppressed (analytics)
class SuppressReason {
  final String reason;  // "later", "not_interested", "know_about_it"
  final DateTime suppressedAt;

  const SuppressReason({required this.reason, required this.suppressedAt});
}

Future<void> dismiss({required String reason}) async {
  final suppressInfo = SuppressReason(
    reason: reason,
    suppressedAt: DateTime.now(),
  );
  // Save to repo + analytics
}
```

## Performance Notes

- SharedPreferences calls are cached in memory after first read
- No performance impact from checking `DateTime.now().difference()` (microseconds)
- Consider invalidating related providers when clearing suppression

## Related Patterns

- **Provider Invalidation**: Call `ref.invalidate(notificationProvider)` when clearing suppression
- **Analytics**: Track suppress reasons for UX insights
- **Testing**: Use `freezed` for state immutability if not already

