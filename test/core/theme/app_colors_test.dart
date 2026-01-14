import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('getSentimentColor', () {
      test('1-2점은 sentimentVeryNegative를 반환해야 한다', () {
        expect(AppColors.getSentimentColor(1), AppColors.sentimentVeryNegative);
        expect(AppColors.getSentimentColor(2), AppColors.sentimentVeryNegative);
      });

      test('3-4점은 sentimentNegative를 반환해야 한다', () {
        expect(AppColors.getSentimentColor(3), AppColors.sentimentNegative);
        expect(AppColors.getSentimentColor(4), AppColors.sentimentNegative);
      });

      test('5-6점은 sentimentNeutral을 반환해야 한다', () {
        expect(AppColors.getSentimentColor(5), AppColors.sentimentNeutral);
        expect(AppColors.getSentimentColor(6), AppColors.sentimentNeutral);
      });

      test('7-8점은 sentimentPositive를 반환해야 한다', () {
        expect(AppColors.getSentimentColor(7), AppColors.sentimentPositive);
        expect(AppColors.getSentimentColor(8), AppColors.sentimentPositive);
      });

      test('9-10점은 sentimentVeryPositive를 반환해야 한다', () {
        expect(AppColors.getSentimentColor(9), AppColors.sentimentVeryPositive);
        expect(AppColors.getSentimentColor(10), AppColors.sentimentVeryPositive);
      });

      test('경계값 테스트', () {
        // 2점과 3점 경계
        expect(AppColors.getSentimentColor(2), AppColors.sentimentVeryNegative);
        expect(AppColors.getSentimentColor(3), AppColors.sentimentNegative);

        // 4점과 5점 경계
        expect(AppColors.getSentimentColor(4), AppColors.sentimentNegative);
        expect(AppColors.getSentimentColor(5), AppColors.sentimentNeutral);

        // 6점과 7점 경계
        expect(AppColors.getSentimentColor(6), AppColors.sentimentNeutral);
        expect(AppColors.getSentimentColor(7), AppColors.sentimentPositive);

        // 8점과 9점 경계
        expect(AppColors.getSentimentColor(8), AppColors.sentimentPositive);
        expect(AppColors.getSentimentColor(9), AppColors.sentimentVeryPositive);
      });
    });

    group('getHeatmapColor', () {
      test('null이면 heatmapLevel0을 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(null), AppColors.heatmapLevel0);
      });

      test('1-2점은 heatmapLevel1을 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(1.0), AppColors.heatmapLevel1);
        expect(AppColors.getHeatmapColor(2.0), AppColors.heatmapLevel1);
      });

      test('3-4점은 heatmapLevel2를 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(3.0), AppColors.heatmapLevel2);
        expect(AppColors.getHeatmapColor(4.0), AppColors.heatmapLevel2);
      });

      test('5-6점은 heatmapLevel3을 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(5.0), AppColors.heatmapLevel3);
        expect(AppColors.getHeatmapColor(6.0), AppColors.heatmapLevel3);
      });

      test('7-8점은 heatmapLevel4를 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(7.0), AppColors.heatmapLevel4);
        expect(AppColors.getHeatmapColor(8.0), AppColors.heatmapLevel4);
      });

      test('9-10점은 heatmapLevel5를 반환해야 한다', () {
        expect(AppColors.getHeatmapColor(9.0), AppColors.heatmapLevel5);
        expect(AppColors.getHeatmapColor(10.0), AppColors.heatmapLevel5);
      });

      test('소수점 점수도 올바르게 처리해야 한다', () {
        // 2.5 > 2 → level2
        expect(AppColors.getHeatmapColor(2.5), AppColors.heatmapLevel2);
        // 4.9 > 4 → level3
        expect(AppColors.getHeatmapColor(4.9), AppColors.heatmapLevel3);
        // 5.5 > 4, <= 6 → level3
        expect(AppColors.getHeatmapColor(5.5), AppColors.heatmapLevel3);
        // 8.9 > 8 → level5
        expect(AppColors.getHeatmapColor(8.9), AppColors.heatmapLevel5);
      });

      test('경계값 테스트 (double)', () {
        expect(AppColors.getHeatmapColor(2.0), AppColors.heatmapLevel1);
        expect(AppColors.getHeatmapColor(2.01), AppColors.heatmapLevel2);
        expect(AppColors.getHeatmapColor(4.0), AppColors.heatmapLevel2);
        expect(AppColors.getHeatmapColor(4.01), AppColors.heatmapLevel3);
        expect(AppColors.getHeatmapColor(6.0), AppColors.heatmapLevel3);
        expect(AppColors.getHeatmapColor(6.01), AppColors.heatmapLevel4);
        expect(AppColors.getHeatmapColor(8.0), AppColors.heatmapLevel4);
        expect(AppColors.getHeatmapColor(8.01), AppColors.heatmapLevel5);
      });
    });

    group('heatmapLegendColors', () {
      test('5개의 색상을 포함해야 한다', () {
        expect(AppColors.heatmapLegendColors.length, 5);
      });

      test('레벨 1-5 순서로 정렬되어야 한다', () {
        expect(AppColors.heatmapLegendColors[0], AppColors.heatmapLevel1);
        expect(AppColors.heatmapLegendColors[1], AppColors.heatmapLevel2);
        expect(AppColors.heatmapLegendColors[2], AppColors.heatmapLevel3);
        expect(AppColors.heatmapLegendColors[3], AppColors.heatmapLevel4);
        expect(AppColors.heatmapLegendColors[4], AppColors.heatmapLevel5);
      });
    });

    group('상수 정의 검증', () {
      test('Primary 색상이 올바르게 정의되어야 한다', () {
        expect(AppColors.primary, const Color(0xFF6B5B95));
        expect(AppColors.primaryLight, const Color(0xFF9B8BC7));
        expect(AppColors.primaryDark, const Color(0xFF3E3466));
      });

      test('Background 색상이 올바르게 정의되어야 한다', () {
        expect(AppColors.background, const Color(0xFFF8F7FC));
        expect(AppColors.surface, Colors.white);
      });

      test('Status 색상이 올바르게 정의되어야 한다', () {
        expect(AppColors.success, const Color(0xFF4CAF50));
        expect(AppColors.warning, const Color(0xFFFF9800));
        expect(AppColors.error, const Color(0xFFE57373));
        expect(AppColors.info, const Color(0xFF64B5F6));
      });
    });
  });
}
