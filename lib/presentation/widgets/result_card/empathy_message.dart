import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 공감 메시지 위젯 (인용구 스타일)
///
/// ResultCard는 항상 SingleChildScrollView 안에서 렌더링되므로
/// 메시지 전체를 잘림 없이 표시합니다.
class EmpathyMessage extends StatelessWidget {
  final String message;

  const EmpathyMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = AppTextStyles.body.copyWith(
      height: 1.7,
      fontSize: 15,
      color: theme.colorScheme.onSurface,
    );

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            message,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),

        // 인용문 아이콘
        Positioned(
          top: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.05);
  }
}
