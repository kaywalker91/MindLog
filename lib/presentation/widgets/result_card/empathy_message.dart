import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 공감 메시지 위젯 (인용구 스타일)
///
/// 메시지가 길 경우 기본 4줄로 축약 표시되며,
/// 하단 "전체보기/접기" 토글로 전체 내용을 확인할 수 있습니다.
class EmpathyMessage extends StatefulWidget {
  final String message;

  const EmpathyMessage({super.key, required this.message});

  @override
  State<EmpathyMessage> createState() => _EmpathyMessageState();
}

class _EmpathyMessageState extends State<EmpathyMessage> {
  static const int _collapsedMaxLines = 4;
  bool _isExpanded = false;

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = AppTextStyles.body.copyWith(
      height: 1.7,
      fontSize: 15,
      color: AppColors.textPrimary,
    );

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(text: widget.message, style: textStyle),
                maxLines: _collapsedMaxLines,
                textDirection: Directionality.of(context),
                textAlign: TextAlign.center,
              );
              textPainter.layout(maxWidth: constraints.maxWidth);
              final showToggle = textPainter.didExceedMaxLines;
              final showExpandedText = _isExpanded && showToggle;

              return Column(
                children: [
                  AnimatedCrossFade(
                    firstChild: Text(
                      widget.message,
                      style: textStyle,
                      textAlign: TextAlign.center,
                      maxLines: _collapsedMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      widget.message,
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                    crossFadeState: showExpandedText
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeInOut,
                  ),
                  if (showToggle) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _toggleExpanded,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  showExpandedText ? '접기' : '전체보기',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: showExpandedText ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
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
