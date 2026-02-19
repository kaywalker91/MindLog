import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/statistics_theme_tokens.dart';

void main() {
  group('StatisticsThemeTokens', () {
    test('라이트/다크 토큰이 필수 값을 제공해야 한다', () {
      expect(StatisticsThemeTokens.light.pageBackground, isA<Color>());
      expect(StatisticsThemeTokens.light.textPrimary, isA<Color>());
      expect(StatisticsThemeTokens.dark.pageBackground, isA<Color>());
      expect(StatisticsThemeTokens.dark.textPrimary, isA<Color>());
      expect(
        StatisticsThemeTokens.light.microMotionMs,
        inInclusiveRange(160, 220),
      );
      expect(
        StatisticsThemeTokens.dark.microMotionMs,
        inInclusiveRange(160, 220),
      );
    });

    test('라이트 토큰의 텍스트 대비가 WCAG AA(4.5:1) 이상이어야 한다', () {
      const t = StatisticsThemeTokens.light;
      expect(
        _contrastRatio(t.textPrimary, t.pageBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(t.textSecondary, t.cardBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(t.textTertiary, t.cardBackground),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('다크 토큰의 텍스트 대비가 WCAG AA(4.5:1) 이상이어야 한다', () {
      const t = StatisticsThemeTokens.dark;
      expect(
        _contrastRatio(t.textPrimary, t.pageBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(t.textSecondary, t.cardBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(t.textTertiary, t.cardBackground),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('네비게이션 선택/비선택 상태가 식별 가능한 대비를 가져야 한다', () {
      const light = StatisticsThemeTokens.light;
      const dark = StatisticsThemeTokens.dark;

      expect(
        _contrastRatio(light.navSelected, light.navIndicator),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(light.navUnselected, light.navGradientBottom),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(dark.navSelected, dark.navIndicator),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(dark.navUnselected, dark.navGradientBottom),
        greaterThanOrEqualTo(3.0),
      );
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final lighter = aLum > bLum ? aLum : bLum;
  final darker = aLum > bLum ? bLum : aLum;
  return (lighter + 0.05) / (darker + 0.05);
}
