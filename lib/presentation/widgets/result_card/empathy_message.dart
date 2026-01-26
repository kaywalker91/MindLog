import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 공감 메시지 위젯 (인용구 스타일)
class EmpathyMessage extends StatelessWidget {
  final String message;

  const EmpathyMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(
              height: 1.8,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          top: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).moveY(begin: 10);
  }
}
