import '../../core/constants/ai_character.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_local_datasource.dart';
import 'repository_failure_handler.dart';

class SettingsRepositoryImpl
    with RepositoryFailureHandler
    implements SettingsRepository {
  final PreferencesLocalDataSource _localDataSource;

  SettingsRepositoryImpl({
    required PreferencesLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<AiCharacter> getSelectedAiCharacter() async {
    return guardFailure(
      'AI 캐릭터 조회 실패',
      _localDataSource.getSelectedAiCharacter,
    );
  }

  @override
  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    return guardFailure(
      'AI 캐릭터 설정 실패',
      () => _localDataSource.setSelectedAiCharacter(character),
    );
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    return guardFailure(
      '알림 설정 조회 실패',
      _localDataSource.getNotificationSettings,
    );
  }

  @override
  Future<void> setNotificationSettings(NotificationSettings settings) async {
    return guardFailure(
      '알림 설정 저장 실패',
      () => _localDataSource.setNotificationSettings(settings),
    );
  }
}
