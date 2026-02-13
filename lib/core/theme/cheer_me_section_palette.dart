import 'package:flutter/material.dart';

/// Cheer Me 추천 영역(칩/추천 문구/하단 안내) 전용 팔레트
class CheerMeSectionPalette {
  const CheerMeSectionPalette({
    required this.signatureSky,
    required this.deepSky,
    required this.selectedChipBackground,
    required this.selectedChipText,
    required this.selectedChipBorder,
    required this.unselectedChipBackground,
    required this.unselectedChipText,
    required this.selectedSuggestionBackground,
    required this.selectedSuggestionText,
    required this.selectedSuggestionBorder,
    required this.unselectedSuggestionBackground,
    required this.unselectedSuggestionText,
    required this.footerHintText,
  });

  final Color signatureSky;
  final Color deepSky;
  final Color selectedChipBackground;
  final Color selectedChipText;
  final Color selectedChipBorder;
  final Color unselectedChipBackground;
  final Color unselectedChipText;
  final Color selectedSuggestionBackground;
  final Color selectedSuggestionText;
  final Color selectedSuggestionBorder;
  final Color unselectedSuggestionBackground;
  final Color unselectedSuggestionText;
  final Color footerHintText;

  factory CheerMeSectionPalette.light() {
    return const CheerMeSectionPalette(
      signatureSky: Color(0xFF7EC8E3),
      deepSky: Color(0xFF5BA4C9),
      selectedChipBackground: Color(0xFFEAF6FC),
      selectedChipText: Color(0xFF245D79),
      selectedChipBorder: Color(0xFF7EC8E3),
      unselectedChipBackground: Color(0xFFF3F8FC),
      unselectedChipText: Color(0xFF6F8596),
      selectedSuggestionBackground: Color(0xFFE6F4FB),
      selectedSuggestionText: Color(0xFF245D79),
      selectedSuggestionBorder: Color(0xFF7EC8E3),
      unselectedSuggestionBackground: Color(0xFFF7FAFD),
      unselectedSuggestionText: Color(0xFF5F7485),
      footerHintText: Color(0xFF7F8C9A),
    );
  }

  factory CheerMeSectionPalette.darkFallback(ColorScheme colorScheme) {
    return CheerMeSectionPalette(
      signatureSky: colorScheme.primary,
      deepSky: colorScheme.primaryContainer,
      selectedChipBackground: colorScheme.secondaryContainer,
      selectedChipText: colorScheme.onSecondaryContainer,
      selectedChipBorder: colorScheme.secondary,
      unselectedChipBackground: colorScheme.surfaceContainerHighest,
      unselectedChipText: colorScheme.onSurfaceVariant,
      selectedSuggestionBackground: colorScheme.secondaryContainer,
      selectedSuggestionText: colorScheme.onSecondaryContainer,
      selectedSuggestionBorder: colorScheme.secondary,
      unselectedSuggestionBackground: colorScheme.surfaceContainerHigh,
      unselectedSuggestionText: colorScheme.onSurfaceVariant,
      footerHintText: colorScheme.outline,
    );
  }
}
