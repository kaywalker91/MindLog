import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/domain/repositories/diary_repository.dart';
import 'package:mindlog/domain/repositories/settings_repository.dart';
import 'package:mindlog/domain/repositories/statistics_repository.dart';

import '../fixtures/diary_fixtures.dart';
import '../fixtures/statistics_fixtures.dart';

/// Mock DiaryRepository
class MockDiaryRepository implements DiaryRepository {
  // 상태 제어 변수
  bool shouldThrowOnCreate = false;
  bool shouldThrowOnAnalyze = false;
  bool shouldThrowOnUpdate = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnGet = false;

  Failure? failureToThrow;
  String? errorMessage;

  // Mock 데이터
  Diary? mockDiary;
  Diary? mockAnalyzedDiary;
  List<Diary> diaries = [];

  // 호출 추적
  final List<Diary> savedDiaries = [];
  final List<Diary> updatedDiaries = [];
  final List<String> deletedDiaryIds = [];
  final List<String> analyzedDiaryIds = [];

  /// 상태 초기화
  void reset() {
    shouldThrowOnCreate = false;
    shouldThrowOnAnalyze = false;
    shouldThrowOnUpdate = false;
    shouldThrowOnDelete = false;
    shouldThrowOnGet = false;
    failureToThrow = null;
    errorMessage = null;
    mockDiary = null;
    mockAnalyzedDiary = null;
    diaries.clear();
    savedDiaries.clear();
    updatedDiaries.clear();
    deletedDiaryIds.clear();
    analyzedDiaryIds.clear();
  }

  @override
  Future<Diary> createDiary(String content) async {
    if (shouldThrowOnCreate) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '일기 생성 실패');
    }
    mockDiary = DiaryFixtures.pending(id: 'created-${savedDiaries.length}', content: content);
    savedDiaries.add(mockDiary!);
    return mockDiary!;
  }

  @override
  Future<Diary> analyzeDiary(
    String diaryId, {
    required AiCharacter character,
    String? userName,
  }) async {
    analyzedDiaryIds.add(diaryId);
    if (shouldThrowOnAnalyze) {
      throw failureToThrow ??
          Failure.api(message: errorMessage ?? '분석 실패');
    }
    mockAnalyzedDiary = mockAnalyzedDiary ??
        DiaryFixtures.analyzed(id: diaryId);
    return mockAnalyzedDiary!;
  }

  @override
  Future<void> updateDiary(Diary diary) async {
    if (shouldThrowOnUpdate) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '업데이트 실패');
    }
    updatedDiaries.add(diary);
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    if (shouldThrowOnGet) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '조회 실패');
    }
    return diaries.where((d) => d.id == diaryId).firstOrNull ?? mockDiary;
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    if (shouldThrowOnGet) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '목록 조회 실패');
    }
    final result = diaries.isNotEmpty ? List<Diary>.from(diaries) : (mockDiary != null ? [mockDiary!] : <Diary>[]);
    // 고정 우선, 최신순 정렬
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    if (shouldThrowOnGet) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '오늘 일기 조회 실패');
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return diaries.where((d) => d.createdAt.isAfter(todayStart)).toList();
  }

  @override
  Future<void> markActionCompleted(String diaryId) async {
    if (shouldThrowOnUpdate) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '완료 표시 실패');
    }
  }

  @override
  Future<void> toggleDiaryPin(String diaryId, bool isPinned) async {
    if (shouldThrowOnUpdate) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '고정 토글 실패');
    }
    final index = diaries.indexWhere((d) => d.id == diaryId);
    if (index != -1) {
      diaries[index] = diaries[index].copyWith(isPinned: isPinned);
    }
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    if (shouldThrowOnDelete) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '삭제 실패');
    }
    deletedDiaryIds.add(diaryId);
    diaries.removeWhere((d) => d.id == diaryId);
  }

  @override
  Future<void> deleteAllDiaries() async {
    if (shouldThrowOnDelete) {
      throw failureToThrow ??
          Failure.cache(message: errorMessage ?? '전체 삭제 실패');
    }
    diaries.clear();
  }
}

/// Mock SettingsRepository
class MockSettingsRepository implements SettingsRepository {
  // 상태 제어 변수
  bool shouldThrowOnGet = false;
  bool shouldThrowOnSet = false;
  Failure? failureToThrow;

  // Mock 데이터
  AiCharacter _selectedCharacter = AiCharacter.warmCounselor;
  NotificationSettings _notificationSettings = NotificationSettings.defaults();
  String? _userName;

  /// 상태 초기화
  void reset() {
    shouldThrowOnGet = false;
    shouldThrowOnSet = false;
    failureToThrow = null;
    _selectedCharacter = AiCharacter.warmCounselor;
    _notificationSettings = NotificationSettings.defaults();
    _userName = null;
  }

