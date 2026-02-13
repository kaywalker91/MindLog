import 'package:flutter/material.dart';

/// 버전 정보 trailing 위젯
class VersionTrailing extends StatelessWidget {
  final String label;
  final bool isReady;

  const VersionTrailing({
    super.key,
    required this.label,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isReady) {
      return Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, color: colorScheme.outline),
      ],
    );
  }
}

/// 시간 선택 trailing 위젯
class TimeTrailing extends StatelessWidget {
  final String label;
  final bool enabled;

  const TimeTrailing({super.key, required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.outline),
        ],
      ],
    );
  }
}

/// AI 캐릭터 trailing 위젯
class AiCharacterTrailing extends StatelessWidget {
  final String label;

  const AiCharacterTrailing({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: colorScheme.outline),
      ],
    );
  }
}

/// 모드 선택 trailing 위젯
class ModeTrailing extends StatelessWidget {
  final String label;
  final bool enabled;

  const ModeTrailing({super.key, required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.outline),
        ],
      ],
    );
  }
}

/// 사용자 이름 trailing 위젯
class UserNameTrailing extends StatelessWidget {
  final String? userName;

  const UserNameTrailing({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = userName ?? '설정 안 함';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: userName != null
                ? colorScheme.onSurfaceVariant
                : colorScheme.outline,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: colorScheme.outline),
      ],
    );
  }
}
