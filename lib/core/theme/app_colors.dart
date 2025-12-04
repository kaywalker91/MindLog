import 'package:flutter/material.dart';

/// 앱 컬러 팔레트
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6B5B95);
  static const Color primaryLight = Color(0xFF9B8BC7);
  static const Color primaryDark = Color(0xFF3E3466);

  // Background Colors
  static const Color background = Color(0xFFF8F7FC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6B6B7D);
  static const Color textHint = Color(0xFFA0A0B0);

  // Sentiment Colors (감정 온도 그라데이션)
  static const Color sentimentVeryNegative = Color(0xFF5C6BC0); // 1-2점
  static const Color sentimentNegative = Color(0xFF7986CB); // 3-4점
  static const Color sentimentNeutral = Color(0xFF9FA8DA); // 5-6점
  static const Color sentimentPositive = Color(0xFFFFB74D); // 7-8점
  static const Color sentimentVeryPositive = Color(0xFFFFD54F); // 9-10점

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // SOS Card Colors
  static const Color sosBackground = Color(0xFFFFF3E0);
  static const Color sosBorder = Color(0xFFFFB74D);

  /// 감정 점수에 따른 색상 반환
  static Color getSentimentColor(int score) {
    if (score <= 2) return sentimentVeryNegative;
    if (score <= 4) return sentimentNegative;
    if (score <= 6) return sentimentNeutral;
    if (score <= 8) return sentimentPositive;
    return sentimentVeryPositive;
  }
}
