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
}
