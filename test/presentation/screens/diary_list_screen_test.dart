import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../mocks/mock_repositories.dart';

/// DiaryListScreen 스크롤 테스트 (데이터 레이어 검증)
///
/// 이 테스트는 일기 목록이 5개로 제한되는지 여부를 확인합니다.
/// FlutterFire 의존성 때문에 Widget 테스트 대신 Provider 테스트로 구현합니다.
void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    mockRepository.reset();
    container.dispose();
  });

  group('일기 목록 개수 제한 테스트 (5개 제한 버그 확인)', () {
    test('7개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 일주일치 일기 (7개)
      mockRepository.diaries = DiaryFixtures.weekOfDiaries();
      expect(mockRepository.diaries.length, 7);

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 5개 제한 없이 모든 7개 반환
      expect(diaries.length, 7, reason: '일기 목록이 5개로 제한되면 안 됩니다');
    });

    test('10개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 10개 일기 생성
      mockRepository.diaries = List.generate(10, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          content: '일기 $index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 10개 반환
      expect(diaries.length, 10, reason: '5개 제한 버그가 없어야 합니다');
    });

    test('20개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 20개 일기 생성
      mockRepository.diaries = List.generate(20, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          content: '일기 $index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 20개 반환
      expect(diaries.length, 20);
    });

    test('30개 일기가 있을 때 모두 반환해야 한다 (한 달치)', () async {
      // Arrange - 한 달치 일기 (30개)
      mockRepository.diaries = DiaryFixtures.monthOfDiaries();
      expect(mockRepository.diaries.length, 30);

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 모든 30개 반환
      expect(diaries.length, 30);
    });

    test('빈 목록도 올바르게 처리해야 한다', () async {
      // Arrange
      mockRepository.diaries = [];

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert
      expect(diaries, isEmpty);
    });

    test('정확히 5개 일기가 있을 때 모두 반환해야 한다', () async {
      // Arrange - 정확히 5개
      mockRepository.diaries = List.generate(5, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert
      expect(diaries.length, 5);
    });

    test('정확히 6개 일기가 있을 때 모두 반환해야 한다 (5개 경계 테스트)', () async {
      // Arrange - 5개 경계 바로 다음 (6개)
      mockRepository.diaries = List.generate(6, (index) {
        return DiaryFixtures.analyzed(
          id: 'diary-$index',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        );
      });

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 5개 제한이 있다면 이 테스트 실패
      expect(diaries.length, 6, reason: '5개 제한이 있으면 안 됩니다');
    });
  });

  group('일기 목록 정렬 테스트', () {
    test('최신 일기가 먼저 표시되어야 한다', () async {
      // Arrange
      final now = DateTime.now();
      mockRepository.diaries = [
        DiaryFixtures.analyzed(id: 'old', createdAt: now.subtract(const Duration(days: 2))),
        DiaryFixtures.analyzed(id: 'newest', createdAt: now),
        DiaryFixtures.analyzed(id: 'middle', createdAt: now.subtract(const Duration(days: 1))),
      ];

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 최신순 정렬
      expect(diaries[0].id, 'newest');
      expect(diaries[1].id, 'middle');
      expect(diaries[2].id, 'old');
    });

    test('고정된 일기가 먼저 표시되어야 한다', () async {
      // Arrange
      final now = DateTime.now();
      mockRepository.diaries = [
        DiaryFixtures.analyzed(id: 'newest', createdAt: now, isPinned: false),
        DiaryFixtures.analyzed(id: 'old-pinned', createdAt: now.subtract(const Duration(days: 5)), isPinned: true),
      ];

      // Act
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 고정된 일기 먼저
      expect(diaries[0].id, 'old-pinned');
      expect(diaries[0].isPinned, true);
      expect(diaries[1].id, 'newest');
    });
  });

  group('일기 목록 새로고침 테스트', () {
    test('새로고침 시 모든 일기를 다시 로드해야 한다', () async {
      // Arrange - 초기 5개
      mockRepository.diaries = List.generate(5, (i) => 
        DiaryFixtures.analyzed(id: 'initial-$i'));
      
      await container.read(diaryListControllerProvider.future);

      // 데이터 추가 (7개로 증가)
      mockRepository.diaries = List.generate(7, (i) => 
        DiaryFixtures.analyzed(id: 'updated-$i'));

      // Act - 새로고침
      await container.read(diaryListControllerProvider.notifier).refresh();
      final diaries = await container.read(diaryListControllerProvider.future);

      // Assert - 새로고침 후 모든 7개 반환
      expect(diaries.length, 7);
      expect(diaries[0].id, startsWith('updated-'));
    });
  });
}
