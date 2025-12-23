import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 로딩 인디케이터 위젯
class LoadingIndicator extends StatelessWidget {
  final String message;
  final String subMessage;
  final Color? accentColor;
  final Color? cardColor;
  final Color? subTextColor;

  const LoadingIndicator({
    super.key,
    this.message = '처리 중...',
    this.subMessage = 'AI가 당신의 마음을 분석하고 있어요...',
    this.accentColor,
    this.cardColor,
    this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    final surface = cardColor ?? Colors.white;
    final subText = subTextColor ?? Colors.grey.shade600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI 로딩 애니메이션
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 배경 원
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                // 뇌 아이콘
                Icon(
                  Icons.psychology,
                  size: 40,
                  color: accent,
                )
                    .animate(
                      onPlay: (controller) => WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.repeat();
                      }),
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(0.8, 0.8),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                    ),
                // 회전하는 원들
                ...List.generate(3, (index) {
                  final angle = (index * 120.0) * (3.14159 / 180);
                  return Positioned.fill(
                    child: Transform.rotate(
                      angle: angle,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(
                              onPlay: (controller) => WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.repeat();
                              }),
                              delay: const Duration(milliseconds: 100),
                            )
                            .scaleX(
                              begin: 1,
                              end: 0.3,
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scaleX(
                              begin: 0.3,
                              end: 1,
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 메시지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  message,
                  style: AppTextStyles.subtitle.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // 타이핑 효과 서브메시지
                Text(
                  subMessage,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: subText,
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 100))
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideY(begin: 0.2, duration: const Duration(milliseconds: 600)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 점 애니메이션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  .animate(
                    onPlay: (controller) => WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.repeat();
                    }),
                    delay: Duration(milliseconds: 100 * index), // 각 점마다 약간의 지연 추가 효과
                  )
                  .scaleX(
                    begin: 0.8,
                    end: 0.3,
                    duration: const Duration(milliseconds: 800),
                  )
                  .scaleY(
                    begin: 0.5,
                    end: 1.2,
                    duration: const Duration(milliseconds: 800),
                  )
                  .then(delay: const Duration(milliseconds: 400))
                  .scaleX(begin: 0.3, end: 1)
                  .scaleY(begin: 1.2, end: 0.5);
            }),
          ),
        ],
      ),
    );
  }
}
