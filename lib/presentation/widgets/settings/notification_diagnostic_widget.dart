import 'package:flutter/material.dart';

import '../../../core/services/notification_diagnostic_service.dart';
import '../../../core/services/notification_permission_service.dart';

enum _StatusTone { positive, warning, neutral }

class _DiagnosticVisualTokens {
  final Color headerForeground;
  final Color tileBackground;
  final Color tileTitleForeground;
  final Color neutralIconForeground;
  final Color neutralIconBackground;
  final Color summaryPositiveBackground;
  final Color summaryPositiveForeground;
  final Color summaryWarningBackground;
  final Color summaryWarningForeground;
  final Color chipPositiveBackground;
  final Color chipPositiveForeground;
  final Color chipWarningBackground;
  final Color chipWarningForeground;
  final Color chipNeutralBackground;
  final Color chipNeutralForeground;
  final Color actionBackground;
  final Color actionForeground;
  final Color actionBorder;

  const _DiagnosticVisualTokens({
    required this.headerForeground,
    required this.tileBackground,
    required this.tileTitleForeground,
    required this.neutralIconForeground,
    required this.neutralIconBackground,
    required this.summaryPositiveBackground,
    required this.summaryPositiveForeground,
    required this.summaryWarningBackground,
    required this.summaryWarningForeground,
    required this.chipPositiveBackground,
    required this.chipPositiveForeground,
    required this.chipWarningBackground,
    required this.chipWarningForeground,
    required this.chipNeutralBackground,
    required this.chipNeutralForeground,
    required this.actionBackground,
    required this.actionForeground,
    required this.actionBorder,
  });

  factory _DiagnosticVisualTokens.of(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return _DiagnosticVisualTokens(
      headerForeground: colorScheme.onSurfaceVariant,
      tileBackground: colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.67 : 0.42,
      ),
      tileTitleForeground: colorScheme.onSurface,
      neutralIconForeground: colorScheme.onSurfaceVariant.withValues(alpha: 0.86),
      neutralIconBackground: colorScheme.surfaceContainer.withValues(
        alpha: isDark ? 0.86 : 1.0,
      ),
      summaryPositiveBackground: isDark
          ? const Color(0xFF22362A)
          : const Color(0xFFE8F3EA),
      summaryPositiveForeground: isDark
          ? const Color(0xFFA5D6A7)
          : const Color(0xFF1D5E2D),
      summaryWarningBackground: isDark
          ? const Color(0xFF3A2C1D)
          : const Color(0xFFFFF1E2),
      summaryWarningForeground: isDark
          ? const Color(0xFFFFCC80)
          : const Color(0xFF8A4E00),
      chipPositiveBackground: isDark
          ? const Color(0xFF1E3226)
          : const Color(0xFFE8F3EA),
      chipPositiveForeground: isDark
          ? const Color(0xFFA5D6A7)
          : const Color(0xFF1D5E2D),
      chipWarningBackground: isDark
          ? const Color(0xFF35281A)
          : const Color(0xFFFFF1E2),
      chipWarningForeground: isDark
          ? const Color(0xFFFFCC80)
          : const Color(0xFF8A4E00),
      chipNeutralBackground: colorScheme.surfaceContainerHigh.withValues(
        alpha: isDark ? 0.82 : 1.0,
      ),
      chipNeutralForeground: colorScheme.onSurfaceVariant.withValues(alpha: 0.90),
      actionBackground: colorScheme.surfaceContainerHigh.withValues(
        alpha: isDark ? 0.71 : 0.59,
      ),
      actionForeground: colorScheme.onSurfaceVariant,
      actionBorder: colorScheme.outline.withValues(alpha: isDark ? 0.55 : 0.47),
    );
  }

  Color chipBackground(_StatusTone tone) {
    switch (tone) {
      case _StatusTone.positive:
        return chipPositiveBackground;
      case _StatusTone.warning:
        return chipWarningBackground;
      case _StatusTone.neutral:
        return chipNeutralBackground;
    }
  }

  Color chipForeground(_StatusTone tone) {
    switch (tone) {
      case _StatusTone.positive:
        return chipPositiveForeground;
      case _StatusTone.warning:
        return chipWarningForeground;
      case _StatusTone.neutral:
        return chipNeutralForeground;
    }
  }
}

/// 사용자 친화적 알림 건강 상태 디스플레이
class NotificationDiagnosticWidget extends StatefulWidget {
  const NotificationDiagnosticWidget({super.key});

  @override
  State<NotificationDiagnosticWidget> createState() =>
      _NotificationDiagnosticWidgetState();
}

class _NotificationDiagnosticWidgetState
    extends State<NotificationDiagnosticWidget>
    with SingleTickerProviderStateMixin {
  Future<NotificationDiagnosticData>? _diagnosticFuture;
  late final AnimationController _refreshController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _diagnosticFuture = NotificationDiagnosticService.collect();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _refresh() {
    _refreshController.forward(from: 0);
    setState(() {
      _diagnosticFuture = NotificationDiagnosticService.collect();
    });
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  Future<void> _handleExactAlarmFix() async {
    await NotificationPermissionService.requestExactAlarmPermission();
    if (mounted) _refresh();
  }

  Future<void> _handleBatteryFix() async {
    await NotificationPermissionService.requestDisableBatteryOptimization();
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<NotificationDiagnosticData>(
      future: _diagnosticFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '알림 상태를 확인하고 있어요...',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          child: _DiagnosticContent(
            key: ValueKey(data.hashCode),
            data: data,
            refreshController: _refreshController,
            isCollapsed: _isCollapsed,
            onRefresh: _refresh,
            onToggleCollapse: _toggleCollapsed,
            onExactAlarmFix: _handleExactAlarmFix,
            onBatteryFix: _handleBatteryFix,
          ),
        );
      },
    );
  }
}

