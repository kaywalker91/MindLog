import '../../core/constants/ai_character.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_local_datasource.dart';
import 'repository_failure_handler.dart';

class SettingsRepositoryImpl
    with RepositoryFailureHandler
    implements SettingsRepository {
  final PreferencesLocalDataSource _localDataSource;

  SettingsRepositoryImpl({required PreferencesLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

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

  @override
  Future<String?> getUserName() async {
    return guardFailure('유저 이름 조회 실패', _localDataSource.getUserName);
  }

  @override
  Future<void> setUserName(String? name) async {
    return guardFailure(
      '유저 이름 설정 실패',
      () => _localDataSource.setUserName(name),
    );
  }

  @override
  Future<String?> getDismissedUpdateVersion() async {
    return guardFailure(
      'dismiss 버전 조회 실패',
      _localDataSource.getDismissedUpdateVersion,
    );
  }

  @override
  Future<void> setDismissedUpdateVersion(String version) async {
    return guardFailure(
      'dismiss 버전 저장 실패',
      () => _localDataSource.setDismissedUpdateVersion(version),
    );
  }

  @override
  Future<void> setDismissedUpdateVersionWithTimestamp(String version) async {
    return guardFailure(
      'dismiss 버전(timestamp 포함) 저장 실패',
      () => _localDataSource.setDismissedUpdateVersionWithTimestamp(version),
    );
  }

  @override
  Future<int?> getDismissedUpdateTimestamp() async {
    return guardFailure(
      'dismiss timestamp 조회 실패',
      _localDataSource.getDismissedUpdateTimestamp,
    );
  }

  @override
  Future<void> clearDismissedUpdateVersion() async {
    return guardFailure(
      'dismiss 버전 삭제 실패',
      _localDataSource.clearDismissedUpdateVersion,
    );
  }

  @override
  Future<String?> getLastSeenAppVersion() async {
    return guardFailure(
      '마지막 앱 버전 조회 실패',
      _localDataSource.getLastSeenAppVersion,
    );
  }

  @override
  Future<void> setLastSeenAppVersion(String version) async {
    return guardFailure(
      '마지막 앱 버전 저장 실패',
      () => _localDataSource.setLastSeenAppVersion(version),
    );
  }
}
