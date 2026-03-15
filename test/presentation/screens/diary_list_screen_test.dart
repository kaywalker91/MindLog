import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

/// DiaryListScreen 스크롤 테스트 (데이터 레이어 검증)
///
/// 이 테스트는 일기 목록이 5개로 제한되는지 여부를 확인합니다.
/// FlutterFire 의존성 때문에 Widget 테스트 대신 Provider 테스트로 구현합니다.
void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockDiaryRepository();
    when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('일기 목록 개수 제한 테스트 (5개 제한 버그 확인)', () {
    test('7개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 일주일치 일기 (7개)
      final diaries = DiaryFixtures.weekOfDiaries();
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);
      expect(diaries.length, 7);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 5개 제한 없이 모든 7개 반환
      expect(result.length, 7, reason: '일기 목록이 5개로 제한되면 안 됩니다');
    });

    test('10개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 10개 일기 생성
      final diaries = List.generate(10, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          content: '일기 $index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 10개 반환
      expect(result.length, 10, reason: '5개 제한 버그가 없어야 합니다');
    });

    test('20개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 20개 일기 생성
      final diaries = List.generate(20, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          content: '일기 $index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 20개 반환
      expect(result.length, 20);
    });

    test('30개 일기가 있을 때 모두 반환해야 한다 (한 달치)', () async {
      // Arrange - 한 달치 일기 (30개)
      final diaries = DiaryFixtures.monthOfDiaries();
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);
      expect(diaries.length, 30);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 30개 반환
      expect(result.length, 30);
    });

    test('빈 목록도 올바르게 처리해야 한다', () async {
      // Arrange
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => []);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert
      expect(result, isEmpty);
    });

    test('정확히 5개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 정확히 5개
      final diaries = List.generate(5, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert
      expect(result.length, 5);
    });

    test('정확히 6개 일기가 있을 때 모두 반환해야 한다 (5개 경계 테스트)', () async {
      // Arrange - 5개 경계 바로 다음 (6개)
      final diaries = List.generate(6, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 5개 제한이 있다면 이 테스트 실패
      expect(result.length, 6, reason: '5개 제한이 있으면 안 됩니다');
    });
  });

  group('일기 목록 정렬 테스트', () {
    test('최신 일기가 먼저 표시되어야 한다', () async {
      // Arrange
      final now = DateTime.now();
      final diaries = [
        DiaryFixtures.analyzed(
          id: 'old',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        DiaryFixtures.analyzed(id: 'newest', createdAt: now),
        DiaryFixtures.analyzed(
          id: 'middle',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 최신순 정렬
      expect(result[0].id, 'newest');
      expect(result[1].id, 'middle');
      expect(result[2].id, 'old');
    });

    test('고정된 일기가 먼저 표시되어야 한다', () async {
      // Arrange
      final now = DateTime.now();
      final diaries = [
        DiaryFixtures.analyzed(id: 'newest', createdAt: now, isPinned: false),
        DiaryFixtures.analyzed(
          id: 'old-pinned',
          createdAt: now.subtract(const Duration(days: 5)),
          isPinned: true,
        ),
      ];
      when(() => mockRepository.getAllDiaries()).thenAnswer((_) async => diaries);

      // Act
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 고정된 일기 먼저
      expect(result[0].id, 'old-pinned');
      expect(result[0].isPinned, true);
      expect(result[1].id, 'newest');
    });
  });

  group('일기 목록 새로고침 테스트', () {
    test('새로고침 시 모든 일기를 다시 로드해야 한다', () async {
      // Arrange - 초기 5개
      final initialDiaries = List.generate(
        5,
        (i) => DiaryFixtures.analyzed(id: 'initial-$i'),
      );
      when(() => mockRepository.getAllDiaries())
          .thenAnswer((_) async => initialDiaries);

      await container.read(diaryListControllerProvider.future);

      // 데이터 추가 (7개로 증가)
      final updatedDiaries = List.generate(
        7,
        (i) => DiaryFixtures.analyzed(id: 'updated-$i'),
      );
      when(() => mockRepository.getAllDiaries())
          .thenAnswer((_) async => updatedDiaries);

      // Act - 새로고침
      await container.read(diaryListControllerProvider.notifier).refresh();
      final result = await container.read(diaryListControllerProvider.future);

      // Assert - 새로고침 후 모든 7개 반환
      expect(result.length, 7);
      expect(result[0].id, startsWith('updated-'));
    });
  });
}
