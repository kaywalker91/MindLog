import '../../core/services/notification_permission_service.dart';

/// Result of Cheer Me (reminder) enable/disable orchestration.
///
/// The widget maps this to dialogs / SnackBars only — permission I/O lives here.
sealed class ReminderEnableResult {
  const ReminderEnableResult();
}

/// Reminder was turned off and settings were persisted.
final class ReminderDisabled extends ReminderEnableResult {
  const ReminderDisabled();
}

/// Exact-alarm permission is missing — show [ExactAlarmPermissionDialog].
final class NeedExactAlarmPrompt extends ReminderEnableResult {
  const NeedExactAlarmPrompt();
}

/// Battery optimization still active — show [BatteryOptimizationDialog].
final class NeedBatteryPrompt extends ReminderEnableResult {
  const NeedBatteryPrompt();
}

/// Reminder was enabled. [warnings] are user-facing SnackBar messages (0–2).
final class ReminderEnabled extends ReminderEnableResult {
  const ReminderEnabled({this.warnings = const []});

  final List<String> warnings;
}

/// Unexpected failure during enable/disable.
final class ReminderEnableFailed extends ReminderEnableResult {
  const ReminderEnableFailed(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}

/// Orchestrates exact-alarm + battery permission steps before enabling reminders.
///
/// Multi-step API so the UI stays dumb:
/// 1. [setEnabled] / [prepareEnable]
/// 2. On [NeedExactAlarmPrompt] → dialog → [onExactAlarmPromptResult]
/// 3. On [NeedBatteryPrompt] → dialog → [onBatteryPromptResult]
/// 4. Terminal: [ReminderEnabled] / [ReminderDisabled] / [ReminderEnableFailed]
class ReminderToggleCoordinator {
  ReminderToggleCoordinator({
    required Future<void> Function(bool enabled) updateReminderEnabled,
    Future<bool> Function()? canScheduleExactAlarms,
    Future<void> Function()? requestExactAlarmPermission,
    Future<void> Function()? markExactAlarmPrompted,
    Future<bool> Function()? isIgnoringBatteryOptimizations,
    Future<void> Function()? requestDisableBatteryOptimization,
  }) : _updateReminderEnabled = updateReminderEnabled,
       _canScheduleExactAlarms =
           canScheduleExactAlarms ??
           NotificationPermissionService.canScheduleExactAlarms,
       _requestExactAlarmPermission =
           requestExactAlarmPermission ??
           NotificationPermissionService.requestExactAlarmPermission,
       _markExactAlarmPrompted =
           markExactAlarmPrompted ??
           NotificationPermissionService.markExactAlarmPrompted,
       _isIgnoringBatteryOptimizations =
           isIgnoringBatteryOptimizations ??
           NotificationPermissionService.isIgnoringBatteryOptimizations,
       _requestDisableBatteryOptimization =
           requestDisableBatteryOptimization ??
           NotificationPermissionService.requestDisableBatteryOptimization;

  static const exactAlarmWarningMessage = '알람이 정확한 시간에 울리지 않을 수 있습니다.';
  static const batteryWarningMessage =
      '배터리 최적화가 활성화되어 있어 알람이 전달되지 않을 수 있습니다.';

  final Future<void> Function(bool enabled) _updateReminderEnabled;
  final Future<bool> Function() _canScheduleExactAlarms;
  final Future<void> Function() _requestExactAlarmPermission;
  final Future<void> Function() _markExactAlarmPrompted;
  final Future<bool> Function() _isIgnoringBatteryOptimizations;
  final Future<void> Function() _requestDisableBatteryOptimization;

  final List<String> _pendingWarnings = [];

  /// Disable reminder or start the enable permission flow.
  Future<ReminderEnableResult> setEnabled(bool enabled) async {
    if (!enabled) {
      try {
        await _updateReminderEnabled(false);
        return const ReminderDisabled();
      } catch (e, st) {
        return ReminderEnableFailed(e, st);
      }
    }
    return prepareEnable();
  }

  /// Start enable path: exact-alarm check first.
  Future<ReminderEnableResult> prepareEnable() async {
    _pendingWarnings.clear();
    try {
      final canScheduleExact = await _canScheduleExactAlarms();
      if (!canScheduleExact) {
        return const NeedExactAlarmPrompt();
      }
      return _checkBattery();
    } catch (e, st) {
      return ReminderEnableFailed(e, st);
    }
  }

  /// Continue after exact-alarm dialog. [shouldContinue] mirrors dialog result.
  Future<ReminderEnableResult> onExactAlarmPromptResult(
    bool? shouldContinue,
  ) async {
    try {
      if (shouldContinue == true) {
        await _requestExactAlarmPermission();
        await _markExactAlarmPrompted();
        final nowCanSchedule = await _canScheduleExactAlarms();
        if (!nowCanSchedule) {
          _pendingWarnings.add(exactAlarmWarningMessage);
        }
      }
      return _checkBattery();
    } catch (e, st) {
      return ReminderEnableFailed(e, st);
    }
  }

  /// Continue after battery dialog. [shouldDisable] mirrors dialog result.
  Future<ReminderEnableResult> onBatteryPromptResult(
    bool? shouldDisable,
  ) async {
    try {
      if (shouldDisable == true) {
        await _requestDisableBatteryOptimization();
        final nowIgnoring = await _isIgnoringBatteryOptimizations();
        if (!nowIgnoring) {
          _pendingWarnings.add(batteryWarningMessage);
        }
      }
      return _finalizeEnable();
    } catch (e, st) {
      return ReminderEnableFailed(e, st);
    }
  }

  Future<ReminderEnableResult> _checkBattery() async {
    final isIgnoring = await _isIgnoringBatteryOptimizations();
    if (!isIgnoring) {
      return const NeedBatteryPrompt();
    }
    return _finalizeEnable();
  }

  Future<ReminderEnableResult> _finalizeEnable() async {
    try {
      await _updateReminderEnabled(true);
      return ReminderEnabled(warnings: List.unmodifiable(_pendingWarnings));
    } catch (e, st) {
      return ReminderEnableFailed(e, st);
    }
  }
}
