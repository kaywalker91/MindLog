import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/today_emotion_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockDiaryRepository();
    when(
      () => mockRepository.getAllDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getTodayDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.createDiary(
        any(),
        imagePaths: any(named: 'imagePaths'),
      ),
    ).thenAnswer((_) async => DiaryFixtures.pending());
    when(
      () => mockRepository.updateDiary(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.deleteDiary(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.toggleDiaryPin(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.deleteAllDiaries(),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.setDiarySecret(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.getSecretDiaries(),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TodayEmotionProvider', () {
    group('일기가 없는 경우', () {
      test('빈 목록일 때 TodayEmotionStatus.empty를 반환해야 한다', () async {
        // Arrange - already stubbed to return []

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, false);
        expect(todayEmotion.emoji, isNull);
        expect(todayEmotion.sentimentScore, isNull);
        expect(todayEmotion.diaryCount, 0);
      });

      test('어제 일기만 있을 때 hasWrittenToday가 false여야 한다', () async {
        // Arrange
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(id: 'yesterday', createdAt: yesterday),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, false);
        expect(todayEmotion.diaryCount, 0);
      });
    });

    group('오늘 일기가 있는 경우', () {
      test('오늘 분석 완료된 일기가 있으면 이모지를 반환해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(
              id: 'today',
              createdAt: now,
              sentimentScore: 8,
            ),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, true);
        expect(todayEmotion.emoji, '😊'); // score 8 -> 😊
        expect(todayEmotion.sentimentScore, 8);
        expect(todayEmotion.diaryCount, 1);
      });

      test('오늘 pending 상태 일기만 있으면 emoji가 null이어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.pending(id: 'today-pending', createdAt: now),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, true);
        expect(todayEmotion.emoji, isNull);
        expect(todayEmotion.sentimentScore, isNull);
        expect(todayEmotion.diaryCount, 1);
      });

      test('오늘 여러 일기가 있으면 가장 최근 일기의 감정을 반환해야 한다', () async {
        // Arrange
        // 정오 기준으로 시간을 설정하여 타임존에 관계없이 같은 날짜로 인식되도록 함
        final now = DateTime.now();
        final todayNoon = DateTime(now.year, now.month, now.day, 12, 0);
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(
              id: 'today-1',
              createdAt: todayNoon.subtract(const Duration(hours: 2)), // 10:00
              sentimentScore: 3,
            ),
            DiaryFixtures.analyzed(
              id: 'today-latest',
              createdAt: todayNoon, // 12:00
              sentimentScore: 9,
            ),
            DiaryFixtures.analyzed(
              id: 'today-2',
              createdAt: todayNoon.subtract(const Duration(hours: 1)), // 11:00
              sentimentScore: 5,
            ),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, true);
        expect(todayEmotion.emoji, '🥰'); // score 9 -> 🥰
        expect(todayEmotion.sentimentScore, 9);
        expect(todayEmotion.diaryCount, 3);
      });
    });

    group('감정 이모지 매핑', () {
      final testCases = [
        (score: 1, emoji: '😭'),
        (score: 2, emoji: '😭'),
        (score: 3, emoji: '😢'),
        (score: 4, emoji: '😢'),
        (score: 5, emoji: '🙂'),
        (score: 6, emoji: '🙂'),
        (score: 7, emoji: '😊'),
        (score: 8, emoji: '😊'),
        (score: 9, emoji: '🥰'),
        (score: 10, emoji: '🥰'),
      ];

      for (final testCase in testCases) {
        test('감정 점수 ${testCase.score}은 ${testCase.emoji}로 표시되어야 한다', () async {
          // Arrange
          final now = DateTime.now();
          when(() => mockRepository.getAllDiaries()).thenAnswer(
            (_) async => [
              DiaryFixtures.analyzed(
                id: 'test',
                createdAt: now,
                sentimentScore: testCase.score,
              ),
            ],
          );

          // Act
          await container.read(diaryListControllerProvider.future);
          final todayEmotion = container.read(todayEmotionProvider);

          // Assert
          expect(todayEmotion.emoji, testCase.emoji);
          expect(todayEmotion.sentimentScore, testCase.score);
        });
      }
    });

    group('오늘 날짜 경계 테스트', () {
      test('오늘 00:00에 작성한 일기도 오늘로 인식해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(id: 'midnight', createdAt: todayMidnight),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, true);
        expect(todayEmotion.diaryCount, 1);
      });

      test('어제 23:59에 작성한 일기는 오늘로 인식하지 않아야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final yesterdayLate = todayMidnight.subtract(
          const Duration(minutes: 1),
        );
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(
              id: 'yesterday-late',
              createdAt: yesterdayLate,
            ),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, false);
        expect(todayEmotion.diaryCount, 0);
      });
    });

    group('혼합 상태 테스트', () {
      test('오늘+어제 일기가 섞여 있을 때 오늘 일기만 카운트해야 한다', () async {
        // Arrange
        // 정오 기준으로 시간을 설정하여 타임존에 관계없이 같은 날짜로 인식되도록 함
        final now = DateTime.now();
        final todayNoon = DateTime(now.year, now.month, now.day, 12, 0);
        final yesterday = todayNoon.subtract(const Duration(days: 1));
        when(() => mockRepository.getAllDiaries()).thenAnswer(
          (_) async => [
            DiaryFixtures.analyzed(
              id: 'today-1',
              createdAt: todayNoon,
              sentimentScore: 7,
            ),
            DiaryFixtures.analyzed(id: 'yesterday-1', createdAt: yesterday),
            DiaryFixtures.analyzed(
              id: 'today-2',
              createdAt: todayNoon.subtract(const Duration(hours: 1)), // 11:00
              sentimentScore: 5,
            ),
          ],
        );

        // Act
        await container.read(diaryListControllerProvider.future);
        final todayEmotion = container.read(todayEmotionProvider);

        // Assert
        expect(todayEmotion.hasWrittenToday, true);
        expect(todayEmotion.diaryCount, 2);
        expect(todayEmotion.emoji, '😊'); // 최신 일기 score 7 -> 😊
      });
    });
  });
}
