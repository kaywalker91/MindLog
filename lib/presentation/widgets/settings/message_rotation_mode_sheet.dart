import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/self_encouragement_message.dart';
import '../../providers/providers.dart';

/// 메시지 로테이션 모드 선택 바텀 시트
class MessageRotationModeSheet extends ConsumerWidget {
  final MessageRotationMode selected;

  const MessageRotationModeSheet({super.key, required this.selected});

  /// 바텀 시트 표시 유틸리티 메서드
  static Future<void> show(
    BuildContext context, {
    required MessageRotationMode selected,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MessageRotationModeSheet(selected: selected),
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
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Text(
              '메시지 순서 선택',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<MessageRotationMode>(
              groupValue: selected,
              onChanged: (value) async {
                if (value == null) return;
                await ref
                    .read(notificationSettingsProvider.notifier)
                    .updateRotationMode(value);
                if (context.mounted) {
                  context.pop();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<MessageRotationMode>(
                    value: MessageRotationMode.random,
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(
                      '무작위로 선택',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '매번 다른 메시지가 랜덤하게 표시돼요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: theme.colorScheme.primary,
                  ),
                  RadioListTile<MessageRotationMode>(
                    value: MessageRotationMode.sequential,
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(
                      '순차로 선택',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '등록한 순서대로 하나씩 표시돼요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: theme.colorScheme.primary,
                  ),
                  RadioListTile<MessageRotationMode>(
                    value: MessageRotationMode.emotionAware,
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(
                      '감정 맞춤 선택',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '최근 감정과 비슷한 때 쓴 메시지가 우선 표시돼요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
