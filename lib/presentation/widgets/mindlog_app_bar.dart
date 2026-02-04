import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// MindLog 전용 그라데이션 AppBar
class MindlogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final double? leadingWidth;
  final double toolbarHeight;

  const MindlogAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.bottom,
    this.leading,
    this.leadingWidth,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
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
      iconTheme: IconThemeData(color: onPrimary),
      actionsIconTheme: IconThemeData(color: onPrimary),
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: onPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      bottom: bottom,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.statsPrimary, AppColors.statsSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -28,
            top: -20,
            child: _buildAccentBubble(
              color: onPrimary.withValues(alpha: 0.16),
              size: 90,
            ),
          ),
          Positioned(
            left: -18,
            bottom: -26,
            child: _buildAccentBubble(
              color: onPrimary.withValues(alpha: 0.12),
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
                    onPrimary.withValues(alpha: 0.0),
                    onPrimary.withValues(alpha: 0.35),
                    onPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
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
