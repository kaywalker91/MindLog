import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 4자리 PIN 입력 키패드 위젯
///
/// [errorCount]가 증가할 때마다 도트 인디케이터 shake 애니메이션 + PIN 초기화
class PinKeypadWidget extends StatefulWidget {
  /// 4자리 입력 완료 시 호출 (즉시 처리)
  final void Function(String pin) onPinCompleted;
  final String title;
  final String? subtitle;

  /// 증가 시 shake 애니메이션 트리거 + PIN 리셋
  final int errorCount;

  /// null이면 "비밀번호를 잊으셨나요?" 링크 미표시
  final VoidCallback? onForgotPin;

  const PinKeypadWidget({
    super.key,
    required this.onPinCompleted,
    required this.title,
    this.subtitle,
    this.errorCount = 0,
    this.onForgotPin,
  });

  @override
  State<PinKeypadWidget> createState() => _PinKeypadWidgetState();
}

class _PinKeypadWidgetState extends State<PinKeypadWidget> {
  static const int _pinLength = 4;
  String _pin = '';

  @override
  void didUpdateWidget(PinKeypadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 에러 발생 시 PIN 초기화
    if (widget.errorCount != oldWidget.errorCount && widget.errorCount > 0) {
      setState(() => _pin = '');
    }
  }

  void _onKeyTap(String digit) {
    if (_pin.length >= _pinLength) return;
    final newPin = _pin + digit;
    setState(() => _pin = newPin);
    if (newPin.length == _pinLength) {
      widget.onPinCompleted(newPin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = isCompact ? 16.0 : 20.0;
    final topSpacing = isCompact ? 20.0 : 28.0;
    final subtitleGap = isCompact ? 6.0 : 8.0;
    final dotGap = isCompact ? 26.0 : 34.0;
    final keypadGap = isCompact ? 30.0 : 44.0;
    final bottomSpacing = isCompact ? 16.0 : 20.0;

    return Container(
      key: const Key('secret_pin_content_card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.statsPrimary.withValues(alpha: 0.06),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.statsCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.statsPrimary.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topSpacing,
          horizontalPadding,
          bottomSpacing,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            if (widget.subtitle != null) ...[
              SizedBox(height: subtitleGap),
              Text(
                widget.subtitle!,
                style: AppTextStyles.hint.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: dotGap),
            _buildDotIndicator(),
            SizedBox(height: keypadGap),
            _buildKeypad(colorScheme, isCompact: isCompact),
            if (widget.onForgotPin != null) ...[
              SizedBox(height: isCompact ? 24 : 28),
              TextButton(
                onPressed: widget.onForgotPin,
                child: Text(
                  '비밀번호를 잊으셨나요?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.statsPrimaryDark,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.statsPrimaryDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 에러 시 sin 파형 shake 애니메이션
  Widget _buildDotIndicator() {
    final dots = Row(
      key: const Key('secret_pin_dot_row'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final filled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.statsPrimaryDark : Colors.transparent,
            border: Border.all(
              color: filled
                  ? AppColors.statsPrimaryDark
                  : AppColors.statsCardBorder,
              width: 1.5,
            ),
          ),
        );
      }),
    );

    if (widget.errorCount == 0) return dots;

    return dots
        .animate(key: ValueKey(widget.errorCount))
        .custom(
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) {
            // sin 파형 + 감쇠
            final offset = math.sin(value * math.pi * 8) * 10.0 * (1.0 - value);
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
        );
  }

  Widget _buildKeypad(ColorScheme colorScheme, {required bool isCompact}) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseKeyWidth = isCompact ? 80.0 : 88.0;
        final baseKeyHeight = isCompact ? 64.0 : 72.0;
        final maxWidthPerKey = constraints.maxWidth / 3;
        final keyWidth = math.min(baseKeyWidth, maxWidthPerKey);
        final scale = (keyWidth / baseKeyWidth).clamp(0.7, 1.0);
        final keyHeight = (baseKeyHeight * scale).clamp(52.0, baseKeyHeight);
        final rowGap = ((isCompact ? 10.0 : 14.0) * scale).clamp(8.0, 14.0);

        return Column(
          key: const Key('secret_pin_keypad'),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rows[i].map((key) {
                  if (key.isEmpty) {
                    return SizedBox(width: keyWidth, height: keyHeight);
                  }
                  if (key == 'del') {
                    return _buildDeleteKey(
                      colorScheme,
                      keyWidth: keyWidth,
                      keyHeight: keyHeight,
                    );
                  }
                  return _buildNumKey(
                    key,
                    colorScheme,
                    keyWidth: keyWidth,
                    keyHeight: keyHeight,
                  );
                }).toList(),
              ),
              if (i < rows.length - 1) SizedBox(height: rowGap),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNumKey(
    String digit,
    ColorScheme colorScheme, {
    required double keyWidth,
    required double keyHeight,
  }) {
    final borderRadius = BorderRadius.circular(keyHeight / 2);

    return SizedBox(
      width: keyWidth,
      height: keyHeight,
      child: Material(
        color: Color.alphaBlend(
          AppColors.statsPrimary.withValues(alpha: 0.10),
          colorScheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: AppColors.statsCardBorder),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onKeyTap(digit);
          },
          borderRadius: borderRadius,
          splashColor: AppColors.statsPrimary.withValues(alpha: 0.24),
          highlightColor: AppColors.statsPrimary.withValues(alpha: 0.15),
          child: Center(
            child: Text(
              digit,
              style: AppTextStyles.title.copyWith(
                fontSize: (keyHeight * 0.38).clamp(20.0, 26.0),
                fontWeight: FontWeight.w500,
                color: AppColors.statsTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(
    ColorScheme colorScheme, {
    required double keyWidth,
    required double keyHeight,
  }) {
    final borderRadius = BorderRadius.circular(keyHeight / 2);

    return SizedBox(
      width: keyWidth,
      height: keyHeight,
      child: Material(
        color: Color.alphaBlend(
          AppColors.statsPrimary.withValues(alpha: 0.10),
          colorScheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: AppColors.statsCardBorder),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onBackspace();
          },
          borderRadius: borderRadius,
          splashColor: AppColors.statsPrimary.withValues(alpha: 0.24),
          highlightColor: AppColors.statsPrimary.withValues(alpha: 0.15),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: AppColors.statsPrimaryDark,
              size: (keyHeight * 0.34).clamp(20.0, 24.0),
            ),
          ),
        ),
      ),
    );
  }
}
