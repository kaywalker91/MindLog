import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/domain/usecases/get_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/get_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/get_statistics_usecase.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/set_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/validate_diary_content_usecase.dart';

import '../fixtures/diary_fixtures.dart';
import '../fixtures/statistics_fixtures.dart';

/// Mock AnalyzeDiaryUseCase
class MockAnalyzeDiaryUseCase implements AnalyzeDiaryUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  Diary? mockDiary;
  DiaryStatus? mockStatus;
  Exception? genericException;

  final List<String> analyzedContents = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    mockDiary = null;
    mockStatus = null;
    genericException = null;
    analyzedContents.clear();
  }

  @override
  Future<Diary> execute(String content, {List<String>? imagePaths}) async {
    analyzedContents.add(content);
    if (genericException != null) {
      throw genericException!;
    }
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.unknown(message: '분석 실패');
    }
    final diary = mockDiary ?? DiaryFixtures.analyzed(content: content);
    if (mockStatus != null) {
      return diary.copyWith(status: mockStatus);
    }
    return diary;
  }
}

/// Mock GetNotificationSettingsUseCase
class MockGetNotificationSettingsUseCase
    implements GetNotificationSettingsUseCase {
  NotificationSettings mockSettings = NotificationSettings.defaults();
  bool shouldThrow = false;
  Failure? failureToThrow;

  void reset() {
    mockSettings = NotificationSettings.defaults();
    shouldThrow = false;
    failureToThrow = null;
  }

  @override
  Future<NotificationSettings> execute() async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 조회 실패');
    }
    return mockSettings;
  }
}

/// Mock SetNotificationSettingsUseCase
class MockSetNotificationSettingsUseCase
    implements SetNotificationSettingsUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  final List<NotificationSettings> savedSettings = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    savedSettings.clear();
  }

  @override
  Future<void> execute(NotificationSettings settings) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 저장 실패');
    }
    savedSettings.add(settings);
  }
}

/// Mock GetSelectedAiCharacterUseCase
class MockGetSelectedAiCharacterUseCase
    implements GetSelectedAiCharacterUseCase {
  AiCharacter mockCharacter = AiCharacter.warmCounselor;
  bool shouldThrow = false;
  Failure? failureToThrow;

  void reset() {
    mockCharacter = AiCharacter.warmCounselor;
    shouldThrow = false;
    failureToThrow = null;
  }

  @override
  Future<AiCharacter> execute() async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 조회 실패');
    }
    return mockCharacter;
  }
}

/// Mock SetSelectedAiCharacterUseCase
class MockSetSelectedAiCharacterUseCase
    implements SetSelectedAiCharacterUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  final List<AiCharacter> savedCharacters = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    savedCharacters.clear();
  }

  @override
  Future<void> execute(AiCharacter character) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 저장 실패');
    }
    savedCharacters.add(character);
  }
}

/// Mock GetStatisticsUseCase
class MockGetStatisticsUseCase implements GetStatisticsUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  EmotionStatistics? mockStatistics;
  List<DailyEmotion>? mockDailyEmotions;
  Map<DateTime, double>? mockActivityMap;

  final List<StatisticsPeriod> requestedPeriods = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    mockStatistics = null;
    mockDailyEmotions = null;
    mockActivityMap = null;
    requestedPeriods.clear();
  }

  @override
  Future<EmotionStatistics> execute(StatisticsPeriod period) async {
    requestedPeriods.add(period);
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '통계 조회 실패');
    }
    return mockStatistics ?? StatisticsFixtures.weekly();
  }

  @override
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '일별 감정 조회 실패');
    }
    return mockDailyEmotions ?? StatisticsFixtures.weekly().dailyEmotions;
  }

  @override
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '활동 맵 조회 실패');
    }
    return mockActivityMap ?? StatisticsFixtures.weekly().activityMap;
  }
}

/// Mock ValidateDiaryContentUseCase
class MockValidateDiaryContentUseCase implements ValidateDiaryContentUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  DiaryValidationResult? mockResult;

  final List<String> validatedContents = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    mockResult = null;
    validatedContents.clear();
  }

  @override
  DiaryValidationResult execute(String content) {
    validatedContents.add(content);
    if (shouldThrow) {
      throw failureToThrow ?? const ValidationFailure(message: '유효성 검사 실패');
    }
    return mockResult ?? DiaryValidationResult.valid(content.trim());
  }

  @override
  DiaryValidationResult validate(String content) {
    validatedContents.add(content);
    if (shouldThrow) {
      return DiaryValidationResult.invalid(
        failureToThrow?.message ?? '유효성 검사 실패',
      );
    }
    return mockResult ?? DiaryValidationResult.valid(content.trim());
  }
}
