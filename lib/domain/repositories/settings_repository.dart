import '../../core/constants/ai_character.dart';
import '../entities/notification_settings.dart';

abstract class SettingsRepository {
  Future<AiCharacter> getSelectedAiCharacter();
  Future<void> setSelectedAiCharacter(AiCharacter character);
  Future<NotificationSettings> getNotificationSettings();
  Future<void> setNotificationSettings(NotificationSettings settings);
}
