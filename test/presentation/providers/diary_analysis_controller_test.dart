import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/presentation/providers/diary_analysis_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../helpers/firebase_test_helpers.dart';
import '../../mocks/mock_repositories.dart';

/// Mock AnalyzeDiaryUseCase
class MockAnalyzeDiaryUseCase implements AnalyzeDiaryUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  Diary? mockDiary;
  DiaryStatus? mockStatus;
  Exception? genericException; // Failure가 아닌 일반 Exception throw용

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

void main() {
  late ProviderContainer container;
  late MockAnalyzeDiaryUseCase mockUseCase;
  late MockStatisticsRepository mockStatisticsRepository;

  setUpAll(() {
    setupFirebaseCoreMocks();
  });

  setUp(() {
    mockUseCase = MockAnalyzeDiaryUseCase();
    mockStatisticsRepository = MockStatisticsRepository();

    container = ProviderContainer(
      overrides: [
        analyzeDiaryUseCaseProvider.overrideWithValue(mockUseCase),
        statisticsRepositoryProvider.overrideWithValue(mockStatisticsRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    mockUseCase.reset();
    mockStatisticsRepository.reset();
  });

  group('DiaryAnalysisNotifier', () {
    group('초기 상태', () {
      test('DiaryAnalysisInitial 상태여야 한다', () {
        // Act
        final state = container.read(diaryAnalysisControllerProvider);

        // Assert
        expect(state, isA<DiaryAnalysisInitial>());
      });
    });

    group('analyzeDiary', () {
      test('분석 중에는 Loading 상태여야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
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
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);

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
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.mockDiary = DiaryFixtures.analyzed();

        // Act
        await notifier.analyzeDiary('테스트 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider) as DiaryAnalysisSuccess;
        expect(state.diary.analysisResult, isNotNull);
        expect(state.diary.status, DiaryStatus.analyzed);
      });

      test('일반 실패 시 Error 상태로 전환해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.shouldThrow = true;
        mockUseCase.failureToThrow = const Failure.api(message: 'API 오류');

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
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.shouldThrow = true;
        mockUseCase.failureToThrow = const Failure.safetyBlocked();

        // Act
        await notifier.analyzeDiary('위험한 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisSafetyBlocked>());
      });

      test('NetworkFailure를 올바르게 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.shouldThrow = true;
        mockUseCase.failureToThrow = const Failure.network(message: '네트워크 오류');

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
        expect((state as DiaryAnalysisError).failure, isA<NetworkFailure>());
      });

      test('analysisResult가 null이고 safetyBlocked가 아니면 Error 상태여야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        // 분석 결과 없이 pending 상태인 일기 반환
        mockUseCase.mockDiary = DiaryFixtures.pending();

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
      });

      test('safetyBlocked 상태의 Diary는 Success로 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.mockDiary = DiaryFixtures.safetyBlocked();

        // Act
        await notifier.analyzeDiary('위험 감지된 내용');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisSuccess>());
        expect((state as DiaryAnalysisSuccess).diary.status, DiaryStatus.safetyBlocked);
      });

      test('UseCase에 content를 올바르게 전달해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        const testContent = '오늘의 특별한 일기 내용';

        // Act
        await notifier.analyzeDiary(testContent);

        // Assert
        expect(mockUseCase.analyzedContents, contains(testContent));
      });

      test('Failure throw 시 UnknownFailure로 처리해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        // Failure를 throw하도록 설정
        mockUseCase.shouldThrow = true;
        mockUseCase.failureToThrow = null;  // 기본 Unknown Failure 반환

        // Act
        await notifier.analyzeDiary('테스트');

        // Assert
        final state = container.read(diaryAnalysisControllerProvider);
        expect(state, isA<DiaryAnalysisError>());
        expect((state as DiaryAnalysisError).failure, isA<UnknownFailure>());
      });

      test('일반 Exception 발생 시 UnknownFailure로 래핑해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        // Failure가 아닌 일반 Exception throw
        mockUseCase.genericException = Exception('일반 예외 발생');

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
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        await notifier.analyzeDiary('테스트 내용');
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisSuccess>());

        // Act
        notifier.reset();

        // Assert
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisInitial>());
      });

      test('Error 상태에서도 Initial로 복귀해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.shouldThrow = true;
        await notifier.analyzeDiary('테스트');
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisError>());

        // Act
        notifier.reset();

        // Assert
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisInitial>());
      });

      test('SafetyBlocked 상태에서도 Initial로 복귀해야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);
        mockUseCase.shouldThrow = true;
        mockUseCase.failureToThrow = const SafetyBlockedFailure();
        await notifier.analyzeDiary('테스트');
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisSafetyBlocked>());

        // Act
        notifier.reset();

        // Assert
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisInitial>());
      });
    });

    group('상태 전환 시나리오', () {
      test('연속 분석 시 상태가 올바르게 전환되어야 한다', () async {
        // Arrange
        final notifier = container.read(diaryAnalysisControllerProvider.notifier);

        // Act & Assert - 첫 번째 분석
        await notifier.analyzeDiary('첫 번째 일기');
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisSuccess>());

        // Reset 후 두 번째 분석
        notifier.reset();
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisInitial>());

        mockUseCase.shouldThrow = true;
        await notifier.analyzeDiary('두 번째 일기');
        expect(container.read(diaryAnalysisControllerProvider), isA<DiaryAnalysisError>());
      });
    });
  });

  group('diaryListProvider', () {
    test('diaryRepositoryProvider에서 일기 목록을 조회해야 한다', () async {
      // Arrange
      final mockDiaryRepository = MockDiaryRepository();
      mockDiaryRepository.diaries = DiaryFixtures.weekOfDiaries();

      final testContainer = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        ],
      );
      addTearDown(testContainer.dispose);

      // Act
      final diaries = await testContainer.read(diaryListProvider.future);

      // Assert
      expect(diaries.length, 7);
    });
  });

  group('todayDiariesProvider', () {
    test('오늘 작성된 일기만 조회해야 한다', () async {
      // Arrange
      final mockDiaryRepository = MockDiaryRepository();
      final now = DateTime.now();
      mockDiaryRepository.diaries = [
        DiaryFixtures.analyzed(id: 'today-1', createdAt: now),
        DiaryFixtures.analyzed(id: 'yesterday', createdAt: now.subtract(const Duration(days: 1))),
      ];

      final testContainer = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        ],
      );
      addTearDown(testContainer.dispose);

      // Act
      final todayDiaries = await testContainer.read(todayDiariesProvider.future);

      // Assert
      expect(todayDiaries.length, 1);
      expect(todayDiaries.first.id, 'today-1');
    });
  });
}
