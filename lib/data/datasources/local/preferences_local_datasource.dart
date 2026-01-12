import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/ai_character.dart';
import '../../../domain/entities/notification_settings.dart';

class PreferencesLocalDataSource {
  static const String _aiCharacterKey = 'ai_character';
  static const String _reminderEnabledKey = 'notification_reminder_enabled';
  static const String _reminderHourKey = 'notification_reminder_hour';
  static const String _reminderMinuteKey = 'notification_reminder_minute';
  static const String _mindcareTopicEnabledKey =
      'notification_mindcare_topic_enabled';
  static const String _userNameKey = 'user_name';
  static const String _dismissedUpdateVersionKey = 'dismissed_update_version';
  static const String _lastSeenAppVersionKey = 'last_seen_app_version';

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
    return NotificationSettings(
      isReminderEnabled: prefs.getBool(_reminderEnabledKey) ??
          NotificationSettings.defaultReminderEnabled,
      reminderHour: prefs.getInt(_reminderHourKey) ??
          NotificationSettings.defaultReminderHour,
      reminderMinute: prefs.getInt(_reminderMinuteKey) ??
          NotificationSettings.defaultReminderMinute,
      isMindcareTopicEnabled: prefs.getBool(_mindcareTopicEnabledKey) ??
          NotificationSettings.defaultMindcareTopicEnabled,
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

  /// dismiss된 업데이트 버전 삭제
  Future<void> clearDismissedUpdateVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedUpdateVersionKey);
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
}
