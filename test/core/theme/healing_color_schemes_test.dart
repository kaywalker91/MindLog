import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/healing_color_schemes.dart';

void main() {
  group('HealingColorSchemes', () {
    test('mutedTeal palette values should match spec', () {
      const scheme = HealingColorSchemes.mutedTeal;

      expect(scheme.primary, const Color(0xFF2E7D86));
      expect(scheme.secondary, const Color(0xFFA5673A));
      expect(HealingColorSchemes.mutedTealBackground, const Color(0xFFF8F5F1));
      expect(scheme.surface, const Color(0xFFFFFDFC));
      expect(scheme.error, const Color(0xFFB84C4C));
    });

    test('pastelComfort palette values should match spec', () {
      const scheme = HealingColorSchemes.pastelComfort;

      expect(scheme.primary, const Color(0xFF66AFA8));
      expect(scheme.secondary, const Color(0xFFD79680));
      expect(
        HealingColorSchemes.pastelComfortBackground,
        const Color(0xFFFFF8F4),
      );
      expect(scheme.surface, const Color(0xFFFFFCFA));
      expect(scheme.error, const Color(0xFFB65050));
    });

    test('resolve should return the correct scheme by mode', () {
      expect(
        HealingColorSchemes.resolve(HealingPaletteMode.mutedTeal),
        HealingColorSchemes.mutedTeal,
      );
      expect(
        HealingColorSchemes.resolve(HealingPaletteMode.pastelComfort),
        HealingColorSchemes.pastelComfort,
      );
    });
  });
}
