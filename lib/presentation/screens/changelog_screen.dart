import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../providers/update_provider.dart';
import '../widgets/mindlog_app_bar.dart';

class ChangelogScreen extends ConsumerWidget {
  final String version;
  final String? buildNumber;

  const ChangelogScreen({
    super.key,
    required this.version,
    this.buildNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final configAsync = ref.watch(updateConfigProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(
        title: Text('변경사항'),
      ),
      body: configAsync.when(
        loading: () => _buildLoadingState(context),
        error: (_, _) => _buildErrorState(context, ref),
        data: (config) => _buildContent(context, config),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '변경사항을 불러올 수 없어요',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.refresh(updateConfigProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UpdateConfig config) {
    final versions = _sortedVersions(config.changelog.keys);
    final latestVersion = config.latestVersion;
    final primaryVersion =
        versions.contains(latestVersion) ? latestVersion : (versions.isNotEmpty ? versions.first : latestVersion);
    final primaryNotes = config.notesFor(primaryVersion);
    final previousVersions = versions.where((v) => v != primaryVersion).toList();

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
      ),
      children: [
        _VersionHeader(
          latestVersion: primaryVersion,
          currentVersion: version,
          buildNumber: buildNumber,
        ),
        const SizedBox(height: 16),
        if (primaryNotes.isEmpty)
          _buildEmptyState(
            context,
            title: '변경사항 준비 중',
            message: '최신 버전의 변경사항이 아직 등록되지 않았어요.',
          )
        else
          _ChangelogCard(
            version: primaryVersion,
            items: primaryNotes,
            isLatest: true,
          ),
        if (previousVersions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionTitle(context, '이전 변경사항'),
          const SizedBox(height: 12),
          ...previousVersions.map(
            (version) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChangelogCard(
                version: version,
                items: config.notesFor(version),
                isExpandable: true,
                initiallyExpanded: false,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
  }) {
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
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _sortedVersions(Iterable<String> versions) {
    final list = versions.map((version) => version.trim()).where((v) => v.isNotEmpty).toList();
    list.sort((a, b) => _compareVersions(b, a));
    return list;
  }

  int _compareVersions(String current, String target) {
    final currentParts = _parseVersion(current);
    final targetParts = _parseVersion(target);
    final length = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < length; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final targetValue = i < targetParts.length ? targetParts[i] : 0;
      if (currentValue != targetValue) {
        return currentValue.compareTo(targetValue);
      }
    }
    return 0;
  }

  List<int> _parseVersion(String version) {
    final normalized = version.split('+').first.trim();
    if (normalized.isEmpty) {
      return const [0];
    }
    return normalized.split('.').map((part) {
      final match = RegExp(r'\d+').firstMatch(part);
      if (match == null) return 0;
      return int.parse(match.group(0)!);
    }).toList();
  }
}

class _VersionHeader extends StatelessWidget {
  final String latestVersion;
  final String currentVersion;
  final String? buildNumber;

  const _VersionHeader({
    required this.latestVersion,
    required this.currentVersion,
    required this.buildNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLabel = _currentLabel();

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
                Text(
                  '최신 변경사항',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'v$latestVersion',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (currentLabel.isNotEmpty) _buildChip(currentLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currentLabel() {
    final trimmedBuild = buildNumber?.trim();
    if (trimmedBuild != null && trimmedBuild.isNotEmpty) {
      return '현재 v$currentVersion (build $trimmedBuild)';
    }
    if (currentVersion.trim().isEmpty) {
      return '';
    }
    return '현재 v$currentVersion';
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

class _ChangelogCard extends StatefulWidget {
  final String version;
  final List<String> items;
  final bool isLatest;
  final bool isExpandable;
  final bool initiallyExpanded;

  const _ChangelogCard({
    required this.version,
    required this.items,
    this.isLatest = false,
    this.isExpandable = false,
    this.initiallyExpanded = false,
  });

  @override
  State<_ChangelogCard> createState() => _ChangelogCardState();
}

class _ChangelogCardState extends State<_ChangelogCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpandable ? widget.initiallyExpanded : true;
  }

  @override
  void didUpdateWidget(covariant _ChangelogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpandable != widget.isExpandable ||
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.isExpandable ? widget.initiallyExpanded : true;
    }
  }

  void _toggleExpanded() {
    if (!widget.isExpandable) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = widget.isLatest
        ? AppColors.statsPrimary.withValues(alpha: 0.12)
        : colorScheme.surface;
    final borderColor = widget.isLatest
        ? AppColors.statsPrimary.withValues(alpha: 0.35)
        : colorScheme.outline.withValues(alpha: 0.16);
    final showItems = widget.isExpandable ? _isExpanded : true;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.isExpandable ? _toggleExpanded : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'v${widget.version}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (widget.isExpandable)
                      Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: colorScheme.outline,
                      ),
                  ],
                ),
                if (showItems) const SizedBox(height: 10),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: showItems
                      ? _buildItems(theme, colorScheme)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItems(ThemeData theme, ColorScheme colorScheme) {
    if (widget.items.isEmpty) {
      return Text(
        '변경사항 정보가 없습니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.items
          .map(
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
          )
          .toList(),
    );
  }
}
