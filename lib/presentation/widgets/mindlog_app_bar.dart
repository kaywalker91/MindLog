import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/statistics_theme_tokens.dart';

enum MindlogAppBarVariant { defaultStyle, statistics }

/// MindLog 전용 그라데이션 AppBar
class MindlogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final double? leadingWidth;
  final double toolbarHeight;
  final MindlogAppBarVariant variant;

  const MindlogAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.bottom,
    this.leading,
    this.leadingWidth,
    this.toolbarHeight = kToolbarHeight,
    this.variant = MindlogAppBarVariant.defaultStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsTokens = StatisticsThemeTokens.of(context);
    final isStatistics = variant == MindlogAppBarVariant.statistics;
    final titleColor = isStatistics
        ? (colorScheme.brightness == Brightness.dark
              ? statsTokens.textPrimary
              : colorScheme.onPrimary)
        : colorScheme.onPrimary;
    final gradientColors = isStatistics
        ? [statsTokens.appBarGradientStart, statsTokens.appBarGradientEnd]
        : [AppColors.statsPrimary, AppColors.statsSecondary];
    final bubbleOpacityA = isStatistics ? 0.1 : 0.16;
    final bubbleOpacityB = isStatistics ? 0.07 : 0.12;
    final dividerMidOpacity = isStatistics ? 0.26 : 0.35;

    return AppBar(
      title: title,
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      leadingWidth: leadingWidth,
      toolbarHeight: toolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: titleColor),
      actionsIconTheme: IconThemeData(color: titleColor),
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: titleColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      bottom: bottom,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -28,
              top: -20,
              child: _buildAccentBubble(
                color: statsTokens.appBarBubble.withValues(
                  alpha: bubbleOpacityA,
                ),
                size: 90,
              ),
            ),
            Positioned(
              left: -18,
              bottom: -26,
              child: _buildAccentBubble(
                color: statsTokens.appBarBubble.withValues(
                  alpha: bubbleOpacityB,
                ),
                size: 76,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statsTokens.appBarDivider.withValues(alpha: 0.0),
                      statsTokens.appBarDivider.withValues(
                        alpha: dividerMidOpacity,
                      ),
                      statsTokens.appBarDivider.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAccentBubble({
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
