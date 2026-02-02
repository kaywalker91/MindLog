import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 업데이트 다이얼로그 액션 버튼 위젯
class UpdateActions extends StatelessWidget {
  final bool isRequired;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onRemindLater;

  const UpdateActions({
    super.key,
    required this.isRequired,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (secondaryLabel != null && onSecondary != null) ...[
                TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: onPrimary,
                style: isRequired
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: colorScheme.onError,
                      )
                    : null,
                child: Text(primaryLabel),
              ),
            ],
          ),
          // "나중에 알림" 버튼 (필수 업데이트가 아닐 때만)
          if (!isRequired && onRemindLater != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onRemindLater,
                icon: Icon(
                  Icons.notifications_off_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  '나중에 알림',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
