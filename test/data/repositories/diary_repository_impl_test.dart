import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';
import 'package:mindlog/data/dto/analysis_response_dto.dart';
import 'package:mindlog/data/repositories/diary_repository_impl.dart';
import 'package:mindlog/domain/entities/diary.dart';

/// Mock SqliteLocalDataSource for testing
class MockSqliteLocalDataSource implements SqliteLocalDataSource {
  final Map<String, Diary> _diaries = {};
  bool shouldThrowOnSave = false;
  bool shouldThrowOnGet = false;

  @override
  Future<void> saveDiary(Diary diary) async {
    if (shouldThrowOnSave) {
      throw Exception('Save failed');
    }
    _diaries[diary.id] = diary;
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    if (shouldThrowOnGet) {
      throw Exception('Get failed');
    }
    return _diaries[diaryId];
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    final diaries = _diaries.values.toList();
    diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return diaries;
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _diaries.values
        .where((d) => d.createdAt.isAfter(todayStart))
        .toList();
  }

  @override
  Future<void> updateDiaryWithAnalysis(
      String diaryId, AnalysisResult analysisResult) async {
    final diary = _diaries[diaryId];
    if (diary != null) {
      // 기존 상태를 유지하면서 분석 결과만 업데이트
      _diaries[diaryId] = diary.copyWith(
        analysisResult: analysisResult,
      );
    }
  }

  @override
  Future<void> updateDiaryStatus(String diaryId, DiaryStatus status) async {
    final diary = _diaries[diaryId];
    if (diary != null) {
      _diaries[diaryId] = diary.copyWith(status: status);
    }
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    if (!_diaries.containsKey(diaryId)) {
      throw Exception('Diary not found');
    }
    _diaries.remove(diaryId);
  }

  @override
  Future<void> deleteAllDiaries() async {
    _diaries.clear();
  }

  @override
  Future<void> close() async {}

  @override
  Future<List<Diary>> getAnalyzedDiariesInRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _diaries.values
        .where((d) =>
            d.status == DiaryStatus.analyzed ||
            d.status == DiaryStatus.safetyBlocked)
        .where((d) =>
            startDate == null || d.createdAt.isAfter(startDate.subtract(const Duration(days: 1))))
        .where((d) =>
            endDate == null || d.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  // Helper method for testing
  void addDiary(Diary diary) {
    _diaries[diary.id] = diary;
  }
}

/// Mock GroqRemoteDataSource for testing
class MockGroqRemoteDataSource implements GroqRemoteDataSource {
  bool shouldThrow = false;
  String? errorMessage;
  AnalysisResponseDto? mockResponse;

  @override
  Future<AnalysisResponseDto> analyzeDiary(
    String content, {
    required AiCharacter character,
  }) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'API Error');
    }
    return mockResponse ??
        AnalysisResponseDto(
          keywords: ['테스트', '키워드', '분석'],
          sentimentScore: 7,
          empathyMessage: '테스트 공감 메시지입니다.',
          actionItem: '테스트 행동을 해보세요.',
          isEmergency: false,
        );
  }

  @override
  Future<AnalysisResponseDto> analyzeDiaryWithRetry(
    String content, {
    required AiCharacter character,
  }) async {
    return analyzeDiary(content, character: character);
  }
}

