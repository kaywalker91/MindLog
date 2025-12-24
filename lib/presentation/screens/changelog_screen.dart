import 'package:flutter/material.dart';
import '../../core/constants/app_changelog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/mindlog_app_bar.dart';

class ChangelogScreen extends StatelessWidget {
  final String version;
  final String? buildNumber;

  const ChangelogScreen({
    super.key,
    required this.version,
    this.buildNumber,
  });

  static void navigate(
    BuildContext context, {
    required String version,
    String? buildNumber,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangelogScreen(
          version: version,
          buildNumber: buildNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entry = AppChangelog.byVersion(version);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(
        title: Text('변경사항'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
        ),
        children: [
          _VersionHeader(
            version: version,
            buildNumber: buildNumber,
            title: entry?.title,
          ),
          const SizedBox(height: 16),
          if (entry == null) _buildEmptyState(context) else ..._buildSections(context, entry),
        ],
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, AppChangelogEntry entry) {
    final widgets = <Widget>[];
    for (var i = 0; i < entry.sections.length; i++) {
      widgets.add(_SectionCard(section: entry.sections[i]));
      if (i != entry.sections.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '변경사항 준비 중',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '현재 버전의 변경사항이 곧 업데이트됩니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionHeader extends StatelessWidget {
  final String version;
  final String? buildNumber;
  final String? title;

  const _VersionHeader({
    required this.version,
    required this.buildNumber,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            AppColors.statsPrimary,
            AppColors.statsSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.new_releases,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'v$version',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (buildNumber != null && buildNumber!.trim().isNotEmpty)
                      _buildChip('build ${buildNumber!.trim()}'),
                  ],
                ),
                if (title != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    title!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppChangelogSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
