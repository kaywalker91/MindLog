import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/ai_character.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../domain/entities/self_encouragement_message.dart';

class PreferencesLocalDataSource {
  static const String _aiCharacterKey = 'ai_character';
  static const String _reminderEnabledKey = 'notification_reminder_enabled';
  static const String _reminderHourKey = 'notification_reminder_hour';
  static const String _reminderMinuteKey = 'notification_reminder_minute';
  static const String _mindcareTopicEnabledKey =
      'notification_mindcare_topic_enabled';
  static const String _rotationModeKey = 'message_rotation_mode';
  static const String _lastDisplayedIndexKey = 'last_displayed_message_index';
  static const String _selfMessagesKey = 'self_encouragement_messages';
  static const String _userNameKey = 'user_name';
  static const String _dismissedUpdateVersionKey = 'dismissed_update_version';
  static const String _dismissedUpdateTimestampKey =
      'dismissed_update_timestamp';
  static const String _lastSeenAppVersionKey = 'last_seen_app_version';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  Future<AiCharacter> getSelectedAiCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_aiCharacterKey);
    return aiCharacterFromId(id);
  }

  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiCharacterKey, character.id);
  }

  Future<NotificationSettings> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rotationModeStr = prefs.getString(_rotationModeKey);
    final rotationMode = rotationModeStr == 'sequential'
        ? MessageRotationMode.sequential
        : MessageRotationMode.random;

    final rawHour =
        prefs.getInt(_reminderHourKey) ??
        NotificationSettings.defaultReminderHour;
    final rawMinute =
        prefs.getInt(_reminderMinuteKey) ??
        NotificationSettings.defaultReminderMinute;

    return NotificationSettings(
      isReminderEnabled:
          prefs.getBool(_reminderEnabledKey) ??
          NotificationSettings.defaultReminderEnabled,
      reminderHour: rawHour.clamp(0, 23),
      reminderMinute: rawMinute.clamp(0, 59),
      isMindcareTopicEnabled:
          prefs.getBool(_mindcareTopicEnabledKey) ??
          NotificationSettings.defaultMindcareTopicEnabled,
      rotationMode: rotationMode,
      lastDisplayedIndex: prefs.getInt(_lastDisplayedIndexKey) ?? 0,
    );
  }

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, settings.isReminderEnabled);
    await prefs.setInt(_reminderHourKey, settings.reminderHour);
    await prefs.setInt(_reminderMinuteKey, settings.reminderMinute);
    await prefs.setBool(
      _mindcareTopicEnabledKey,
      settings.isMindcareTopicEnabled,
    );
    await prefs.setString(
      _rotationModeKey,
      settings.rotationMode == MessageRotationMode.sequential
          ? 'sequential'
          : 'random',
    );
    await prefs.setInt(_lastDisplayedIndexKey, settings.lastDisplayedIndex);
  }

  /// 유저 이름 조회 (미설정 시 null 반환)
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// 유저 이름 저장 (null 또는 빈 문자열 시 삭제)
  Future<void> setUserName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || name.trim().isEmpty) {
      await prefs.remove(_userNameKey);
    } else {
      await prefs.setString(_userNameKey, name.trim());
    }
  }

  /// dismiss된 업데이트 버전 조회
  Future<String?> getDismissedUpdateVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedUpdateVersionKey);
  }

  /// dismiss된 업데이트 버전 저장
  Future<void> setDismissedUpdateVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedUpdateVersionKey, version);
  }

  /// dismiss된 업데이트 버전 저장 (timestamp 포함)
  Future<void> setDismissedUpdateVersionWithTimestamp(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedUpdateVersionKey, version);
    await prefs.setInt(
      _dismissedUpdateTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// dismiss된 업데이트 timestamp 조회
  Future<int?> getDismissedUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dismissedUpdateTimestampKey);
  }

  /// dismiss된 업데이트 버전 삭제 (timestamp도 함께 삭제)
  Future<void> clearDismissedUpdateVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedUpdateVersionKey);
    await prefs.remove(_dismissedUpdateTimestampKey);
  }

  /// 마지막으로 확인한 앱 버전 조회 (업그레이드 감지용)
  Future<String?> getLastSeenAppVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenAppVersionKey);
  }

  /// 마지막으로 확인한 앱 버전 저장
  Future<void> setLastSeenAppVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenAppVersionKey, version);
  }

  /// 온보딩 완료 여부 조회
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// 온보딩 완료 저장
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // === 개인 응원 메시지 관리 ===

  /// 저장된 개인 응원 메시지 목록 조회
  Future<List<SelfEncouragementMessage>> getSelfEncouragementMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_selfMessagesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map(
            (e) =>
                SelfEncouragementMessage.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stack) {
      // 손상된 데이터 로깅 후 제거, 빈 리스트 반환
      await CrashlyticsService.recordError(
        e,
        stack,
        reason: 'Corrupted self-encouragement messages JSON removed',
      );
      await prefs.remove(_selfMessagesKey);
      return [];
    }
  }

  /// 개인 응원 메시지 목록 저장
  Future<void> saveSelfEncouragementMessages(
    List<SelfEncouragementMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_selfMessagesKey, json.encode(jsonList));
  }

  /// 개인 응원 메시지 추가
  Future<void> addSelfEncouragementMessage(
    SelfEncouragementMessage message,
  ) async {
    final messages = await getSelfEncouragementMessages();
    messages.add(message);
    await saveSelfEncouragementMessages(messages);
  }

  /// 개인 응원 메시지 수정
  Future<void> updateSelfEncouragementMessage(
    SelfEncouragementMessage message,
  ) async {
    final messages = await getSelfEncouragementMessages();
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
      await saveSelfEncouragementMessages(messages);
    }
  }

  /// 개인 응원 메시지 삭제
  Future<void> deleteSelfEncouragementMessage(String messageId) async {
    final messages = await getSelfEncouragementMessages();
    messages.removeWhere((m) => m.id == messageId);
    // displayOrder 재정렬
    for (var i = 0; i < messages.length; i++) {
      messages[i] = messages[i].copyWith(displayOrder: i);
    }
    await saveSelfEncouragementMessages(messages);
  }

  /// 개인 응원 메시지 순서 변경
  Future<void> reorderSelfEncouragementMessages(
    List<String> orderedIds,
  ) async {
    final messages = await getSelfEncouragementMessages();
    final reordered = <SelfEncouragementMessage>[];

    for (var i = 0; i < orderedIds.length; i++) {
      final message = messages.firstWhere(
        (m) => m.id == orderedIds[i],
        orElse: () => throw Exception('Message not found: ${orderedIds[i]}'),
      );
      reordered.add(message.copyWith(displayOrder: i));
    }

    await saveSelfEncouragementMessages(reordered);
  }
}
