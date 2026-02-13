import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
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

  Future<void> updateRotationMode(MessageRotationMode mode) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    final updated = current.copyWith(rotationMode: mode);
    await _persistAndApply(updated, source: 'user_toggle');
  }

  Future<void> updateWeeklyInsightEnabled(bool enabled) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    final updated = current.copyWith(isWeeklyInsightEnabled: enabled);
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
      final messages = ref.read(selfEncouragementProvider).valueOrNull ?? [];
      final userName = ref.read(userNameProvider).valueOrNull;
      final recentScore = ref.read(todayEmotionProvider).sentimentScore;
      // TODO: Consider wrapping NotificationSettingsService.applySettings in UseCase
      final nextIndex = await NotificationSettingsService.applySettings(
        settings,
        messages: messages,
        source: source,
        userName: userName,
        recentEmotionScore: recentScore?.toDouble(),
      );

      await _updateSequentialIndex(settings, nextIndex);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[NotificationSettingsController] applySettings failed: $e');
        debugPrint('[NotificationSettingsController] Stack trace: $stackTrace');
      }
    }
  }

  /// 순차 모드에서 다음 인덱스 업데이트 (공통 헬퍼)
  Future<void> _updateSequentialIndex(
    NotificationSettings settings,
    int nextIndex,
  ) async {
    if (settings.rotationMode == MessageRotationMode.sequential &&
        nextIndex != settings.lastDisplayedIndex) {
      final updated = settings.copyWith(lastDisplayedIndex: nextIndex);
      final useCase = ref.read(setNotificationSettingsUseCaseProvider);
      await useCase.execute(updated);
      state = AsyncValue.data(updated);
    }
  }

  /// 메시지 변경 시 알림 재스케줄링
  Future<void> rescheduleWithMessages(
    List<SelfEncouragementMessage> messages,
  ) async {
    final current = state.valueOrNull ?? NotificationSettings.defaults();
    if (!current.isReminderEnabled) return;

    try {
      final userName = ref.read(userNameProvider).valueOrNull;
      final recentScore = ref.read(todayEmotionProvider).sentimentScore;
      final nextIndex = await NotificationSettingsService.applySettings(
        current,
        messages: messages,
        source: 'message_change',
        userName: userName,
        recentEmotionScore: recentScore?.toDouble(),
      );

      await _updateSequentialIndex(current, nextIndex);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[NotificationSettingsController] reschedule failed: $e');
        debugPrint('[NotificationSettingsController] Stack trace: $stackTrace');
      }
    }
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );
