import '../../core/constants/ai_character.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final PreferencesLocalDataSource _localDataSource;

  SettingsRepositoryImpl({
    required PreferencesLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<AiCharacter> getSelectedAiCharacter() {
    return _localDataSource.getSelectedAiCharacter();
  }

  @override
  Future<void> setSelectedAiCharacter(AiCharacter character) {
    return _localDataSource.setSelectedAiCharacter(character);
  }
}
