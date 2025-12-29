import '../../core/constants/ai_character.dart';
import '../repositories/settings_repository.dart';

class SetSelectedAiCharacterUseCase {
  final SettingsRepository _repository;

  SetSelectedAiCharacterUseCase(this._repository);

  Future<void> execute(AiCharacter character) {
    return _repository.setSelectedAiCharacter(character);
  }
}
