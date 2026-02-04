import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 점진적 공개 패턴을 적용한 확장 가능한 텍스트 위젯
///
/// 긴 텍스트를 기본적으로 [collapsedMaxLines]줄로 접어두고,
/// "더 보기" 버튼으로 전체 내용을 펼칠 수 있음.
///
/// [showGradientFade]가 true이면 텍스트 하단에 그라데이션 페이드 효과를 적용하여
/// 텍스트가 축약되었음을 시각적으로 명확하게 표시합니다.
class ExpandableText extends StatefulWidget {
  final String text;
  final int collapsedMaxLines;
  final TextStyle? style;
  final TextAlign textAlign;
  final String expandText;
  final String collapseText;

  /// 축약 상태에서 텍스트 하단에 그라데이션 페이드 효과를 표시할지 여부
  final bool showGradientFade;

  const ExpandableText({
    super.key,
    required this.text,
    this.collapsedMaxLines = 3,
    this.style,
    this.textAlign = TextAlign.start,
    this.expandText = '더 보기',
    this.collapseText = '접기',
    this.showGradientFade = true,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    // Reduced Motion 접근성 지원
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animationDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return LayoutBuilder(
      builder: (context, constraints) {
        // TextPainter로 텍스트 초과 여부 감지
        final textSpan = TextSpan(text: widget.text, style: effectiveStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.collapsedMaxLines,
          textDirection: TextDirection.ltr,
          textAlign: widget.textAlign,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        final hasOverflow = textPainter.didExceedMaxLines;

        // 그라데이션 페이드용 색상 (테마 기반)
        final fadeColor = Theme.of(context).colorScheme.surface;

        return Column(
          crossAxisAlignment: _getCrossAxisAlignment(),
          children: [
            AnimatedCrossFade(
              duration: animationDuration,
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildCollapsedText(
                effectiveStyle,
                hasOverflow,
                fadeColor,
              ),
              secondChild: Text(
                widget.text,
                style: effectiveStyle,
                textAlign: widget.textAlign,
              ),
            ),
            if (hasOverflow)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _isExpanded ? widget.collapseText : widget.expandText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 축약된 텍스트 위젯 빌드 (그라데이션 페이드 옵션 포함)
  Widget _buildCollapsedText(
    TextStyle effectiveStyle,
    bool hasOverflow,
    Color fadeColor,
  ) {
    final textWidget = Text(
      widget.text,
      style: effectiveStyle,
      textAlign: widget.textAlign,
      maxLines: widget.collapsedMaxLines,
      overflow: TextOverflow.ellipsis,
    );

    // 그라데이션 페이드가 비활성화되거나 오버플로우가 없으면 그냥 텍스트 반환
    if (!widget.showGradientFade || !hasOverflow) {
      return textWidget;
    }

    // 그라데이션 페이드 효과 적용
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: textWidget,
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (widget.textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }
}
