import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/diary.dart';

/// Diary 감정 점수 기반 UI 표시용 extension
extension DiaryDisplayExtension on Diary {
  /// 감정 점수에 따른 이모지
  String get emotionEmoji {
    if (status != DiaryStatus.analyzed || analysisResult == null) {
      return '📝';
    }
    final score = analysisResult!.sentimentScore;
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }

  /// 감정 점수에 따른 배경 색상 (연한 알파)
  Color get emotionBackgroundColor {
    if (status != DiaryStatus.analyzed || analysisResult == null) {
      return AppColors.textHint.withValues(alpha: 0.1);
    }
    return AppColors.getSentimentColor(analysisResult!.sentimentScore)
        .withValues(alpha: 0.15);
  }
}
