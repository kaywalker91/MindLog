import '../../core/constants/ai_character.dart';
import '../repositories/settings_repository.dart';

class GetSelectedAiCharacterUseCase {
  final SettingsRepository _repository;

  GetSelectedAiCharacterUseCase(this._repository);

  Future<AiCharacter> execute() {
    return _repository.getSelectedAiCharacter();
  }
}
