import '../../core/constants/ai_character.dart';

abstract class SettingsRepository {
  Future<AiCharacter> getSelectedAiCharacter();
  Future<void> setSelectedAiCharacter(AiCharacter character);
}
