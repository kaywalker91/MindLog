import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/data/datasources/local/preferences_local_datasource.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';

import '../fixtures/diary_fixtures.dart';

/// Mock SqliteLocalDataSource
/// 메모리 기반 구현으로 실제 DB 없이 테스트 가능
class MockSqliteLocalDataSource extends SqliteLocalDataSource {
  // 메모리 저장소
  final Map<String, Diary> _diaries = {};
  final Map<String, String> _metadata = {};

  // 상태 제어 변수
  bool shouldThrowOnSave = false;
  bool shouldThrowOnGet = false;
  bool shouldThrowOnUpdate = false;
  bool shouldThrowOnDelete = false;
  String? errorMessage;

  /// 상태 초기화
  void reset() {
    _diaries.clear();
    _metadata.clear();
    shouldThrowOnSave = false;
    shouldThrowOnGet = false;
    shouldThrowOnUpdate = false;
    shouldThrowOnDelete = false;
    errorMessage = null;
  }

  /// 테스트용 일기 추가
  void addDiary(Diary diary) {
    _diaries[diary.id] = diary;
  }

  /// 테스트용 일기 목록 설정
  void setDiaries(List<Diary> diaries) {
    _diaries.clear();
    for (final diary in diaries) {
      _diaries[diary.id] = diary;
    }
  }

  @override
  Future<void> saveDiary(Diary diary) async {
    if (shouldThrowOnSave) {
      throw CacheException(errorMessage ?? '일기 저장 실패');
    }
    _diaries[diary.id] = diary;
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '일기 조회 실패');
    }
    return _diaries[diaryId];
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '일기 목록 조회 실패');
    }
    final diaries = _diaries.values.toList();
    // 고정 우선, 최신순 정렬
    diaries.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return diaries;
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '오늘 일기 조회 실패');
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _diaries.values
        .where((d) => d.createdAt.isAfter(todayStart))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> updateDiaryWithAnalysis(
    String diaryId,
    AnalysisResult analysisResult,
  ) async {
    if (shouldThrowOnUpdate) {
      throw CacheException(errorMessage ?? '일기 업데이트 실패');
    }
    final diary = _diaries[diaryId];
    if (diary == null) {
      throw DataNotFoundException('일기를 찾을 수 없습니다: $diaryId');
    }
    _diaries[diaryId] = diary.copyWith(
      status: DiaryStatus.analyzed,
      analysisResult: analysisResult,
    );
  }

  @override
  Future<void> updateDiaryStatus(String diaryId, DiaryStatus status) async {
    if (shouldThrowOnUpdate) {
      throw CacheException(errorMessage ?? '상태 업데이트 실패');
    }
    final diary = _diaries[diaryId];
    if (diary == null) {
      throw DataNotFoundException('일기를 찾을 수 없습니다: $diaryId');
    }
    _diaries[diaryId] = diary.copyWith(status: status);
  }

  @override
  Future<void> updateDiaryPin(String diaryId, bool isPinned) async {
    if (shouldThrowOnUpdate) {
      throw CacheException(errorMessage ?? '고정 상태 업데이트 실패');
    }
    final diary = _diaries[diaryId];
    if (diary == null) {
      throw DataNotFoundException('일기를 찾을 수 없습니다: $diaryId');
    }
    _diaries[diaryId] = diary.copyWith(isPinned: isPinned);
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    if (shouldThrowOnDelete) {
      throw CacheException(errorMessage ?? '일기 삭제 실패');
    }
    if (!_diaries.containsKey(diaryId)) {
      throw DataNotFoundException('삭제할 일기를 찾을 수 없습니다: $diaryId');
    }
    _diaries.remove(diaryId);
  }

  @override
  Future<void> deleteAllDiaries() async {
    if (shouldThrowOnDelete) {
      throw CacheException(errorMessage ?? '전체 삭제 실패');
    }
    _diaries.clear();
  }

  @override
  Future<void> close() async {
    // Mock에서는 아무 작업도 하지 않음
  }

  @override
  Future<List<Diary>> getAnalyzedDiariesInRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '날짜 범위 조회 실패');
    }
    return _diaries.values.where((diary) {
      // analyzed 또는 safetyBlocked 상태만 포함
      if (diary.status != DiaryStatus.analyzed &&
          diary.status != DiaryStatus.safetyBlocked) {
        return false;
      }

      // 날짜 범위 필터링
      if (startDate != null && diary.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && diary.createdAt.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<void> setMetadata(String key, String value) async {
    if (shouldThrowOnSave) {
      throw CacheException(errorMessage ?? '메타데이터 저장 실패');
    }
    _metadata[key] = value;
  }

  @override
  Future<String?> getMetadata(String key) async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '메타데이터 조회 실패');
    }
    return _metadata[key];
  }

  // 테스트용 헬퍼 메서드
  int get diaryCount => _diaries.length;
  List<Diary> get allDiariesRaw => _diaries.values.toList();
}

