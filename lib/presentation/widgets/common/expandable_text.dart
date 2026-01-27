import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 점진적 공개 패턴을 적용한 확장 가능한 텍스트 위젯
///
/// 긴 텍스트를 기본적으로 [collapsedMaxLines]줄로 접어두고,
/// "더 보기" 버튼으로 전체 내용을 펼칠 수 있음.
class ExpandableText extends StatefulWidget {
  final String text;
  final int collapsedMaxLines;
  final TextStyle? style;
  final TextAlign textAlign;
  final String expandText;
  final String collapseText;

  const ExpandableText({
    super.key,
    required this.text,
    this.collapsedMaxLines = 3,
    this.style,
    this.textAlign = TextAlign.start,
    this.expandText = '더 보기',
    this.collapseText = '접기',
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
    final animationDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

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

        return Column(
          crossAxisAlignment: _getCrossAxisAlignment(),
          children: [
            AnimatedCrossFade(
              duration: animationDuration,
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.text,
                style: effectiveStyle,
                textAlign: widget.textAlign,
                maxLines: widget.collapsedMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.text,
                style: effectiveStyle,
                textAlign: widget.textAlign,
              ),
            ),
            if (hasOverflow)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded ? widget.collapseText : widget.expandText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
