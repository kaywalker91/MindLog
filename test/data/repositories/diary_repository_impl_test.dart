import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/data/dto/analysis_response_dto.dart';
import 'package:mindlog/data/repositories/diary_repository_impl.dart';
import 'package:mindlog/domain/entities/diary.dart';

import '../../helpers/debug_print_helpers.dart';
import '../../mocks/mock_datasources.dart';

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

  tearDown(() {
    mockLocalDataSource.reset();
    mockRemoteDataSource.reset();
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

        expect(
          diary.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(
          diary.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          true,
        );
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
        mockLocalDataSource.addDiary(
          Diary(
            id: '1',
            content: '첫번째',
            createdAt: DateTime(2024, 1, 1),
            status: DiaryStatus.pending,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: '2',
            content: '두번째',
            createdAt: DateTime(2024, 1, 3),
            status: DiaryStatus.analyzed,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: '3',
            content: '세번째',
            createdAt: DateTime(2024, 1, 2),
            status: DiaryStatus.pending,
          ),
        );

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

      test('존재하지 않는 일기 분석 시 DataNotFoundFailure를 던져야 한다', () async {
        expect(
          () => repository.analyzeDiary(
            'non-existent',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<DataNotFoundFailure>()),
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
            analyzedAt: DateTime(2024, 1, 1, 12, 0),
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
            analyzedAt: DateTime(2024, 1, 1, 12, 0),
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

      test('존재하지 않는 일기 삭제 시 DataNotFoundFailure를 던져야 한다', () async {
        expect(
          () => repository.deleteDiary('non-existent'),
          throwsA(isA<DataNotFoundFailure>()),
        );
      });
    });

    group('getTodayDiaries', () {
      test('오늘 작성된 일기만 반환해야 한다', () async {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayNoon = todayStart.add(const Duration(hours: 12));
        final todayMorning = todayStart.add(const Duration(hours: 9));
        final yesterday = todayStart.subtract(const Duration(hours: 9));

        mockLocalDataSource.addDiary(
          Diary(
            id: 'today-1',
            content: '오늘 일기 1',
            createdAt: todayNoon,
            status: DiaryStatus.pending,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: 'today-2',
            content: '오늘 일기 2',
            createdAt: todayMorning,
            status: DiaryStatus.analyzed,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: 'yesterday',
            content: '어제 일기',
            createdAt: yesterday,
            status: DiaryStatus.pending,
          ),
        );

        final todayDiaries = await repository.getTodayDiaries();

        expect(todayDiaries.length, 2);
        expect(todayDiaries.any((d) => d.id == 'today-1'), true);
        expect(todayDiaries.any((d) => d.id == 'today-2'), true);
        expect(todayDiaries.any((d) => d.id == 'yesterday'), false);
      });

      test('오늘 일기가 없으면 빈 리스트를 반환해야 한다', () async {
        mockLocalDataSource.addDiary(
          Diary(
            id: 'old',
            content: '오래된 일기',
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
            status: DiaryStatus.pending,
          ),
        );

        final todayDiaries = await repository.getTodayDiaries();

        expect(todayDiaries, isEmpty);
      });
    });

    group('toggleDiaryPin', () {
      test('일기 고정 상태를 true로 변경해야 한다', () async {
        final testDiary = Diary(
          id: 'test-pin',
          content: '고정 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.analyzed,
          isPinned: false,
        );
        mockLocalDataSource.addDiary(testDiary);

        await repository.toggleDiaryPin('test-pin', true);

        final result = await repository.getDiaryById('test-pin');
        expect(result?.isPinned, true);
      });

      test('일기 고정 상태를 false로 변경해야 한다', () async {
        final testDiary = Diary(
          id: 'test-unpin',
          content: '고정 해제 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.analyzed,
          isPinned: true,
        );
        mockLocalDataSource.addDiary(testDiary);

        await repository.toggleDiaryPin('test-unpin', false);

        final result = await repository.getDiaryById('test-unpin');
        expect(result?.isPinned, false);
      });
    });

    group('deleteAllDiaries', () {
      test('모든 일기를 삭제해야 한다', () async {
        mockLocalDataSource.addDiary(
          Diary(
            id: '1',
            content: '일기 1',
            createdAt: DateTime.now(),
            status: DiaryStatus.pending,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: '2',
            content: '일기 2',
            createdAt: DateTime.now(),
            status: DiaryStatus.analyzed,
          ),
        );
        mockLocalDataSource.addDiary(
          Diary(
            id: '3',
            content: '일기 3',
            createdAt: DateTime.now(),
            status: DiaryStatus.failed,
          ),
        );

        await repository.deleteAllDiaries();

        final allDiaries = await repository.getAllDiaries();
        expect(allDiaries, isEmpty);
      });

      test('일기가 없어도 에러 없이 완료되어야 한다', () async {
        await repository.deleteAllDiaries();

        final allDiaries = await repository.getAllDiaries();
        expect(allDiaries, isEmpty);
      });
    });

    group('analyzeDiary - 실패 시 상태 업데이트', () {
      test('SafetyBlockException 발생 시 safetyBlocked 상태로 업데이트되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-safety',
          content: '안전 차단 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);
        mockRemoteDataSource.setCustomException(SafetyBlockException('안전 차단됨'));

        await expectLater(
          () => repository.analyzeDiary(
            'test-safety',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<SafetyBlockedFailure>()),
        );

        final result = await repository.getDiaryById('test-safety');
        expect(result?.status, DiaryStatus.safetyBlocked);
      });

      test('NetworkException 발생 시 failed 상태로 업데이트되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-network',
          content: '네트워크 오류 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);
        mockRemoteDataSource.setCustomException(NetworkException('네트워크 오류'));

        await expectLater(
          () => repository.analyzeDiary(
            'test-network',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<NetworkFailure>()),
        );

        final result = await repository.getDiaryById('test-network');
        expect(result?.status, DiaryStatus.failed);
      });

      test(
        '재시도 소진 후 NetworkException 발생 시 failed 상태와 NetworkFailure를 유지해야 한다',
        () async {
          final testDiary = Diary(
            id: 'test-network-retry-exhausted',
            content: '재시도 소진 테스트',
            createdAt: DateTime.now(),
            status: DiaryStatus.pending,
          );
          mockLocalDataSource.addDiary(testDiary);
          mockRemoteDataSource.setCustomException(
            NetworkException(
              '네트워크 연결에 실패했습니다. (3번 재시도): SocketException: Connection refused',
            ),
          );

          await expectLater(
            () => repository.analyzeDiary(
              'test-network-retry-exhausted',
              character: AiCharacter.warmCounselor,
            ),
            throwsA(
              isA<NetworkFailure>().having(
                (failure) => failure.message,
                'message',
                contains('네트워크 연결에 실패했습니다.'),
              ),
            ),
          );

          final result = await repository.getDiaryById(
            'test-network-retry-exhausted',
          );
          expect(result?.status, DiaryStatus.failed);
        },
      );

      test('ApiException 발생 시 failed 상태로 업데이트되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-api',
          content: 'API 오류 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);
        mockRemoteDataSource.setErrorMode('API 오류');

        await expectLater(
          () => repository.analyzeDiary(
            'test-api',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiFailure>()),
        );

        final result = await repository.getDiaryById('test-api');
        expect(result?.status, DiaryStatus.failed);
      });

      test('일기가 로드되지 않은 상태에서 실패 시 상태 업데이트를 시도하지 않아야 한다', () async {
        mockRemoteDataSource.shouldThrow = true;

        await expectLater(
          () => repository.analyzeDiary(
            'non-existent-diary',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<DataNotFoundFailure>()),
        );
      });

      test('userName 파라미터가 전달되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-username',
          content: '유저 이름 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(testDiary);

        final result = await repository.analyzeDiary(
          'test-username',
          character: AiCharacter.cheerfulFriend,
          userName: '홍길동',
        );

        expect(result.status, DiaryStatus.analyzed);
        expect(result.analysisResult, isNotNull);
        // 호출 추적 검증
        expect(mockRemoteDataSource.analyzeRequests.last['userName'], '홍길동');
        expect(
          mockRemoteDataSource.analyzeRequests.last['character'],
          AiCharacter.cheerfulFriend,
        );
      });
    });

    group('markActionCompleted - 엣지 케이스', () {
      test('analysisResult가 없는 일기는 무시되어야 한다', () async {
        final testDiary = Diary(
          id: 'test-no-analysis',
          content: '분석 결과 없는 일기',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
          analysisResult: null,
        );
        mockLocalDataSource.addDiary(testDiary);

        await repository.markActionCompleted('test-no-analysis');

        final result = await repository.getDiaryById('test-no-analysis');
        expect(result?.analysisResult, isNull);
      });

      test('존재하지 않는 일기는 DataNotFoundFailure를 던져야 한다', () async {
        expect(
          () => repository.markActionCompleted('non-existent'),
          throwsA(isA<DataNotFoundFailure>()),
        );
      });
    });

    group('analyzeDiary - Vision 실패 시 텍스트 폴백', () {
      setUp(muteDebugPrint);
      tearDown(restoreDebugPrint);

      test('Vision 413 실패 시 텍스트 분석으로 폴백해야 한다', () async {
        final diary = Diary(
          id: 'vision-fallback-413',
          content: '사진이 있는 일기 내용입니다.',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
          imagePaths: const ['/tmp/photo.jpg'],
        );
        mockLocalDataSource.addDiary(diary);
        mockRemoteDataSource.visionShouldThrow = true;
        mockRemoteDataSource.visionException = ApiException(
          message: '요청이 너무 큽니다.',
          statusCode: 413,
        );

        final result = await repository.analyzeDiary(
          'vision-fallback-413',
          character: AiCharacter.warmCounselor,
        );

        expect(result.status, DiaryStatus.analyzed);
        expect(mockRemoteDataSource.visionRequests.length, 1);
        expect(mockRemoteDataSource.analyzeRequests.length, 1);
      });

      test('Vision 429 실패 시 텍스트 분석으로 폴백해야 한다', () async {
        final diary = Diary(
          id: 'vision-fallback-429',
          content: '사진이 있는 일기 내용입니다.',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
          imagePaths: const ['/tmp/photo.jpg'],
        );
        mockLocalDataSource.addDiary(diary);
        mockRemoteDataSource.visionShouldThrow = true;
        mockRemoteDataSource.visionException = ApiException(
          message: '요청 제한을 초과했습니다.',
          statusCode: 429,
        );

        final result = await repository.analyzeDiary(
          'vision-fallback-429',
          character: AiCharacter.warmCounselor,
        );

        expect(result.status, DiaryStatus.analyzed);
        expect(mockRemoteDataSource.visionRequests.length, 1);
        expect(mockRemoteDataSource.analyzeRequests.length, 1);
      });
    });

    // ── P0-2: Groq 응답 캐싱 ────────────────────────────────────
    group('analyzeDiary - Groq 응답 캐싱', () {
      setUp(muteDebugPrint);
      tearDown(restoreDebugPrint);
      test('첫 호출은 cache miss → 원격 호출 + 캐시 저장', () async {
        final diary = Diary(
          id: 'cache-1',
          content: '동일 내용 캐싱 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(diary);

        await repository.analyzeDiary(
          'cache-1',
          character: AiCharacter.warmCounselor,
        );

        expect(mockRemoteDataSource.callCount, 1);
        expect(mockLocalDataSource.groqCacheSize, 1);
      });

      test(
        '동일 content/character/userName 두 번째 호출은 cache hit → 원격 미호출',
        () async {
          final diary1 = Diary(
            id: 'cache-2a',
            content: '캐시 동일 내용',
            createdAt: DateTime.now(),
            status: DiaryStatus.pending,
          );
          final diary2 = Diary(
            id: 'cache-2b',
            content: '캐시 동일 내용',
            createdAt: DateTime.now(),
            status: DiaryStatus.pending,
          );
          mockLocalDataSource.addDiary(diary1);
          mockLocalDataSource.addDiary(diary2);

          await repository.analyzeDiary(
            'cache-2a',
            character: AiCharacter.warmCounselor,
          );
          expect(mockRemoteDataSource.callCount, 1);

          await repository.analyzeDiary(
            'cache-2b',
            character: AiCharacter.warmCounselor,
          );

          // 두 번째 호출은 cache hit → 여전히 1
          expect(
            mockRemoteDataSource.callCount,
            1,
            reason: '동일 content는 cache hit이어야 한다',
          );
        },
      );

      test('character가 다르면 cache miss → 두 번째 호출도 원격', () async {
        final diary1 = Diary(
          id: 'cache-3a',
          content: '같은 내용 다른 캐릭터',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        final diary2 = Diary(
          id: 'cache-3b',
          content: '같은 내용 다른 캐릭터',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(diary1);
        mockLocalDataSource.addDiary(diary2);

        await repository.analyzeDiary(
          'cache-3a',
          character: AiCharacter.warmCounselor,
        );
        await repository.analyzeDiary(
          'cache-3b',
          character: AiCharacter.cheerfulFriend,
        );

        expect(
          mockRemoteDataSource.callCount,
          2,
          reason: 'character가 다르면 캐시 키도 다르다',
        );
      });

      test('content 양끝 공백 차이는 정규화되어 cache hit', () async {
        final diary1 = Diary(
          id: 'cache-4a',
          content: '정규화 테스트',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        final diary2 = Diary(
          id: 'cache-4b',
          content: '   정규화   테스트   ',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(diary1);
        mockLocalDataSource.addDiary(diary2);

        await repository.analyzeDiary(
          'cache-4a',
          character: AiCharacter.warmCounselor,
        );
        await repository.analyzeDiary(
          'cache-4b',
          character: AiCharacter.warmCounselor,
        );

        expect(mockRemoteDataSource.callCount, 1);
      });

      test('is_emergency=true 응답은 캐시되지 않아 다음 호출도 원격', () async {
        // 응급 응답 설정
        mockRemoteDataSource.setMockResponse(
          const AnalysisResponseDto(
            keywords: ['응급', '위기', '도움', '지원', '연락'],
            sentimentScore: 1,
            empathyMessage: '많이 힘드시군요.',
            actionItem: '전문가에게 연락하세요.',
            isEmergency: true,
            emotionCategory: EmotionCategoryDto(primary: '슬픔', secondary: '절망'),
          ),
        );

        final diary1 = Diary(
          id: 'cache-5a',
          content: '위기 표현 내용',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        final diary2 = Diary(
          id: 'cache-5b',
          content: '위기 표현 내용',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(diary1);
        mockLocalDataSource.addDiary(diary2);

        await repository.analyzeDiary(
          'cache-5a',
          character: AiCharacter.warmCounselor,
        );
        await repository.analyzeDiary(
          'cache-5b',
          character: AiCharacter.warmCounselor,
        );

        expect(
          mockRemoteDataSource.callCount,
          2,
          reason: '위기 응답은 캐시하지 않아 매번 재평가',
        );
        expect(mockLocalDataSource.groqCacheSize, 0);
      });

      test('Vision 분석(이미지 포함)도 동일 imagePaths 시 cache hit', () async {
        final diary1 = Diary(
          id: 'cache-6a',
          content: '비전 캐싱',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
          imagePaths: ['/img/a.jpg', '/img/b.jpg'],
        );
        final diary2 = Diary(
          id: 'cache-6b',
          content: '비전 캐싱',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
          // 순서 다름 — 키 정렬 후 동일해야 함
          imagePaths: ['/img/b.jpg', '/img/a.jpg'],
        );
        mockLocalDataSource.addDiary(diary1);
        mockLocalDataSource.addDiary(diary2);

        await repository.analyzeDiary(
          'cache-6a',
          character: AiCharacter.warmCounselor,
        );
        await repository.analyzeDiary(
          'cache-6b',
          character: AiCharacter.warmCounselor,
        );

        expect(mockRemoteDataSource.visionRequests.length, 1);
        expect(mockRemoteDataSource.callCount, 1);
      });

      test('cache 저장 실패는 분석을 막지 않는다', () async {
        mockLocalDataSource.shouldThrowOnGroqCache = true;

        final diary = Diary(
          id: 'cache-7',
          content: '캐시 실패 회복',
          createdAt: DateTime.now(),
          status: DiaryStatus.pending,
        );
        mockLocalDataSource.addDiary(diary);

        final result = await repository.analyzeDiary(
          'cache-7',
          character: AiCharacter.warmCounselor,
        );

        expect(result.status, DiaryStatus.analyzed);
        expect(result.analysisResult, isNotNull);
      });
    });
  });
}
