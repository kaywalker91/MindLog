import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_settings_service.dart';
import '../../domain/entities/notification_settings.dart';
import 'providers.dart';

class NotificationSettingsController
    extends AsyncNotifier<NotificationSettings> {
  @override
  FutureOr<NotificationSettings> build() async {
    final useCase = ref.read(getNotificationSettingsUseCaseProvider);
    return useCase.execute();
  }

  Future<void> updateReminderEnabled(bool enabled) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    final updated = current.copyWith(isReminderEnabled: enabled);
    await _persistAndApply(updated, source: 'user_toggle');
  }

  Future<void> updateReminderTime({
    required int hour,
    required int minute,
  }) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    final updated = current.copyWith(
      reminderHour: hour,
      reminderMinute: minute,
    );
    await _persistAndApply(updated, source: 'time_change');
  }

  Future<void> updateMindcareTopicEnabled(bool enabled) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    final updated = current.copyWith(isMindcareTopicEnabled: enabled);
    await _persistAndApply(updated, source: 'user_toggle');
  }

  Future<void> _persistAndApply(
    NotificationSettings settings, {
    required String source,
  }) async {
    final useCase = ref.read(setNotificationSettingsUseCaseProvider);
    await useCase.execute(settings);
    state = AsyncValue.data(settings);
    await NotificationSettingsService.applySettings(settings, source: source);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
  NotificationSettingsController.new,
);
