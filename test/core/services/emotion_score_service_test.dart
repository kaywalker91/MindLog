import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/emotion_score_service.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database testDb;
  late SqliteLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: SqliteLocalDataSource.onCreate,
      ),
    );
    SqliteLocalDataSource.testDatabase = testDb;
    dataSource = SqliteLocalDataSource();
    EmotionScoreService.setDataSource(dataSource);
  });

  tearDown(() async {
    EmotionScoreService.resetForTesting();
    SqliteLocalDataSource.testDatabase = null;
    await testDb.close();
  });

  group('EmotionScoreService', () {
    group('getRecentAverageScore', () {
      test('일기가 없으면 null을 반환해야 한다', () async {
        final result = await EmotionScoreService.getRecentAverageScore();
        expect(result, isNull);
      });

      test('분석된 일기가 없으면 null을 반환해야 한다', () async {
        // pending 상태 일기만 있음
        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '테스트 일기',
            createdAt: DateTime.now(),
            status: DiaryStatus.pending,
          ),
        );

        final result = await EmotionScoreService.getRecentAverageScore();
        expect(result, isNull);
      });

      test('분석된 일기가 있으면 평균 점수를 반환해야 한다', () async {
        final now = DateTime.now();

        // 분석 완료된 일기 3개 저장 (점수: 3, 5, 7)
        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '테스트 일기 1',
            createdAt: now.subtract(const Duration(days: 1)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 3, analyzedAt: now),
          ),
        );
        await dataSource.saveDiary(
          Diary(
            id: '2',
            content: '테스트 일기 2',
            createdAt: now.subtract(const Duration(days: 2)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 5, analyzedAt: now),
          ),
        );
        await dataSource.saveDiary(
          Diary(
            id: '3',
            content: '테스트 일기 3',
            createdAt: now.subtract(const Duration(days: 3)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 7, analyzedAt: now),
          ),
        );

        final result = await EmotionScoreService.getRecentAverageScore();
        expect(result, equals(5.0)); // (3 + 5 + 7) / 3 = 5.0
      });

      test('7일 이전 일기는 제외해야 한다', () async {
        final now = DateTime.now();

        // 최근 일기 (점수: 8)
        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '최근 일기',
            createdAt: now.subtract(const Duration(days: 1)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 8, analyzedAt: now),
          ),
        );

        // 오래된 일기 (점수: 2) - 8일 전
        await dataSource.saveDiary(
          Diary(
            id: '2',
            content: '오래된 일기',
            createdAt: now.subtract(const Duration(days: 8)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(
              sentimentScore: 2,
              analyzedAt: now.subtract(const Duration(days: 8)),
            ),
          ),
        );

        final result = await EmotionScoreService.getRecentAverageScore();
        expect(result, equals(8.0)); // 최근 일기만 포함
      });

      test('days 파라미터로 조회 기간을 변경할 수 있어야 한다', () async {
        final now = DateTime.now();

        // 3일 이내 일기 (점수: 6)
        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '최근 일기',
            createdAt: now.subtract(const Duration(days: 2)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 6, analyzedAt: now),
          ),
        );

        // 5일 전 일기 (점수: 4)
        await dataSource.saveDiary(
          Diary(
            id: '2',
            content: '5일 전 일기',
            createdAt: now.subtract(const Duration(days: 5)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(
              sentimentScore: 4,
              analyzedAt: now.subtract(const Duration(days: 5)),
            ),
          ),
        );

        // 3일 기준 조회
        final result3Days = await EmotionScoreService.getRecentAverageScore(
          days: 3,
        );
        expect(result3Days, equals(6.0));

        // 7일 기준 조회
        final result7Days = await EmotionScoreService.getRecentAverageScore(
          days: 7,
        );
        expect(result7Days, equals(5.0)); // (6 + 4) / 2 = 5.0
      });

      test('pending/failed 상태 일기는 제외해야 한다', () async {
        final now = DateTime.now();

        // 분석 완료 (점수: 7)
        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '분석 완료',
            createdAt: now.subtract(const Duration(days: 1)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 7, analyzedAt: now),
          ),
        );

        // 분석 실패
        await dataSource.saveDiary(
          Diary(
            id: '2',
            content: '분석 실패',
            createdAt: now.subtract(const Duration(days: 2)),
            status: DiaryStatus.failed,
          ),
        );

        // 대기 중
        await dataSource.saveDiary(
          Diary(
            id: '3',
            content: '대기 중',
            createdAt: now.subtract(const Duration(days: 3)),
            status: DiaryStatus.pending,
          ),
        );

        final result = await EmotionScoreService.getRecentAverageScore();
        expect(result, equals(7.0)); // 분석 완료된 것만 포함
      });
    });

    group('getRecentEmotionSummary', () {
      test('일기가 없으면 null을 반환해야 한다', () async {
        final result = await EmotionScoreService.getRecentEmotionSummary();
        expect(result, isNull);
      });

      test('평균 점수와 일기 수를 반환해야 한다', () async {
        final now = DateTime.now();

        await dataSource.saveDiary(
          Diary(
            id: '1',
            content: '일기 1',
            createdAt: now.subtract(const Duration(days: 1)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 4, analyzedAt: now),
          ),
        );
        await dataSource.saveDiary(
          Diary(
            id: '2',
            content: '일기 2',
            createdAt: now.subtract(const Duration(days: 2)),
            status: DiaryStatus.analyzed,
            analysisResult: AnalysisResult(sentimentScore: 6, analyzedAt: now),
          ),
        );

        final result = await EmotionScoreService.getRecentEmotionSummary();
        expect(result, isNotNull);
        expect(result!.avgScore, equals(5.0));
        expect(result.diaryCount, equals(2));
      });
    });
  });
}
