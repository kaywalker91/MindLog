import '../../core/constants/ai_character.dart';
import '../entities/notification_settings.dart';

abstract class SettingsRepository {
  Future<AiCharacter> getSelectedAiCharacter();
  Future<void> setSelectedAiCharacter(AiCharacter character);
  Future<NotificationSettings> getNotificationSettings();
  Future<void> setNotificationSettings(NotificationSettings settings);

  /// 유저 이름 조회 (미설정 시 null)
  Future<String?> getUserName();

  /// 유저 이름 저장 (null 전달 시 삭제)
  Future<void> setUserName(String? name);
}
