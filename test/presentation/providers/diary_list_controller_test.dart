import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../mocks/mock_repositories.dart';

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

  group('DiaryListController', () {
    group('build', () {
      test('초기 로드 시 getAllDiaries를 호출해야 한다', () async {
        // Arrange
        mockRepository.diaries = DiaryFixtures.weekOfDiaries();

        // Act
        final diaries = await container.read(diaryListControllerProvider.future);

        // Assert
        expect(diaries.length, 7);
      });

      test('빈 목록을 처리해야 한다', () async {
        // Arrange
        mockRepository.diaries = [];

        // Act
        final diaries = await container.read(diaryListControllerProvider.future);

        // Assert
        expect(diaries, isEmpty);
      });

      test('에러 발생 시 AsyncError 상태여야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGet = true;

        // Act
        final state = container.read(diaryListControllerProvider);

        // Assert (초기 상태는 Loading이고, future 접근 시 에러)
        await expectLater(
          container.read(diaryListControllerProvider.future),
          throwsA(anything),
        );
      });
    });

    group('refresh', () {
      test('목록을 새로고침해야 한다', () async {
        // Arrange
        mockRepository.diaries = [DiaryFixtures.analyzed(id: 'initial')];
        await container.read(diaryListControllerProvider.future);

        // 데이터 변경
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'initial'),
          DiaryFixtures.analyzed(id: 'new'),
        ];

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.refresh();
        final diaries = await container.read(diaryListControllerProvider.future);

        // Assert
        expect(diaries.length, 2);
      });

      test('새로고침 중 Loading 상태를 거쳐야 한다', () async {
        // Arrange
        mockRepository.diaries = DiaryFixtures.weekOfDiaries();
        await container.read(diaryListControllerProvider.future);

        final states = <AsyncValue<List<Diary>>>[];
        container.listen(
          diaryListControllerProvider,
          (previous, next) => states.add(next),
        );

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.refresh();

        // Assert - Loading 상태를 거쳤는지 확인
        expect(states.any((s) => s.isLoading), true);
      });
    });

    group('togglePin', () {
      test('낙관적 업데이트로 즉시 UI가 반영되어야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'test-diary', isPinned: false);
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        // 낙관적 업데이트는 동기적으로 상태를 변경
        final toggleFuture = controller.togglePin('test-diary', true);

        // Assert - 즉시 상태 확인
        final currentState = container.read(diaryListControllerProvider);
        expect(currentState.value?.first.isPinned, true);

        await toggleFuture;
      });

      test('성공 시 상태가 유지되어야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'test-diary', isPinned: false);
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('test-diary', true);

        // Assert
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries.first.isPinned, true);
      });

      test('실패 시 이전 상태로 롤백해야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'test-diary', isPinned: false);
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // 업데이트 실패 설정
        mockRepository.shouldThrowOnUpdate = true;

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('test-diary', true);

        // Assert - 롤백되어 원래 상태
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries.first.isPinned, false);
      });

      test('정렬 유지: 고정된 일기가 먼저 표시되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'old', createdAt: now.subtract(const Duration(days: 2)), isPinned: false),
          DiaryFixtures.analyzed(id: 'new', createdAt: now, isPinned: false),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 오래된 일기를 고정
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('old', true);

        // Assert - 고정된 일기가 최신 일기보다 먼저
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries[0].id, 'old');  // 고정된 일기 먼저
        expect(diaries[0].isPinned, true);
        expect(diaries[1].id, 'new');
      });

      test('고정 해제 시 날짜순으로 재정렬되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'old', createdAt: now.subtract(const Duration(days: 2)), isPinned: true),
          DiaryFixtures.analyzed(id: 'new', createdAt: now, isPinned: false),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 고정 해제
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('old', false);

        // Assert - 최신순 정렬
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries[0].id, 'new');  // 최신 일기 먼저
        expect(diaries[1].id, 'old');
      });

      test('여러 고정 일기는 날짜순으로 정렬되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'pinned-old', createdAt: now.subtract(const Duration(days: 3)), isPinned: true),
          DiaryFixtures.analyzed(id: 'pinned-new', createdAt: now.subtract(const Duration(days: 1)), isPinned: true),
          DiaryFixtures.analyzed(id: 'not-pinned', createdAt: now, isPinned: false),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 이미 데이터가 설정되어 있으므로 바로 확인
        final diaries = await container.read(diaryListControllerProvider.future);

        // Assert - 고정 일기들이 먼저, 그 안에서 최신순
        expect(diaries[0].id, 'pinned-new');  // 고정 중 최신
        expect(diaries[1].id, 'pinned-old');  // 고정 중 오래된
        expect(diaries[2].id, 'not-pinned');  // 미고정
      });

      test('state.value가 null이면 아무 동작도 하지 않아야 한다', () async {
        // Arrange - 빈 상태로 시작
        mockRepository.diaries = [];
        mockRepository.shouldThrowOnGet = true;

        // Act - error 상태에서 togglePin 시도
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('non-existent', true);

        // Assert - 에러 없이 종료
        // (togglePin 내부에서 value == null이면 early return)
      });

      test('존재하지 않는 일기 ID로 토글해도 안전해야 한다', () async {
        // Arrange
        mockRepository.diaries = [DiaryFixtures.analyzed(id: 'existing')];
        await container.read(diaryListControllerProvider.future);

        // Act - 존재하지 않는 ID
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('non-existent', true);

        // Assert - 에러 없이 동작, 기존 데이터 유지
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries.length, 1);
        expect(diaries.first.id, 'existing');
      });
    });

    group('통합 시나리오', () {
      test('새로고침 후 고정 토글이 올바르게 동작해야 한다', () async {
        // Arrange
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'diary-1'),
          DiaryFixtures.analyzed(id: 'diary-2'),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);

        // 새로고침
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'diary-1'),
          DiaryFixtures.analyzed(id: 'diary-2'),
          DiaryFixtures.analyzed(id: 'diary-3'),
        ];
        await controller.refresh();

        // 고정 토글
        await controller.togglePin('diary-3', true);

        // Assert
        final diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries.length, 3);
        expect(diaries.first.id, 'diary-3');  // 고정된 일기가 먼저
        expect(diaries.first.isPinned, true);
      });
    });
  });
}
