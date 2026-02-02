import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary.dart';
import 'diary_list_controller.dart';

/// 오늘의 감정 상태 모델
class TodayEmotionStatus {
  /// 오늘 일기를 작성했는지 여부
  final bool hasWrittenToday;

  /// 최신 일기의 감정 이모지 (분석 완료 시)
  final String? emoji;

  /// 최신 일기의 감정 점수 (1-10)
  final int? sentimentScore;

  /// 오늘 작성한 일기 수
  final int diaryCount;

  const TodayEmotionStatus({
    required this.hasWrittenToday,
    this.emoji,
    this.sentimentScore,
    required this.diaryCount,
  });

  /// 기본값 (오늘 일기 없음)
  static const empty = TodayEmotionStatus(
    hasWrittenToday: false,
    emoji: null,
    sentimentScore: null,
    diaryCount: 0,
  );
}

/// 오늘의 감정 상태 Provider
/// diaryListControllerProvider를 구독하여 오늘 작성된 일기의 감정 상태를 계산
final todayEmotionProvider = Provider<TodayEmotionStatus>((ref) {
  final diaryListState = ref.watch(diaryListControllerProvider);

  return diaryListState.when(
    data: (diaries) => _calculateTodayEmotion(diaries),
    loading: () => TodayEmotionStatus.empty,
    error: (_, _) => TodayEmotionStatus.empty,
  );
});

/// 오늘 작성된 일기에서 감정 상태 계산
TodayEmotionStatus _calculateTodayEmotion(List<Diary> diaries) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  // 오늘 작성된 일기만 필터링
  final todayDiaries = diaries.where((diary) {
    return diary.createdAt.isAfter(todayStart) ||
        (diary.createdAt.year == todayStart.year &&
            diary.createdAt.month == todayStart.month &&
            diary.createdAt.day == todayStart.day);
  }).toList();

  if (todayDiaries.isEmpty) {
    return TodayEmotionStatus.empty;
  }

  // 가장 최근 일기 찾기
  final latestDiary = todayDiaries.reduce(
    (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
  );

  // 감정 이모지 계산 (분석 완료된 경우에만)
  String? emoji;
  int? sentimentScore;

  if (latestDiary.status == DiaryStatus.analyzed &&
      latestDiary.analysisResult != null) {
    sentimentScore = latestDiary.analysisResult!.sentimentScore;
    emoji = _getEmotionEmoji(sentimentScore);
  }

  return TodayEmotionStatus(
    hasWrittenToday: true,
    emoji: emoji,
    sentimentScore: sentimentScore,
    diaryCount: todayDiaries.length,
  );
}

/// 감정 점수에 따른 이모지 반환
String _getEmotionEmoji(int score) {
  if (score <= 2) return '😭';
  if (score <= 4) return '😢';
  if (score <= 6) return '🙂';
  if (score <= 8) return '😊';
  return '🥰';
}