void main() {
  late DiaryRepositoryImpl repository;
  late MockSqliteLocalDataSource mockLocalDataSource;
  late MockGroqRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockSqliteLocalDataSource();
    mockRemoteDataSource = MockGroqRemoteDataSource();
    repository = DiaryRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('DiaryRepositoryImpl', () {
    group('createDiary', () {
      test('일기 생성 시 pending 상태로 저장되어야 한다', () async {
        final diary = await repository.createDiary('오늘 하루 테스트 내용입니다.');

        expect(diary.content, '오늘 하루 테스트 내용입니다.');
        expect(diary.status, DiaryStatus.pending);
        expect(diary.id, isNotEmpty);
      });

      test('일기 생성 시 현재 시간이 기록되어야 한다', () async {
        final before = DateTime.now();
        final diary = await repository.createDiary('테스트 일기');
        final after = DateTime.now();

        expect(diary.createdAt.isAfter(before.subtract(Duration(seconds: 1))),
            true);
        expect(diary.createdAt.isBefore(after.add(Duration(seconds: 1))), true);
      });

      test('저장 실패 시 CacheFailure를 던져야 한다', () async {
        mockLocalDataSource.shouldThrowOnSave = true;

        expect(
          () => repository.createDiary('테스트'),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getDiaryById', () {
      test('존재하는 일기를 조회할 수 있어야 한다', () async {
        final testDiary = Diary(
          id: 'test-123',
          content: '테스트 내용',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        final result = await repository.getDiaryById('test-123');

        expect(result, isNotNull);
        expect(result?.id, 'test-123');
        expect(result?.content, '테스트 내용');
      });

      test('존재하지 않는 일기는 null을 반환해야 한다', () async {
        final result = await repository.getDiaryById('non-existent');

        expect(result, isNull);
      });
    });

    group('getAllDiaries', () {
      test('모든 일기를 최신순으로 반환해야 한다', () async {
        mockLocalDataSource.addDiary(Diary(
          id: '1',
          content: '첫번째',
          createdAt: DateTime(2024, 1, 1),
          status: DiaryStatus.pending,
        ));
        mockLocalDataSource.addDiary(Diary(
          id: '2',
          content: '두번째',
          createdAt: DateTime(2024, 1, 3),
          status: DiaryStatus.analyzed,
        ));
        mockLocalDataSource.addDiary(Diary(
          id: '3',
          content: '세번째',
          createdAt: DateTime(2024, 1, 2),
          status: DiaryStatus.pending,
        ));

        final diaries = await repository.getAllDiaries();

        expect(diaries.length, 3);
        expect(diaries[0].id, '2'); // 가장 최신
        expect(diaries[1].id, '3');
        expect(diaries[2].id, '1'); // 가장 오래된
      });

      test('일기가 없으면 빈 리스트를 반환해야 한다', () async {
        final diaries = await repository.getAllDiaries();

        expect(diaries, isEmpty);
      });
    });

    group('analyzeDiary', () {
      test('분석 성공 시 analyzed 상태로 업데이트되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-analyze',
          content: '분석할 내용입니다.',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        final result = await repository.analyzeDiary(
          'test-analyze',
          character: AiCharacter.warmCounselor,
        );

        expect(result.status, DiaryStatus.analyzed);
        expect(result.analysisResult, isNotNull);
        expect(result.analysisResult?.keywords, isNotEmpty);
      });

      test('분석 결과에 키워드가 포함되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-keywords',
          content: '키워드 분석 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        final result = await repository.analyzeDiary(
          'test-keywords',
          character: AiCharacter.warmCounselor,
        );

        expect(result.analysisResult?.keywords, contains('테스트'));
      });

      test('존재하지 않는 일기 분석 시 CacheFailure를 던져야 한다', () async {
        expect(
          () => repository.analyzeDiary(
            'non-existent',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('updateDiary', () {
      test('일기 상태와 분석 결과를 업데이트해야 한다', () async {
        final testDiary = Diary(
          id: 'test-update',
          content: '업데이트 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        final updatedDiary = testDiary.copyWith(
          status: DiaryStatus.safetyBlocked,
          analysisResult: AnalysisResult(
            keywords: ['응급', '상황', '테스트'],
            sentimentScore: 1,
            empathyMessage: '응급 메시지',
            actionItem: '전화하세요',
            isEmergency: true,
          ),
        );

        await repository.updateDiary(updatedDiary);

        final result = await repository.getDiaryById('test-update');
        expect(result?.status, DiaryStatus.safetyBlocked);
      });
    });

    group('markActionCompleted', () {
      test('행동 완료 상태를 업데이트해야 한다', () async {
        final testDiary = Diary(
          id: 'test-action',
          content: '행동 완료 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.analyzed,
          analysisResult: AnalysisResult(
            keywords: ['테스트'],
            sentimentScore: 5,
            empathyMessage: '메시지',
            actionItem: '행동',
            isActionCompleted: false,
          ),
        );
        mockLocalDataSource.addDiary(testDiary);

        await repository.markActionCompleted('test-action');

        final result = await repository.getDiaryById('test-action');
        expect(result?.analysisResult?.isActionCompleted, true);
      });
    });

    group('deleteDiary', () {
      test('일기를 삭제해야 한다', () async {
        final testDiary = Diary(
          id: 'test-delete',
          content: '삭제 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        await repository.deleteDiary('test-delete');

        final result = await repository.getDiaryById('test-delete');
        expect(result, isNull);
      });

      test('존재하지 않는 일기 삭제 시 CacheFailure를 던져야 한다', () async {
        expect(
          () => repository.deleteDiary('non-existent'),
          throwsA(isA<CacheFailure>()),
        );
      });
    });
  });
}
