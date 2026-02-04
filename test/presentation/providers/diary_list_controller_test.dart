import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/providers/diary_list_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/statistics_providers.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../fixtures/statistics_fixtures.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    container = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(mockRepository)],
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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );

        // Assert
        expect(diaries.length, 7);
      });

      test('빈 목록을 처리해야 한다', () async {
        // Arrange
        mockRepository.diaries = [];

        // Act
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );

        // Assert
        expect(diaries, isEmpty);
      });

      test('에러 발생 시 AsyncError 상태여야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGet = true;

        // Act
        // final state = container.read(diaryListControllerProvider);

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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );

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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.first.isPinned, false);
      });

      test('정렬 유지: 고정된 일기가 먼저 표시되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(
            id: 'old',
            createdAt: now.subtract(const Duration(days: 2)),
            isPinned: false,
          ),
          DiaryFixtures.analyzed(id: 'new', createdAt: now, isPinned: false),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 오래된 일기를 고정
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('old', true);

        // Assert - 고정된 일기가 최신 일기보다 먼저
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries[0].id, 'old'); // 고정된 일기 먼저
        expect(diaries[0].isPinned, true);
        expect(diaries[1].id, 'new');
      });

      test('고정 해제 시 날짜순으로 재정렬되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(
            id: 'old',
            createdAt: now.subtract(const Duration(days: 2)),
            isPinned: true,
          ),
          DiaryFixtures.analyzed(id: 'new', createdAt: now, isPinned: false),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 고정 해제
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.togglePin('old', false);

        // Assert - 최신순 정렬
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries[0].id, 'new'); // 최신 일기 먼저
        expect(diaries[1].id, 'old');
      });

      test('여러 고정 일기는 날짜순으로 정렬되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(
            id: 'pinned-old',
            createdAt: now.subtract(const Duration(days: 3)),
            isPinned: true,
          ),
          DiaryFixtures.analyzed(
            id: 'pinned-new',
            createdAt: now.subtract(const Duration(days: 1)),
            isPinned: true,
          ),
          DiaryFixtures.analyzed(
            id: 'not-pinned',
            createdAt: now,
            isPinned: false,
          ),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 이미 데이터가 설정되어 있으므로 바로 확인
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );

        // Assert - 고정 일기들이 먼저, 그 안에서 최신순
        expect(diaries[0].id, 'pinned-new'); // 고정 중 최신
        expect(diaries[1].id, 'pinned-old'); // 고정 중 오래된
        expect(diaries[2].id, 'not-pinned'); // 미고정
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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'existing');
      });
    });

    group('deleteImmediately', () {
      test('일기가 목록에서 즉시 제거되어야 한다', () async {
        // Arrange
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'diary-1'),
          DiaryFixtures.analyzed(id: 'diary-2'),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('diary-1');

        // Assert
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'diary-2');
      });

      test('Repository.deleteDiary가 호출되어야 한다', () async {
        // Arrange
        mockRepository.diaries = [DiaryFixtures.analyzed(id: 'target-diary')];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('target-diary');

        // Assert
        expect(mockRepository.deletedDiaryIds, contains('target-diary'));
      });

      test('삭제 후 statisticsProvider가 무효화되어야 한다', () async {
        // Arrange
        var invalidateCount = 0;
        final statsContainer = ProviderContainer(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(mockRepository),
            statisticsProvider.overrideWith((ref) async {
              invalidateCount++;
              return StatisticsFixtures.empty();
            }),
          ],
        );
        addTearDown(statsContainer.dispose);

        mockRepository.diaries = [DiaryFixtures.analyzed(id: 'to-delete')];
        await statsContainer.read(diaryListControllerProvider.future);

        // 초기 로드로 인한 카운트 리셋
        invalidateCount = 0;

        // Act
        final controller = statsContainer.read(
          diaryListControllerProvider.notifier,
        );
        await controller.deleteImmediately('to-delete');

        // Assert - invalidate 호출 시 provider가 다시 실행됨
        // 여기서는 삭제 후 최소 1회 이상 갱신 확인
        await statsContainer.read(statisticsProvider.future);
        expect(invalidateCount, greaterThanOrEqualTo(1));
      });

      test('state.value가 null이면 아무 동작도 하지 않아야 한다', () async {
        // Arrange - 에러 상태로 만들기
        mockRepository.shouldThrowOnGet = true;

        // Act & Assert - 에러 없이 종료
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('any-id');

        // Repository 호출되지 않음
        expect(mockRepository.deletedDiaryIds, isEmpty);
      });

      test('존재하지 않는 ID 삭제 시에도 에러 없이 동작해야 한다', () async {
        // Arrange
        mockRepository.diaries = [DiaryFixtures.analyzed(id: 'existing')];
        await container.read(diaryListControllerProvider.future);

        // Act - 존재하지 않는 ID
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('non-existent');

        // Assert - 기존 데이터 유지
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'existing');
      });

      test('여러 일기 연속 삭제가 올바르게 동작해야 한다', () async {
        // Arrange
        mockRepository.diaries = [
          DiaryFixtures.analyzed(id: 'diary-1'),
          DiaryFixtures.analyzed(id: 'diary-2'),
          DiaryFixtures.analyzed(id: 'diary-3'),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 연속 삭제
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('diary-1');
        await controller.deleteImmediately('diary-3');

        // Assert
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'diary-2');
        expect(mockRepository.deletedDiaryIds, ['diary-1', 'diary-3']);
      });

      test('고정된 일기 삭제 후 정렬이 유지되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockRepository.diaries = [
          DiaryFixtures.analyzed(
            id: 'pinned',
            createdAt: now.subtract(const Duration(days: 1)),
            isPinned: true,
          ),
          DiaryFixtures.analyzed(id: 'new', createdAt: now, isPinned: false),
          DiaryFixtures.analyzed(
            id: 'old',
            createdAt: now.subtract(const Duration(days: 2)),
            isPinned: false,
          ),
        ];
        await container.read(diaryListControllerProvider.future);

        // Act - 고정된 일기 삭제
        final controller = container.read(diaryListControllerProvider.notifier);
        await controller.deleteImmediately('pinned');

        // Assert - 최신순 정렬 유지
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 2);
        expect(diaries[0].id, 'new');
        expect(diaries[1].id, 'old');
      });
    });

    group('softDelete', () {
      test('일기가 목록에서 즉시 제거되어야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'soft-delete-target');
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary);

        // Assert - 즉시 리스트에서 제거됨
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries, isEmpty);
      });

      test('state.value가 null이면 아무 동작도 하지 않아야 한다', () async {
        // Arrange - 에러 상태로 만들기
        mockRepository.diaries = [];
        mockRepository.shouldThrowOnGet = true;
        final diary = DiaryFixtures.analyzed(id: 'any');

        // Act - error 상태에서 softDelete 시도
        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary);

        // Assert - 에러 없이 종료
        // (softDelete 내부에서 value == null이면 early return)
      });

      test('여러 일기 소프트 삭제가 올바르게 동작해야 한다', () async {
        // Arrange
        final diary1 = DiaryFixtures.analyzed(id: 'diary-1');
        final diary2 = DiaryFixtures.analyzed(id: 'diary-2');
        final diary3 = DiaryFixtures.analyzed(id: 'diary-3');
        mockRepository.diaries = [diary1, diary2, diary3];
        await container.read(diaryListControllerProvider.future);

        // Act - 연속 소프트 삭제
        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary1);
        controller.softDelete(diary3);

        // Assert
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'diary-2');
      });
    });

    group('cancelDelete', () {
      test('삭제 취소 시 일기가 목록에 복원되어야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'to-restore');
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary);

        // 삭제 후 목록 비어있음 확인
        var diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries, isEmpty);

        // Act - 삭제 취소
        controller.cancelDelete('to-restore');

        // Assert - 복원됨
        diaries = await container.read(diaryListControllerProvider.future);
        expect(diaries.length, 1);
        expect(diaries.first.id, 'to-restore');
      });

      test('복원 시 정렬이 유지되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final oldDiary = DiaryFixtures.analyzed(
          id: 'old',
          createdAt: now.subtract(const Duration(days: 2)),
        );
        final newDiary = DiaryFixtures.analyzed(id: 'new', createdAt: now);
        mockRepository.diaries = [oldDiary, newDiary];
        await container.read(diaryListControllerProvider.future);

        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(oldDiary);

        // Act - 삭제 취소
        controller.cancelDelete('old');

        // Assert - 최신순 정렬 유지 (new가 먼저)
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 2);
        expect(diaries[0].id, 'new');
        expect(diaries[1].id, 'old');
      });

      test('고정된 일기 복원 시 고정 우선 정렬이 유지되어야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final pinnedOld = DiaryFixtures.analyzed(
          id: 'pinned-old',
          createdAt: now.subtract(const Duration(days: 2)),
          isPinned: true,
        );
        final notPinnedNew = DiaryFixtures.analyzed(
          id: 'not-pinned-new',
          createdAt: now,
          isPinned: false,
        );
        mockRepository.diaries = [pinnedOld, notPinnedNew];
        await container.read(diaryListControllerProvider.future);

        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(pinnedOld);

        // Act - 삭제 취소
        controller.cancelDelete('pinned-old');

        // Assert - 고정된 일기가 먼저
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 2);
        expect(diaries[0].id, 'pinned-old');
        expect(diaries[0].isPinned, true);
        expect(diaries[1].id, 'not-pinned-new');
      });

      test('존재하지 않는 삭제 취소 요청은 무시되어야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'existing');
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act - 존재하지 않는 ID로 취소 시도
        final controller = container.read(diaryListControllerProvider.notifier);
        controller.cancelDelete('non-existent');

        // Assert - 기존 상태 유지
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'existing');
      });

      test('이미 취소된 삭제를 다시 취소해도 에러가 발생하지 않아야 한다', () async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'double-cancel');
        mockRepository.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        final controller = container.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary);
        controller.cancelDelete('double-cancel');

        // Act - 두 번째 취소 시도
        controller.cancelDelete('double-cancel');

        // Assert - 에러 없이 동작, 일기는 하나만 존재
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 1);
        expect(diaries.first.id, 'double-cancel');
      });
    });

    group('softDelete 타이머 동작 (FakeAsync)', () {
      test('5초 후 실제 삭제가 실행되어야 한다', () {
        fakeAsync((async) {
          // Arrange
          final diary = DiaryFixtures.analyzed(id: 'timer-delete');
          mockRepository.diaries = [diary];

          // 동기적으로 초기화
          container.read(diaryListControllerProvider);
          async.flushMicrotasks();

          // Act
          final controller = container.read(
            diaryListControllerProvider.notifier,
          );
          controller.softDelete(diary);

          // 5초 전 - Repository 삭제 호출되지 않음
          async.elapse(const Duration(seconds: 4));
          expect(mockRepository.deletedDiaryIds, isEmpty);

          // 5초 후 - Repository 삭제 호출됨
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          expect(mockRepository.deletedDiaryIds, contains('timer-delete'));
        });
      });

      test('5초 내 취소 시 실제 삭제가 실행되지 않아야 한다', () {
        fakeAsync((async) {
          // Arrange
          final diary = DiaryFixtures.analyzed(id: 'cancel-before-timer');
          mockRepository.diaries = [diary];

          container.read(diaryListControllerProvider);
          async.flushMicrotasks();

          final controller = container.read(
            diaryListControllerProvider.notifier,
          );
          controller.softDelete(diary);

          // Act - 3초 후 취소
          async.elapse(const Duration(seconds: 3));
          controller.cancelDelete('cancel-before-timer');

          // 10초 경과해도 삭제되지 않음
          async.elapse(const Duration(seconds: 10));
          async.flushMicrotasks();

          // Assert
          expect(mockRepository.deletedDiaryIds, isEmpty);
        });
      });

      test('동일 일기 재삭제 시 기존 타이머가 취소되어야 한다', () {
        fakeAsync((async) {
          // Arrange
          final diary = DiaryFixtures.analyzed(id: 're-delete');
          mockRepository.diaries = [diary];

          container.read(diaryListControllerProvider);
          async.flushMicrotasks();

          final controller = container.read(
            diaryListControllerProvider.notifier,
          );

          // 첫 번째 softDelete
          controller.softDelete(diary);
          async.elapse(const Duration(seconds: 3));

          // Act - 두 번째 softDelete (타이머 리셋)
          controller.cancelDelete('re-delete'); // 복원
          controller.softDelete(diary); // 다시 삭제

          // 첫 번째 타이머 기준 5초 (총 8초) - 아직 삭제 안됨
          async.elapse(const Duration(seconds: 2));
          expect(mockRepository.deletedDiaryIds, isEmpty);

          // 두 번째 타이머 기준 5초 (추가 3초)
          async.elapse(const Duration(seconds: 3));
          async.flushMicrotasks();

          // Assert - 한 번만 삭제됨
          expect(mockRepository.deletedDiaryIds, ['re-delete']);
        });
      });

      test('삭제 실패 시 리스트가 복원되어야 한다', () {
        fakeAsync((async) {
          // Arrange
          final diary = DiaryFixtures.analyzed(id: 'fail-delete');
          mockRepository.diaries = [diary];
          mockRepository.shouldThrowOnDelete = true;

          container.read(diaryListControllerProvider);
          async.flushMicrotasks();

          final controller = container.read(
            diaryListControllerProvider.notifier,
          );
          controller.softDelete(diary);

          // 즉시 리스트에서 제거됨
          var state = container.read(diaryListControllerProvider);
          expect(state.value, isEmpty);

          // Act - 5초 후 삭제 시도 (실패)
          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();

          // Assert - 실패 후 복원됨
          state = container.read(diaryListControllerProvider);
          expect(state.value?.length, 1);
          expect(state.value?.first.id, 'fail-delete');
        });
      });

      test('삭제 후 statisticsProvider가 무효화되어야 한다', () {
        fakeAsync((async) {
          // Arrange
          var invalidateCount = 0;
          final statsContainer = ProviderContainer(
            overrides: [
              diaryRepositoryProvider.overrideWithValue(mockRepository),
              statisticsProvider.overrideWith((ref) async {
                invalidateCount++;
                return StatisticsFixtures.empty();
              }),
            ],
          );
          addTearDown(statsContainer.dispose);

          final diary = DiaryFixtures.analyzed(id: 'stats-invalidate');
          mockRepository.diaries = [diary];

          statsContainer.read(diaryListControllerProvider);
          async.flushMicrotasks();

          // 초기화 후 카운트 리셋
          invalidateCount = 0;

          // Act
          final controller = statsContainer.read(
            diaryListControllerProvider.notifier,
          );
          controller.softDelete(diary);

          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();

          // statistics provider 읽기 시도
          statsContainer.read(statisticsProvider);
          async.flushMicrotasks();

          // Assert
          expect(invalidateCount, greaterThanOrEqualTo(1));
        });
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
        final diaries = await container.read(
          diaryListControllerProvider.future,
        );
        expect(diaries.length, 3);
        expect(diaries.first.id, 'diary-3'); // 고정된 일기가 먼저
        expect(diaries.first.isPinned, true);
      });
    });
  });
}
