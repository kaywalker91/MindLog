import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/cheer_me_section_palette.dart';

void main() {
  group('CheerMeSectionPalette', () {
    test('light palette tokens should match sky design spec', () {
      final palette = CheerMeSectionPalette.light();

      expect(palette.signatureSky, const Color(0xFF7EC8E3));
      expect(palette.deepSky, const Color(0xFF5BA4C9));
      expect(palette.selectedChipBackground, const Color(0xFFEAF6FC));
      expect(palette.selectedChipText, const Color(0xFF245D79));
      expect(palette.selectedChipBorder, const Color(0xFF7EC8E3));
      expect(palette.unselectedChipBackground, const Color(0xFFF3F8FC));
      expect(palette.unselectedChipText, const Color(0xFF6F8596));
      expect(palette.selectedSuggestionBackground, const Color(0xFFE6F4FB));
      expect(palette.selectedSuggestionText, const Color(0xFF245D79));
      expect(palette.selectedSuggestionBorder, const Color(0xFF7EC8E3));
      expect(palette.unselectedSuggestionBackground, const Color(0xFFF7FAFD));
      expect(palette.unselectedSuggestionText, const Color(0xFF5F7485));
      expect(palette.footerHintText, const Color(0xFF7F8C9A));
    });

    test('dark fallback should use readable color scheme roles', () {
      const colorScheme = ColorScheme.dark(
        primary: Color(0xFF80C8FF),
        primaryContainer: Color(0xFF17486A),
        secondary: Color(0xFF88D7D1),
        secondaryContainer: Color(0xFF1E4E4A),
        onSecondaryContainer: Color(0xFFE2FFFB),
        surfaceContainerHighest: Color(0xFF2E3235),
        surfaceContainerHigh: Color(0xFF282C2F),
        onSurfaceVariant: Color(0xFFC3C8CE),
        outline: Color(0xFF8A9199),
      );

      final palette = CheerMeSectionPalette.darkFallback(colorScheme);

      expect(palette.signatureSky, colorScheme.primary);
      expect(palette.deepSky, colorScheme.primaryContainer);
      expect(palette.selectedChipBackground, colorScheme.secondaryContainer);
      expect(palette.selectedChipText, colorScheme.onSecondaryContainer);
      expect(palette.selectedChipBorder, colorScheme.secondary);
      expect(
        palette.unselectedChipBackground,
        colorScheme.surfaceContainerHighest,
      );
      expect(palette.unselectedChipText, colorScheme.onSurfaceVariant);
      expect(
        palette.selectedSuggestionBackground,
        colorScheme.secondaryContainer,
      );
      expect(palette.selectedSuggestionText, colorScheme.onSecondaryContainer);
      expect(palette.selectedSuggestionBorder, colorScheme.secondary);
      expect(
        palette.unselectedSuggestionBackground,
        colorScheme.surfaceContainerHigh,
      );
      expect(palette.unselectedSuggestionText, colorScheme.onSurfaceVariant);
      expect(palette.footerHintText, colorScheme.outline);
    });
  });
}