/// Mock PreferencesLocalDataSource
/// SharedPreferences 없이 메모리 기반으로 동작
class MockPreferencesLocalDataSource extends PreferencesLocalDataSource {
  // 메모리 저장소
  AiCharacter _selectedCharacter = AiCharacter.warmCounselor;
  NotificationSettings _notificationSettings = NotificationSettings.defaults();
  String? _userName;
  String? _lastSeenAppVersion;
  String? _dismissedUpdateVersion;

  // 상태 제어 변수
  bool shouldThrowOnGet = false;
  bool shouldThrowOnSet = false;
  String? errorMessage;

  /// 상태 초기화
  void reset() {
    _selectedCharacter = AiCharacter.warmCounselor;
    _notificationSettings = NotificationSettings.defaults();
    _userName = null;
    _lastSeenAppVersion = null;
    _dismissedUpdateVersion = null;
    shouldThrowOnGet = false;
    shouldThrowOnSet = false;
    errorMessage = null;
  }

  @override
  Future<AiCharacter> getSelectedAiCharacter() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? 'AI 캐릭터 조회 실패');
    }
    return _selectedCharacter;
  }

  @override
  Future<void> setSelectedAiCharacter(AiCharacter character) async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? 'AI 캐릭터 설정 실패');
    }
    _selectedCharacter = character;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '알림 설정 조회 실패');
    }
    return _notificationSettings;
  }

  @override
  Future<void> setNotificationSettings(NotificationSettings settings) async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? '알림 설정 저장 실패');
    }
    _notificationSettings = settings;
  }

  @override
  Future<String?> getUserName() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '유저 이름 조회 실패');
    }
    return _userName;
  }

  @override
  Future<void> setUserName(String? name) async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? '유저 이름 설정 실패');
    }
    _userName = name?.trim().isEmpty == true ? null : name?.trim();
  }

  @override
  Future<String?> getLastSeenAppVersion() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? '앱 버전 조회 실패');
    }
    return _lastSeenAppVersion;
  }

  @override
  Future<void> setLastSeenAppVersion(String version) async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? '앱 버전 설정 실패');
    }
    _lastSeenAppVersion = version;
  }

  @override
  Future<String?> getDismissedUpdateVersion() async {
    if (shouldThrowOnGet) {
      throw CacheException(errorMessage ?? 'Dismissed 버전 조회 실패');
    }
    return _dismissedUpdateVersion;
  }

  @override
  Future<void> setDismissedUpdateVersion(String version) async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? 'Dismissed 버전 설정 실패');
    }
    _dismissedUpdateVersion = version;
  }

  @override
  Future<void> clearDismissedUpdateVersion() async {
    if (shouldThrowOnSet) {
      throw CacheException(errorMessage ?? 'Dismissed 버전 삭제 실패');
    }
    _dismissedUpdateVersion = null;
  }

  // 테스트용 헬퍼 메서드
  void setMockCharacter(AiCharacter character) => _selectedCharacter = character;
  void setMockNotificationSettings(NotificationSettings settings) =>
      _notificationSettings = settings;
  void setMockUserName(String? name) => _userName = name;
  void setMockLastSeenAppVersion(String? version) => _lastSeenAppVersion = version;
}
