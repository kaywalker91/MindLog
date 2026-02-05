import 'package:flutter/material.dart';

/// 설정 화면의 카드 컨테이너 위젯
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51), // 0.2 * 255 ≈ 51
        ),
      ),
      child: Column(children: children),
    );
  }
}

/// 설정 섹션 헤더 위젯
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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
}

/// 설정 항목 구분선
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outline.withAlpha(51),
    );
  }
}

/// 설정 카드 내 서브그룹 간 구분선
///
/// [SettingsDivider]보다 강조된 구분선으로, 카드 내에서
/// 논리적으로 다른 기능 그룹을 시각적으로 분리합니다.
class SettingsGroupDivider extends StatelessWidget {
  const SettingsGroupDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        indent: 0,
        endIndent: 0,
        color: colorScheme.outlineVariant,
      ),
    );
  }
}
