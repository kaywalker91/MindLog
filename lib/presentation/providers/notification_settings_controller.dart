import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/presentation/providers/providers.dart';

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

    // 안전망: 설정은 저장됨, 스케줄링 실패 시 크래시 방지
    try {
      await NotificationSettingsService.applySettings(settings, source: source);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[NotificationSettingsController] applySettings failed: $e');
        debugPrint('[NotificationSettingsController] Stack trace: $stackTrace');
      }
      // 설정 저장됨, 스케줄링만 실패 - 앱 크래시 방지
    }
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
  NotificationSettingsController.new,
);
