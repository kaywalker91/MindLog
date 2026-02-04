import 'package:flutter/foundation.dart';
import '../../../data/datasources/local/sqlite_local_datasource.dart';
import '../../../domain/entities/diary.dart';

/// 감정 점수 조회 서비스
///
/// FCM 알림 개인화를 위해 최근 감정 점수를 조회합니다.
/// SQLite에서 직접 조회하여 Repository 의존성 최소화.
class EmotionScoreService {
  EmotionScoreService._();

  static SqliteLocalDataSource? _dataSource;

  /// 테스트용 DataSource 주입
  @visibleForTesting
  static void setDataSource(SqliteLocalDataSource dataSource) {
    _dataSource = dataSource;
  }

  /// 테스트용 리셋
  @visibleForTesting
  static void resetForTesting() {
    _dataSource = null;
  }

  /// 최근 N일 동안의 감정 점수 평균 반환
  ///
  /// [days] - 조회할 일수 (기본 7일)
  ///
  /// 반환값:
  /// - 분석된 일기가 있으면 평균 점수 (1.0 - 10.0)
  /// - 분석된 일기가 없으면 null
  static Future<double?> getRecentAverageScore({int days = 7}) async {
    try {
      final dataSource = _dataSource ?? SqliteLocalDataSource();
      final allDiaries = await dataSource.getAllDiaries();

      if (allDiaries.isEmpty) return null;

      // 최근 N일 기준 날짜
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      // 최근 N일 내 분석 완료된 일기만 필터링
      final recentAnalyzedDiaries = allDiaries.where((diary) {
        return diary.createdAt.isAfter(cutoffDate) &&
            diary.status == DiaryStatus.analyzed &&
            diary.analysisResult != null;
      }).toList();

      if (recentAnalyzedDiaries.isEmpty) return null;

      // 감정 점수 평균 계산
      final totalScore = recentAnalyzedDiaries.fold<int>(
        0,
        (sum, diary) => sum + diary.analysisResult!.sentimentScore,
      );

      return totalScore / recentAnalyzedDiaries.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EmotionScore] Failed to get average score: $e');
      }
      return null;
    }
  }

  /// 최근 감정 레벨 반환 (EmotionLevel로 변환)
  ///
  /// 반환값:
  /// - 감정 데이터가 있으면 EmotionLevel
  /// - 없으면 null (폴백 필요)
  static Future<({double avgScore, int diaryCount})?> getRecentEmotionSummary({
    int days = 7,
  }) async {
    try {
      final dataSource = _dataSource ?? SqliteLocalDataSource();
      final allDiaries = await dataSource.getAllDiaries();

      if (allDiaries.isEmpty) return null;

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final recentAnalyzedDiaries = allDiaries.where((diary) {
        return diary.createdAt.isAfter(cutoffDate) &&
            diary.status == DiaryStatus.analyzed &&
            diary.analysisResult != null;
      }).toList();

      if (recentAnalyzedDiaries.isEmpty) return null;

      final totalScore = recentAnalyzedDiaries.fold<int>(
        0,
        (sum, diary) => sum + diary.analysisResult!.sentimentScore,
      );

      return (
        avgScore: totalScore / recentAnalyzedDiaries.length,
        diaryCount: recentAnalyzedDiaries.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EmotionScore] Failed to get emotion summary: $e');
      }
      return null;
    }
  }
}
