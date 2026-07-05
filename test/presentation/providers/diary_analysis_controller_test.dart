import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/presentation/providers/diary_analysis_controller.dart';
import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/statistics_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../fixtures/diary_fixtures.dart';
import '../../fixtures/statistics_fixtures.dart';
import '../../helpers/firebase_test_helpers.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../helpers/notification_test_helpers.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_usecases.dart';

void main() {
  late ProviderContainer container;
  late MockAnalyzeDiaryUseCase mockUseCase;
  late MockStatisticsRepository mockStatisticsRepository;
  late MockDiaryRepository mockDiaryRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    setupFirebaseCoreMocks();
    registerMockFallbackValues();
    tz_data.initializeTimeZones();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDiaryAnalysisSideEffectMocks();

    mockUseCase = MockAnalyzeDiaryUseCase();
    mockStatisticsRepository = MockStatisticsRepository();
    mockDiaryRepository = MockDiaryRepository();
    mockSettingsRepository = MockSettingsRepository();

    // Default stub: return an analyzed diary
    when(
      () => mockUseCase.execute(
        any(),
        imagePaths: any(named: 'imagePaths'),
        entryDate: any(named: 'entryDate'),
      ),
    ).thenAnswer(
      (invocation) async => DiaryFixtures.analyzed(
        content: invocation.positionalArguments[0] as String,
      ),
    );

    // DiaryRepository stubs
    when(() => mockDiaryRepository.getAllDiaries()).thenAnswer((_) async => []);
    when(
      () => mockDiaryRepository.getTodayDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockDiaryRepository.createDiary(
        any(),
        imagePaths: any(named: 'imagePaths'),
        createdAt: any(named: 'createdAt'),
      ),
    ).thenAnswer((_) async => DiaryFixtures.pending());
    when(() => mockDiaryRepository.updateDiary(any())).thenAnswer((_) async {});
    when(() => mockDiaryRepository.deleteDiary(any())).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.toggleDiaryPin(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockDiaryRepository.deleteAllDiaries()).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.setDiarySecret(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.getSecretDiaries(),
    ).thenAnswer((_) async => []);

    // StatisticsRepository stubs
    when(
      () => mockStatisticsRepository.getStatistics(any()),
    ).thenAnswer((_) async => StatisticsFixtures.empty());
    when(
      () => mockStatisticsRepository.getDailyEmotions(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockStatisticsRepository.getActivityMap(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => {});

    when(
      () => mockSettingsRepository.getNotificationSettings(),
    ).thenAnswer((_) async => NotificationSettings.defaults());
    when(
      () => mockSettingsRepository.getSelfEncouragementMessages(),
    ).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepository.setNotificationSettings(any()),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        analyzeDiaryUseCaseProvider.overrideWithValue(mockUseCase),
        statisticsRepositoryProvider.overrideWithValue(
          mockStatisticsRepository,
        ),
        diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
      ],
    );
    addTearDown(() async {
      await drainPostAnalysisSideEffects();
      container.dispose();
    });
  });

  tearDown(teardownDiaryAnalysisSideEffectMocks);

  group('DiaryAnalysisNotifier', () {
    group('초기 상태', () {
      test('DiaryAnalysisInitial 상태여야 한다', () {
        // Act
        final state = container.read(diaryAnalysisControllerProvider);

        // Assert
        expect(state, isA<DiaryAnalysisInitial>());
      });
    });

    group('Provider Invalidation', () {
      test(
        'analyzeDiary 성공 후 statisticsProvider는 무효화되고 diaryList는 낙관적 갱신되어야 한다',
        () async {
          // Arrange — 호출 횟수 카운터
          // 분석 후: stats는 invalidate(재빌드), diaryList는 addOrUpdateDiary(메모리만 갱신)
          var statsCallCount = 0;
          var diaryCallCount = 0;
          final analyzedDiary = DiaryFixtures.analyzed();
          when(() => mockStatisticsRepository.getStatistics(any())).thenAnswer((
            _,
          ) async {
            statsCallCount++;
            return StatisticsFixtures.empty();
          });
          when(() => mockDiaryRepository.getAllDiaries()).thenAnswer((_) async {
            diaryCallCount++;
            return [];
          });
          when(
            () => mockUseCase.execute(
              any(),
              imagePaths: any(named: 'imagePaths'),
              entryDate: any(named: 'entryDate'),
            ),
          ).thenAnswer((_) async => analyzedDiary);

          // 초기화 (각 1회 호출)
          await container.read(statisticsProvider.future);
          await container.read(diaryListControllerProvider.future);
          final initialStatsCount = statsCallCount;
          final initialDiaryCount = diaryCallCount;

          // Act
          final notifier = container.read(
            diaryAnalysisControllerProvider.notifier,
          );
          await notifier.analyzeDiary('테스트 내용');

          await container.read(statisticsProvider.future);
          await container.read(diaryListControllerProvider.future);

          // Assert: statisticsProvider는 invalidate → 재빌드
          expect(
            statsCallCount,
            greaterThan(initialStatsCount),
            reason: 'statisticsProvider가 무효화되어 재빌드되어야 합니다',
          );

          // Assert: diaryList는 풀스캔 없이 낙관적 갱신
          expect(
            diaryCallCount,
            equals(initialDiaryCount),
            reason: 'diaryList는 addOrUpdateDiary로 메모리만 갱신 — DB 풀스캔 발생 금지',
          );

          // Assert: 분석된 diary가 list state에 반영되었는지 확인
          final list = await container.read(diaryListControllerProvider.future);
          expect(
            list.any((d) => d.id == analyzedDiary.id),
            isTrue,
            reason: '분석 완료된 diary가 목록에 즉시 반영되어야 합니다',
          );
        },
      );

      test('safetyBlocked 상태에서도 statistics는 무효화 + diaryList는 낙관적 갱신', () async {
        // Arrange — 호출 횟수 카운터
        var statsCallCount = 0;
        var diaryCallCount = 0;
        final blockedDiary = DiaryFixtures.safetyBlocked();
        when(() => mockStatisticsRepository.getStatistics(any())).thenAnswer((
          _,
        ) async {
          statsCallCount++;
          return StatisticsFixtures.empty();
        });
        when(() => mockDiaryRepository.getAllDiaries()).thenAnswer((_) async {
          diaryCallCount++;
          return [];
        });
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenAnswer((_) async => blockedDiary);

        // 초기화
        await container.read(statisticsProvider.future);
        await container.read(diaryListControllerProvider.future);
        final initialStatsCount = statsCallCount;
        final initialDiaryCount = diaryCallCount;

        // Act
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        await notifier.analyzeDiary('위험 내용');

        await container.read(statisticsProvider.future);
        await container.read(diaryListControllerProvider.future);

        // Assert
        expect(statsCallCount, greaterThan(initialStatsCount));
        expect(
          diaryCallCount,
          equals(initialDiaryCount),
          reason: 'safetyBlocked에서도 풀스캔 금지 — addOrUpdateDiary 사용',
        );

        final list = await container.read(diaryListControllerProvider.future);
        expect(list.any((d) => d.id == blockedDiary.id), isTrue);
      });

      test('pending 상태(분석 실패)에서는 provider를 무효화하지 않아야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenAnswer((_) async => DiaryFixtures.pending());

        final initialStats = await container.read(statisticsProvider.future);
        final initialList = await container.read(
          diaryListControllerProvider.future,
        );

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert - pending(에러 상태)이므로 무효화하지 않음
        // 같은 인스턴스여야 함 (invalidate 되지 않았다는 증거)
        final newStats = await container.read(statisticsProvider.future);
        final newList = await container.read(
          diaryListControllerProvider.future,
        );

        expect(
          identical(initialStats, newStats),
          isTrue,
          reason: 'pending 상태에서는 statisticsProvider를 무효화하지 않아야 합니다',
        );
        expect(
          identical(initialList, newList),
          isTrue,
          reason: 'pending 상태에서는 diaryListControllerProvider를 무효화하지 않아야 합니다',
        );
      });
    });

    group('analyzeDiary', () {
      test('분석 중에는 Loading 상태여야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        final states = <DiaryAnalysisState>[];

        container.listen(
          diaryAnalysisControllerProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        // Act
        await notifier.analyzeDiary('오늘 하루 행복했다');

        // Assert - Loading 상태를 거쳤는지 확인
        expect(states.any((s) => s is DiaryAnalysisLoading), true);
      });

      test('분석 성공 시 Success 상태로 전환해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );

        // Act
        await notifier.analyzeDiary('오늘 하루 정말 행복했다');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisSuccess>());

        final successState = state as DiaryAnalysisSuccess;
        expect(successState.diary.content, '오늘 하루 정말 행복했다');
      });

      test('분석된 Diary에 analysisResult가 포함되어야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenAnswer((_) async => DiaryFixtures.analyzed());

        // Act
        await notifier.analyzeDiary('테스트 내용');

        // Assert
        final state =
            container.read(diaryAnalysisControllerProvider)
                as DiaryAnalysisSuccess;
        expect(state.diary.analysisResult, isNotNull);
        expect(state.diary.status, DiaryStatus.analyzed);
      });

      test('일반 실패 시 Error 상태로 전환해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.api(message: 'API 오류'));

        // Act
        await notifier.analyzeDiary('테스트 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());

        final errorState = state as DiaryAnalysisError;
        expect(errorState.failure, isA<ApiFailure>());
      });

      test('SafetyBlockedFailure 시 SafetyBlocked 상태로 전환해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.safetyBlocked());

        // Act
        await notifier.analyzeDiary('위험한 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisSafetyBlocked>());
      });

      test('NetworkFailure를 올바르게 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.network(message: '네트워크 오류'));

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
        expect((state as DiaryAnalysisError).failure, isA<NetworkFailure>());
      });

      test('analysisResult가 null이고 safetyBlocked가 아니면 Error 상태여야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        // 분석 결과 없이 pending 상태인 일기 반환
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenAnswer((_) async => DiaryFixtures.pending());

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
      });

      test('safetyBlocked 상태의 Diary는 Success로 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenAnswer((_) async => DiaryFixtures.safetyBlocked());

        // Act
        await notifier.analyzeDiary('위험 감지된 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisSuccess>());
        expect(
          (state as DiaryAnalysisSuccess).diary.status,
          DiaryStatus.safetyBlocked,
        );
      });

      test('UseCase에 content를 올바르게 전달해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        const testContent = '오늘의 특별한 일기 내용';

        // Act
        await notifier.analyzeDiary(testContent);

        // Assert
        verify(
          () => mockUseCase.execute(
            testContent,
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).called(1);
      });

      test('Failure throw 시 UnknownFailure로 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        // Failure를 throw하도록 설정 - default Unknown Failure
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.unknown(message: '분석 실패'));

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
        expect((state as DiaryAnalysisError).failure, isA<UnknownFailure>());
      });

      test('일반 Exception 발생 시 UnknownFailure로 래핑해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        // Failure가 아닌 일반 Exception throw
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(Exception('일반 예외 발생'));

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
        final errorState = state as DiaryAnalysisError;
        expect(errorState.failure, isA<UnknownFailure>());
        expect(errorState.failure.message, contains('일반 예외 발생'));
      });
    });

    group('reset', () {
      test('Initial 상태로 복귀해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        await notifier.analyzeDiary('테스트 내용');
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisSuccess>(),
        );

        // Act
        notifier.reset();

        // Assert
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisInitial>(),
        );
      });

      test('Error 상태에서도 Initial로 복귀해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.unknown(message: '분석 실패'));
        await notifier.analyzeDiary('테스트');
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisError>(),
        );

        // Act
        notifier.reset();

        // Assert
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisInitial>(),
        );
      });

      test('SafetyBlocked 상태에서도 Initial로 복귀해야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );
        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const SafetyBlockedFailure());
        await notifier.analyzeDiary('테스트');
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisSafetyBlocked>(),
        );

        // Act
        notifier.reset();

        // Assert
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisInitial>(),
        );
      });
    });

    group('상태 전환 시나리오', () {
      test('연속 분석 시 상태가 올바르게 전환되어야 한다', () async {
        // Arrange
        final notifier = container.read(
          diaryAnalysisControllerProvider.notifier,
        );

        // Act & Assert - 첫 번째 분석
        await notifier.analyzeDiary('첫 번째 일기');
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisSuccess>(),
        );

        // Reset 후 두 번째 분석
        notifier.reset();
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisInitial>(),
        );

        when(
          () => mockUseCase.execute(
            any(),
            imagePaths: any(named: 'imagePaths'),
            entryDate: any(named: 'entryDate'),
          ),
        ).thenThrow(const Failure.unknown(message: '분석 실패'));
        await notifier.analyzeDiary('두 번째 일기');
        expect(
          container.read(diaryAnalysisControllerProvider),
          isA<DiaryAnalysisError>(),
        );
      });
    });
  });
}
