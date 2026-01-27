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

  // ============================================
  // 통계 화면 전용 팔레트 (하늘색 파스텔 톤)
  // ============================================

  // Statistics Primary Colors
  static const Color statsPrimary = Color(0xFF7EC8E3);       // Sky Blue
  static const Color statsPrimaryDark = Color(0xFF5BA4C9);   // Deep Sky
  static const Color statsSecondary = Color(0xFFB8C5E2);     // Soft Lavender

  // Statistics Background Colors
  static const Color statsBackground = Color(0xFFF8FBFF);    // Cloud White
  static const Color statsCardBackground = Color(0xFFFFFFFF); // Soft Cloud
  static const Color statsCardBorder = Color(0xFFE8F4FA);    // Mist

  // Statistics Text Colors
  static const Color statsTextPrimary = Color(0xFF2C3E50);   // 제목, 주요 텍스트
  static const Color statsTextSecondary = Color(0xFF7F8C9A); // 부제목, 설명
  static const Color statsTextTertiary = Color(0xFFA8B5C4);  // 힌트, 비활성

  // Statistics Heatmap Colors (하늘색 5단계)
  static const Color heatmapLevel0 = Color(0xFFF0F4F8);      // 데이터 없음
  static const Color heatmapLevel1 = Color(0xFFE8F4FA);      // 1-2점 (가장 연함)
  static const Color heatmapLevel2 = Color(0xFFC5E3F2);      // 3-4점
  static const Color heatmapLevel3 = Color(0xFF7EC8E3);      // 5-6점 (Primary)
  static const Color heatmapLevel4 = Color(0xFF5BA4C9);      // 7-8점
  static const Color heatmapLevel5 = Color(0xFF3D8AB0);      // 9-10점 (가장 진함)

  // Statistics Accent Colors
  static const Color statsAccentCoral = Color(0xFFF5A895);   // 스트릭 강조
  static const Color statsAccentMint = Color(0xFFA8E6CF);    // 성취, 긍정

  // Emotion Garden Colors (감정 정원)
  static const Color gardenSoil = Color(0xFFF5F0EB);         // 빈 날 (흙)
  static const Color gardenSoilBorder = Color(0xFFE8E0D8);   // 흙 테두리

  // Warm Garden Colors (따뜻한 정원 - 친근감 디자인)
  static const Color gardenWarm1 = Color(0xFFFAF8F5);        // 크림 (1-2점)
  static const Color gardenWarm2 = Color(0xFFF5F2ED);        // 베이지 (3-4점)
  static const Color gardenWarm3 = Color(0xFFE8F0E5);        // 연민트 (5-6점)
  static const Color gardenWarm4 = Color(0xFFD4E8D0);        // 민트 (7-8점)
  static const Color gardenWarm5 = Color(0xFFC0E0BC);        // 연초록 (9-10점)

  // Legacy Garden Colors (기존 hex 호환)
  static const Color gardenLegacy1 = Color(0xFFF5F8F5);      // 1-2점
  static const Color gardenLegacy2 = Color(0xFFEDF5ED);      // 3-4점
  static const Color gardenLegacy3 = Color(0xFFE5F2E5);      // 5-6점
  static const Color gardenLegacy4 = Color(0xFFDDEFDD);      // 7-8점
  static const Color gardenLegacy5 = Color(0xFFD4EBD4);      // 9-10점

  // Cell Glow Colors
  static const Color gardenGlow = Color(0xFFA8E6CF);         // 성취감 glow
  static const Color todayGlow = Color(0xFFFFE4B5);          // 오늘 강조 (모카신)

  // Action/Mission Colors (행동 추천 UI)
  static const Color actionAmber = Color(0xFFFFC107);
  static const Color actionAmberDark = Color(0xFFF9A825);     // amber.shade800 대체
  static const Color actionStep1 = Color(0xFF4CAF50);         // 즉시 행동 (green)
  static const Color actionStep2 = Color(0xFFFF9800);         // 오늘 중 (orange)
  static const Color actionStep3 = Color(0xFF2196F3);         // 이번 주 (blue)

  // SOS Colors (긴급 상황 UI)
  static const Color sosCardBackground = Color(0xFFFFEBEE);   // red.shade50
  static const Color sosCardBorder = Color(0xFFEF9A9A);       // red.shade200
  static const Color sosIcon = Color(0xFFF44336);             // red
  static const Color sosTextDark = Color(0xFFC62828);         // red.shade800
  static const Color sosTextDarker = Color(0xFFB71C1C);       // red.shade900
  static const Color sosButton = Color(0xFFEF5350);           // red.shade400

  /// 감정 점수에 따른 색상 반환
  static Color getSentimentColor(int score) {
    if (score <= 2) return sentimentVeryNegative;
    if (score <= 4) return sentimentNegative;
    if (score <= 6) return sentimentNeutral;
    if (score <= 8) return sentimentPositive;
    return sentimentVeryPositive;
  }

  /// 통계 히트맵용 감정 점수 색상 반환 (하늘색 단일 색조)
  static Color getHeatmapColor(double? score) {
    if (score == null) return heatmapLevel0;
    if (score <= 2) return heatmapLevel1;
    if (score <= 4) return heatmapLevel2;
    if (score <= 6) return heatmapLevel3;
    if (score <= 8) return heatmapLevel4;
    return heatmapLevel5;
  }

  /// 히트맵 범례용 색상 리스트
  static const List<Color> heatmapLegendColors = [
    heatmapLevel1,
    heatmapLevel2,
    heatmapLevel3,
    heatmapLevel4,
    heatmapLevel5,
  ];
}
