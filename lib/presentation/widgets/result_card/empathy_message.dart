import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 공감 메시지 위젯 (인용구 스타일)
///
/// 메시지가 3줄 이상일 경우 축약 표시되며,
/// 탭하면 인라인으로 확장되어 전체 내용을 표시합니다.
class EmpathyMessage extends StatefulWidget {
  final String message;

  const EmpathyMessage({super.key, required this.message});

  @override
  State<EmpathyMessage> createState() => _EmpathyMessageState();
}

class _EmpathyMessageState extends State<EmpathyMessage> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfNeedsExpansion();
  }

  void _checkIfNeedsExpansion() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: AppTextStyles.body.copyWith(
          height: 1.7,
          fontSize: 15,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );

    // 대략적인 카드 너비 추정 (패딩 48px 제외)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 32 - 48; // 화면 패딩 32 + 카드 내부 패딩 48

    textPainter.layout(maxWidth: cardWidth);

    setState(() {
      _needsExpansion = textPainter.didExceedMaxLines;
    });
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showToggle = _needsExpansion;

    return GestureDetector(
      onTap: showToggle ? _toggleExpanded : null,
      child: Stack(
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
            child: Column(
              children: [
                // 공감 메시지 텍스트
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.message,
                    style: AppTextStyles.body.copyWith(
                      height: 1.7,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    widget.message,
                    style: AppTextStyles.body.copyWith(
                      height: 1.7,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                ),

                // 전체 보기 / 접기 힌트
                if (showToggle) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? '접기' : '전체 보기',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.05);
  }
}