  @override
  Future<AiCharacter> getSelectedAiCharacter() async {
    if (shouldThrowOnGet) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 조회 실패');
    }
    return _selectedCharacter;
  }

  @override
  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    if (shouldThrowOnSet) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 설정 실패');
    }
    _selectedCharacter = character;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    if (shouldThrowOnGet) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 조회 실패');
    }
    return _notificationSettings;
  }

  @override
  Future<void> setNotificationSettings(NotificationSettings settings) async {
    if (shouldThrowOnSet) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 저장 실패');
    }
    _notificationSettings = settings;
  }

  @override
  Future<String?> getUserName() async {
    if (shouldThrowOnGet) {
      throw failureToThrow ?? const Failure.cache(message: '유저 이름 조회 실패');
    }
    return _userName;
  }

  @override
  Future<void> setUserName(String? name) async {
    if (shouldThrowOnSet) {
      throw failureToThrow ?? const Failure.cache(message: '유저 이름 설정 실패');
    }
    _userName = name?.trim().isEmpty == true ? null : name?.trim();
  }

  // 테스트 헬퍼 메서드
  void setMockCharacter(AiCharacter character) => _selectedCharacter = character;
  void setMockNotificationSettings(NotificationSettings settings) =>
      _notificationSettings = settings;
  void setMockUserName(String? name) => _userName = name;
}

/// Mock StatisticsRepository
class MockStatisticsRepository implements StatisticsRepository {
  // 상태 제어 변수
  bool shouldThrowOnGetStatistics = false;
  bool shouldThrowOnGetDailyEmotions = false;
  bool shouldThrowOnGetKeywordFrequency = false;
  bool shouldThrowOnGetActivityMap = false;
  Failure? failureToThrow;

  // Mock 데이터
  EmotionStatistics? mockStatistics;
  List<DailyEmotion>? mockDailyEmotions;
  Map<String, int>? mockKeywordFrequency;
  Map<DateTime, double>? mockActivityMap;

  // 호출 추적
  final List<StatisticsPeriod> requestedPeriods = [];
  final List<Map<String, DateTime?>> dailyEmotionRequests = [];
  final List<int?> keywordFrequencyLimits = [];
  final List<Map<String, DateTime?>> activityMapRequests = [];

  /// 상태 초기화
  void reset() {
    shouldThrowOnGetStatistics = false;
    shouldThrowOnGetDailyEmotions = false;
    shouldThrowOnGetKeywordFrequency = false;
    shouldThrowOnGetActivityMap = false;
    failureToThrow = null;
    mockStatistics = null;
    mockDailyEmotions = null;
    mockKeywordFrequency = null;
    mockActivityMap = null;
    requestedPeriods.clear();
    dailyEmotionRequests.clear();
    keywordFrequencyLimits.clear();
    activityMapRequests.clear();
  }

  @override
  Future<EmotionStatistics> getStatistics(StatisticsPeriod period) async {
    requestedPeriods.add(period);
    if (shouldThrowOnGetStatistics) {
      throw failureToThrow ?? const Failure.cache(message: '통계 조회 실패');
    }
    return mockStatistics ?? _defaultStatisticsForPeriod(period);
  }

  @override
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    dailyEmotionRequests.add({'startDate': startDate, 'endDate': endDate});
    if (shouldThrowOnGetDailyEmotions) {
      throw failureToThrow ?? const Failure.cache(message: '일별 감정 조회 실패');
    }
    return mockDailyEmotions ?? StatisticsFixtures.weekly().dailyEmotions;
  }

  @override
  Future<Map<String, int>> getKeywordFrequency({int? limit}) async {
    keywordFrequencyLimits.add(limit);
    if (shouldThrowOnGetKeywordFrequency) {
      throw failureToThrow ?? const Failure.cache(message: '키워드 빈도 조회 실패');
    }
    final frequency = mockKeywordFrequency ?? StatisticsFixtures.weekly().keywordFrequency;
    if (limit == null) return frequency;

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  @override
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    activityMapRequests.add({'startDate': startDate, 'endDate': endDate});
    if (shouldThrowOnGetActivityMap) {
      throw failureToThrow ?? const Failure.cache(message: '활동 맵 조회 실패');
    }
    return mockActivityMap ?? StatisticsFixtures.weekly().activityMap;
  }

  EmotionStatistics _defaultStatisticsForPeriod(StatisticsPeriod period) {
    return switch (period) {
      StatisticsPeriod.week => StatisticsFixtures.weekly(),
      StatisticsPeriod.month => StatisticsFixtures.monthly(),
      StatisticsPeriod.all => StatisticsFixtures.all(),
    };
  }
}
