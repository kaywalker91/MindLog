import 'package:flutter/material.dart';
import 'expandable_notes.dart';
import 'update_actions.dart';
import 'update_header.dart';
import 'version_comparison.dart';

/// 업데이트 프롬프트 다이얼로그 위젯
class UpdatePromptDialog extends StatelessWidget {
  final bool isRequired;
  final String title;
  final String message;
  final String currentVersion;
  final String latestVersion;
  final List<String> notes;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onRemindLater;

  const UpdatePromptDialog({
    super.key,
    required this.isRequired,
    required this.title,
    required this.message,
    required this.currentVersion,
    required this.latestVersion,
    required this.notes,
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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UpdateHeader(isRequired: isRequired),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VersionComparison(
                      currentVersion: currentVersion,
                      latestVersion: latestVersion,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpandableNotes(notes: notes),
                  ],
                ),
              ),
              UpdateActions(
                isRequired: isRequired,
                primaryLabel: primaryLabel,
                onPrimary: onPrimary,
                secondaryLabel: secondaryLabel,
                onSecondary: onSecondary,
                onRemindLater: onRemindLater,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
