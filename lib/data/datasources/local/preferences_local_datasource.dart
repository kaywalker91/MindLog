import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/ai_character.dart';

class PreferencesLocalDataSource {
  static const String _aiCharacterKey = 'ai_character';

  Future<AiCharacter> getSelectedAiCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_aiCharacterKey);
    return aiCharacterFromId(id);
  }

  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiCharacterKey, character.id);
  }
}