class _DiagnosticContent extends StatelessWidget {
  final NotificationDiagnosticData data;
  final AnimationController refreshController;
  final bool isCollapsed;
  final VoidCallback onRefresh;
  final VoidCallback onToggleCollapse;
  final VoidCallback onExactAlarmFix;
  final VoidCallback onBatteryFix;

  const _DiagnosticContent({
    super.key,
    required this.data,
    required this.refreshController,
    required this.isCollapsed,
    required this.onRefresh,
    required this.onToggleCollapse,
    required this.onExactAlarmFix,
    required this.onBatteryFix,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = _DiagnosticVisualTokens.of(colorScheme);
    final cheerMeCount = data.pendingNotifications
        .where((n) => n.id == 1001)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: tokens.headerForeground,
              ),
              const SizedBox(width: 6),
              Text(
                '알림 상태',
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.headerForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: refreshController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: tokens.headerForeground,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onToggleCollapse,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                    size: 18,
                    color: tokens.headerForeground,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isCollapsed
                ? const SizedBox.shrink(key: ValueKey('diagnostic-collapsed'))
                : Column(
                    key: const ValueKey('diagnostic-expanded'),
                    children: [
                      const SizedBox(height: 8),
                      // Summary Banner
                      _DiagnosticSummaryBanner(
                        data: data,
                        cheerMeCount: cheerMeCount,
                        tokens: tokens,
                      ),
                      const SizedBox(height: 8),

                      // Status Tiles
                      _DiagnosticStatusTile(
                        icon: Icons.notifications_active_outlined,
                        title: '알림 예약',
                        statusText: cheerMeCount > 0
                            ? '$cheerMeCount개 예약됨'
                            : '없음',
                        statusTone: cheerMeCount > 0
                            ? _StatusTone.positive
                            : _StatusTone.warning,
                      ),
                      const SizedBox(height: 8),
                      _DiagnosticStatusTile(
                        icon: Icons.alarm_on_outlined,
                        title: '정확한 알람',
                        statusText: !data.hasExactAlarmIssue ? '허용됨' : '권한 필요',
                        statusTone: !data.hasExactAlarmIssue
                            ? _StatusTone.positive
                            : _StatusTone.warning,
                        actionLabel: data.hasExactAlarmIssue ? '설정' : null,
                        onAction: data.hasExactAlarmIssue
                            ? onExactAlarmFix
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _DiagnosticStatusTile(
                        icon: Icons.battery_saver_outlined,
                        title: '배터리 최적화',
                        statusText: !data.hasBatteryIssue ? '제외됨' : '활성',
                        statusTone: !data.hasBatteryIssue
                            ? _StatusTone.positive
                            : _StatusTone.warning,
                        actionLabel: data.hasBatteryIssue ? '해제' : null,
                        onAction: data.hasBatteryIssue ? onBatteryFix : null,
                      ),
                      const SizedBox(height: 8),
                      _DiagnosticStatusTile(
                        icon: Icons.language_outlined,
                        title: '시간대',
                        statusText: data.timezoneName,
                        statusTone: _StatusTone.neutral,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticSummaryBanner extends StatelessWidget {
  final NotificationDiagnosticData data;
  final int cheerMeCount;
  final _DiagnosticVisualTokens tokens;

  const _DiagnosticSummaryBanner({
    required this.data,
    required this.cheerMeCount,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Count fixable issues (permissions the user can act on)
    final issueCount = [
      data.hasExactAlarmIssue,
      data.hasBatteryIssue,
      data.hasNotificationIssue,
    ].where((e) => e).length;

    final hasIssue = data.hasAnyIssue || cheerMeCount == 0;
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String message;

    if (!hasIssue) {
      bgColor = tokens.summaryPositiveBackground;
      fgColor = tokens.summaryPositiveForeground;
      icon = Icons.check_circle_rounded;
      message = '모든 알림이 정상이에요';
    } else {
      bgColor = tokens.summaryWarningBackground;
      fgColor = tokens.summaryWarningForeground;
      icon = Icons.info_outline_rounded;
      message = issueCount > 0 ? '$issueCount개 항목을 확인해주세요' : '알림 예약을 확인해주세요';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusText;
  final _StatusTone statusTone;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DiagnosticStatusTile({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.statusTone,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = _DiagnosticVisualTokens.of(colorScheme);
    final hasAction = actionLabel != null && onAction != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.tileBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Circular icon background
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tokens.neutralIconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tokens.neutralIconForeground),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.tileTitleForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Trailing: action chip or status chip
          if (hasAction)
            _ActionChip(label: actionLabel!, onTap: onAction!, tokens: tokens)
          else
            _StatusChip(text: statusText, tone: statusTone, tokens: tokens),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final _StatusTone tone;
  final _DiagnosticVisualTokens tokens;

  const _StatusChip({
    required this.text,
    required this.tone,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bgColor = tokens.chipBackground(tone);
    final fgColor = tokens.chipForeground(tone);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _DiagnosticVisualTokens tokens;

  const _ActionChip({
    required this.label,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tokens.actionBackground,
          border: Border.all(color: tokens.actionBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: tokens.actionForeground,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 13, color: tokens.actionForeground),
          ],
        ),
      ),
    );
  }
}
