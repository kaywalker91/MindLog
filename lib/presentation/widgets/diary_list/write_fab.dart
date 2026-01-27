import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 일기 작성 FAB
class WriteFab extends StatefulWidget {
  final VoidCallback onPressed;

  const WriteFab({super.key, required this.onPressed});

  @override
  State<WriteFab> createState() => _WriteFabState();
}

class _WriteFabState extends State<WriteFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(28));

    return Tooltip(
      message: '오늘 기록하기',
      child: Semantics(
        button: true,
        label: '오늘 기록하기',
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.mediumImpact();
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.statsPrimary.withValues(
                      alpha: _isPressed ? 0.2 : 0.35,
                    ),
                    blurRadius: _isPressed ? 4 : 12,
                    offset: Offset(0, _isPressed ? 2 : 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.statsPrimary,
                        AppColors.statsSecondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: AppColors.statsPrimaryDark.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '오늘 기록하기',
                        style: AppTextStyles.button.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
