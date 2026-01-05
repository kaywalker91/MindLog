import 'package:flutter/material.dart';

/// 설정 화면에서 사용되는 공통 위젯 컴포넌트
class SettingsComponents {
  SettingsComponents._();

  /// 섹션 헤더
  static Widget buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 설정 카드 컨테이너
  static Widget buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51), // 0.2 * 255 ≈ 51
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// 개별 설정 항목
  static Widget buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: titleColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: titleColor ?? colorScheme.onSurface,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.outline,
                ),
          ],
        ),
      ),
    );
  }

  /// 구분선
  static Widget buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outline.withAlpha(51),
    );
  }

  /// 버전 정보 트레일링 위젯
  static Widget buildVersionTrailing(
    BuildContext context, {
    required String label,
    required bool isReady,
  }) {
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
        Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
      ],
    );
  }

  /// AI 캐릭터 트레일링 위젯
  static Widget buildAiCharacterTrailing(BuildContext context, String label) {
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
        Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
      ],
    );
  }

  /// 스낵바 표시
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
