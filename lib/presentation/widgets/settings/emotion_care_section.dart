import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/ai_character.dart';
import '../../providers/providers.dart';
import 'ai_character_sheet.dart';
import 'settings_card.dart';
import 'settings_item.dart';
import 'settings_trailing.dart';
import 'user_name_dialog.dart';

/// 감정 케어 섹션
class EmotionCareSection extends ConsumerWidget {
  const EmotionCareSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(aiCharacterProvider);
    final selectedCharacter =
        characterAsync.valueOrNull ?? AiCharacter.warmCounselor;
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.valueOrNull;

    final characterLabel = characterAsync.when(
      data: (character) => character.displayName,
      loading: () => '불러오는 중...',
      error: (_, _) => AiCharacter.warmCounselor.displayName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '감정 케어'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.mood_outlined,
              title: 'AI 캐릭터',
              trailing: AiCharacterTrailing(label: characterLabel),
              onTap: () => AiCharacterSheet.show(
                context,
                selected: selectedCharacter,
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.person_outline,
              title: '내 이름',
              trailing: UserNameTrailing(userName: userName),
              onTap: () => UserNameDialog.show(context, currentName: userName),
            ),
          ],
        ),
      ],
    );
  }
}
