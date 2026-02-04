import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../common/expandable_text.dart';

/// 공감 메시지 위젯 (인용구 스타일)
class EmpathyMessage extends StatelessWidget {
  final String message;

  /// 탭 시 전체 분석 내용을 보여주는 시트를 열기 위한 콜백
  final VoidCallback? onTapExpand;

  const EmpathyMessage({super.key, required this.message, this.onTapExpand});

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: ExpandableText(
            text: message,
            collapsedMaxLines: 4,
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
    );

    // onTapExpand 콜백이 있으면 GestureDetector로 래핑
    final widget = onTapExpand != null
        ? GestureDetector(
            onTap: onTapExpand,
            behavior: HitTestBehavior.opaque,
            child: content,
          )
        : content;

    return widget
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .moveY(begin: 10);
  }
}
