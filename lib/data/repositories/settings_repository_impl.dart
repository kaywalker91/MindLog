import '../../core/constants/ai_character.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final PreferencesLocalDataSource _localDataSource;

  SettingsRepositoryImpl({
    required PreferencesLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<AiCharacter> getSelectedAiCharacter() async {
    try {
      return await _localDataSource.getSelectedAiCharacter();
    } catch (e) {
      throw FailureMapper.from(e, message: 'AI 캐릭터 조회 실패');
    }
  }

  @override
  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    try {
      await _localDataSource.setSelectedAiCharacter(character);
    } catch (e) {
      throw FailureMapper.from(e, message: 'AI 캐릭터 설정 실패');
    }
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _localDataSource.getNotificationSettings();
    } catch (e) {
      throw FailureMapper.from(e, message: '알림 설정 조회 실패');
    }
  }

  @override
  Future<void> setNotificationSettings(NotificationSettings settings) async {
    try {
      await _localDataSource.setNotificationSettings(settings);
    } catch (e) {
      throw FailureMapper.from(e, message: '알림 설정 저장 실패');
    }
  }
}
