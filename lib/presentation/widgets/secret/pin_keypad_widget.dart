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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Text(
          widget.title,
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: AppTextStyles.hint.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 36),
        _buildDotIndicator(colorScheme),
        const SizedBox(height: 48),
        _buildKeypad(colorScheme),
        if (widget.onForgotPin != null) ...[
          const SizedBox(height: 28),
          TextButton(
            onPressed: widget.onForgotPin,
            child: Text(
              '비밀번호를 잊으셨나요?',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// 에러 시 sin 파형 shake 애니메이션
  Widget _buildDotIndicator(ColorScheme colorScheme) {
    final dots = Row(
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
            color: filled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.primary : colorScheme.outline,
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

  Widget _buildKeypad(ColorScheme colorScheme) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 88, height: 72);
            if (key == 'del') return _buildDeleteKey(colorScheme);
            return _buildNumKey(key, colorScheme);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildNumKey(String digit, ColorScheme colorScheme) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onKeyTap(digit);
          },
          borderRadius: BorderRadius.circular(44),
          child: Center(
            child: Text(
              digit,
              style: AppTextStyles.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(ColorScheme colorScheme) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onBackspace();
          },
          borderRadius: BorderRadius.circular(44),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
