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

  const ChangelogScreen({super.key, required this.version, this.buildNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final configAsync = ref.watch(updateConfigProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(title: Text('변경사항')),
      body: configAsync.when(
        loading: () => _buildLoadingState(context),
        error: (_, _) => _buildErrorState(context, ref),
        data: (config) => _buildContent(context, ref, config),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UpdateConfig config,
  ) {
    final paginatedVersions = ref.watch(paginatedVersionsProvider);
    final hasMore = ref.watch(hasMoreChangelogProvider);
    final latestVersion = config.latestVersion;

    // 최신 버전은 항상 첫 번째에 고정
    final primaryVersion = paginatedVersions.contains(latestVersion)
        ? latestVersion
        : (paginatedVersions.isNotEmpty
              ? paginatedVersions.first
              : latestVersion);
    final primaryNotes = config.notesFor(primaryVersion);
    final previousVersions = paginatedVersions
        .where((v) => v != primaryVersion)
        .toList();

    // 아이템 개수: Header(1) + Latest Card(1) + Section Title(1, 조건부) + Previous Cards + Bottom Buttons(1, 항상)
    final hasPreviousVersions = previousVersions.isNotEmpty;
    final hasLoadedMore = ref.watch(hasLoadedMoreChangelogProvider);
    final showBottomButtons = hasMore || hasLoadedMore;
    final itemCount =
        2 + // Header + Latest
        (hasPreviousVersions ? 1 : 0) + // Section Title
        previousVersions.length +
        (showBottomButtons ? 1 : 0); // Bottom Buttons

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Index 0: Header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _VersionHeader(
              latestVersion: primaryVersion,
              currentVersion: version,
              buildNumber: buildNumber,
            ),
          );
        }

        // Index 1: Latest Card or Empty State
        if (index == 1) {
          if (primaryNotes.isEmpty) {
            return _buildEmptyState(
              context,
              title: '변경사항 준비 중',
              message: '최신 버전의 변경사항이 아직 등록되지 않았어요.',
            );
          }
          return _ChangelogCard(
            version: primaryVersion,
            items: primaryNotes,
            isLatest: true,
          );
        }

        // Index 2: Section Title (if previous versions exist)
        if (index == 2 && hasPreviousVersions) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: _buildSectionHeader(context, ref, '이전 변경사항'),
          );
        }

        // Previous version cards
        final previousIndex = index - (hasPreviousVersions ? 3 : 2);
        if (previousIndex >= 0 && previousIndex < previousVersions.length) {
          final versionStr = previousVersions[previousIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChangelogCard(
              version: versionStr,
              items: config.notesFor(versionStr),
              isExpandable: true,
            ),
          );
        }

        // Bottom buttons (Load More / Collapse)
        if (showBottomButtons) {
          return _buildBottomButtons(context, ref);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBottomButtons(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMore = ref.watch(hasMoreChangelogProvider);
    final hasLoadedMore = ref.watch(hasLoadedMoreChangelogProvider);

    // 둘 다 표시할 것이 없으면 빈 위젯
    if (!hasMore && !hasLoadedMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "다시 접기" 버튼 (pageIndex > 0일 때만)
          if (hasLoadedMore)
            TextButton.icon(
              onPressed: () {
                ref.read(changelogPageIndexProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.expand_less, size: 18),
              label: const Text('다시 접기'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.outline,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // 버튼 사이 간격
          if (hasLoadedMore && hasMore) const SizedBox(width: 8),

          // "이전 버전 더보기" 버튼 (더 불러올 데이터가 있을 때만)
          if (hasMore)
            TextButton.icon(
              onPressed: () {
                ref.read(changelogPageIndexProvider.notifier).state++;
              },
              icon: const Icon(Icons.expand_more, size: 18),
              label: const Text('이전 버전 더보기'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
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
    final colorScheme = theme.colorScheme;
    final headerFg = colorScheme.onPrimary;
    final currentLabel = _currentLabel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.statsPrimary, AppColors.statsSecondary],
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
              color: headerFg.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.new_releases, color: headerFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최신 변경사항',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: headerFg.withValues(alpha: 0.9),
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
                        color: headerFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (currentLabel.isNotEmpty)
                      _buildChip(currentLabel, headerFg),
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

  Widget _buildChip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
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

  const _ChangelogCard({
    required this.version,
    required this.items,
    this.isLatest = false,
    this.isExpandable = false,
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
    // 확장 가능한 카드는 처음에 접힌 상태로 시작
    _isExpanded = !widget.isExpandable;
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
            color: colorScheme.shadow.withValues(alpha: 0.04),
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
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
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
