import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/presentation/providers/providers.dart';

class AiCharacterController extends AsyncNotifier<AiCharacter> {
  @override
  FutureOr<AiCharacter> build() async {
    final useCase = ref.read(getSelectedAiCharacterUseCaseProvider);
    return useCase.execute();
  }

  Future<void> setCharacter(AiCharacter character) async {
    final useCase = ref.read(setSelectedAiCharacterUseCaseProvider);
    await useCase.execute(character);
    state = AsyncValue.data(character);
  }
}

final aiCharacterProvider =
    AsyncNotifierProvider<AiCharacterController, AiCharacter>(() {
  return AiCharacterController();
});
