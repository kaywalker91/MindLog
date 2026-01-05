import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/ai_character.dart';
import '../providers/ai_character_controller.dart';

/// AI 캐릭터 선택 바텀시트 위젯
class AiCharacterBottomSheet extends ConsumerWidget {
  final AiCharacter selected;

  const AiCharacterBottomSheet({
    super.key,
    required this.selected,
  });

  /// 바텀시트를 표시하는 유틸리티 메서드
  static void show(BuildContext context, WidgetRef ref, AiCharacter selected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AiCharacterBottomSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // 제목
            Text(
              'AI 캐릭터 선택',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // RadioGroup으로 감싸서 groupValue/onChanged 대체 (Flutter 3.32+)
            RadioGroup<AiCharacter>(
              groupValue: selected,
              onChanged: (value) async {
                if (value == null) return;
                await ref
                    .read(aiCharacterProvider.notifier)
                    .setCharacter(value);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AiCharacter.values.map(
                  (character) => RadioListTile<AiCharacter>(
                    value: character,
                    secondary: _buildCharacterThumbnail(context, character),
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(
                      character.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      character.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: theme.colorScheme.primary,
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterThumbnail(BuildContext context, AiCharacter character) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        character.imagePath,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 44,
            height: 44,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined, size: 20),
          );
        },
      ),
    );
  }
}
