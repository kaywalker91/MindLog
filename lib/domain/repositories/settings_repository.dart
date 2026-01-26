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

  /// dismiss된 업데이트 버전 조회
  Future<String?> getDismissedUpdateVersion();

  /// dismiss된 업데이트 버전 저장
  Future<void> setDismissedUpdateVersion(String version);

  /// dismiss된 업데이트 버전 삭제
  Future<void> clearDismissedUpdateVersion();

  /// 마지막으로 확인한 앱 버전 조회 (업그레이드 감지용)
  Future<String?> getLastSeenAppVersion();

  /// 마지막으로 확인한 앱 버전 저장
  Future<void> setLastSeenAppVersion(String version);
}
