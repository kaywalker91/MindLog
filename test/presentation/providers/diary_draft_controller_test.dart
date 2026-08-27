import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/domain/usecases/clear_diary_draft_usecase.dart';
import 'package:mindlog/domain/usecases/get_diary_draft_usecase.dart';
import 'package:mindlog/domain/usecases/save_diary_draft_usecase.dart';
import 'package:mindlog/presentation/providers/providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockSaveDiaryDraftUseCase extends Mock
    implements SaveDiaryDraftUseCase {}

class _MockGetDiaryDraftUseCase extends Mock implements GetDiaryDraftUseCase {}

class _MockClearDiaryDraftUseCase extends Mock
    implements ClearDiaryDraftUseCase {}

void main() {
  late ProviderContainer container;
  var containerOpened = false;
  late _MockSaveDiaryDraftUseCase mockSave;
  late _MockGetDiaryDraftUseCase mockGet;
  late _MockClearDiaryDraftUseCase mockClear;

  final entryDate = DateTime(2026, 8, 27);

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    mockSave = _MockSaveDiaryDraftUseCase();
    mockGet = _MockGetDiaryDraftUseCase();
    mockClear = _MockClearDiaryDraftUseCase();

    when(() => mockGet.execute()).thenAnswer((_) async => null);
    when(
      () => mockSave.execute(
        any(),
        entryDate: any(named: 'entryDate'),
        imagePaths: any(named: 'imagePaths'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockClear.execute()).thenAnswer((_) async {});

  });

  /// ProviderContainer 는 반드시 fakeAsync 존 **안에서** 만들어야 한다.
  /// 밖에서 만들면 컨트롤러의 내부 Future 체인이 실제 마이크로태스크 큐에 묶여
  /// async.flushMicrotasks() 로 진행되지 않는다 (저장이 영영 관찰되지 않음).
  void openContainer() {
    container = ProviderContainer(
      overrides: [
        saveDiaryDraftUseCaseProvider.overrideWithValue(mockSave),
        getDiaryDraftUseCaseProvider.overrideWithValue(mockGet),
        clearDiaryDraftUseCaseProvider.overrideWithValue(mockClear),
      ],
    );
    container.listen(
      diaryDraftControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    containerOpened = true;
  }

  tearDown(() {
    if (containerOpened) {
      container.dispose();
      containerOpened = false;
    }
  });

  DiaryDraftController controller() =>
      container.read(diaryDraftControllerProvider.notifier);

  void restoreAbsent(FakeAsync async) {
    unawaited(controller().restore());
    async.flushMicrotasks();
    expect(
      container.read(diaryDraftControllerProvider),
      isA<DiaryDraftAbsent>(),
    );
  }

  group('DiaryDraftController', () {
    test('a. restore 완료 전 onChanged는 저장하지 않는다', () {
      fakeAsync((async) {
        openContainer();
        final restoreCompleter = Completer<DiaryDraft?>();
        when(
          () => mockGet.execute(),
        ).thenAnswer((_) => restoreCompleter.future);

        unawaited(controller().restore());
        controller().onChanged(content: '복원 전에 입력된 값', entryDate: entryDate);
        unawaited(
          controller().flush(content: '복원 전 flush 값', entryDate: entryDate),
        );
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => mockSave.execute(
            '복원 전에 입력된 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );
        verifyNever(
          () => mockSave.execute(
            '복원 전 flush 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );

        restoreCompleter.complete(null);
        async.flushMicrotasks();
        controller().onChanged(content: '복원 후 입력된 값', entryDate: entryDate);
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verify(
          () => mockSave.execute(
            '복원 후 입력된 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);
      });
    });

    test('b. restore 후 799ms에는 미저장, 800ms에 저장한다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);

        controller().onChanged(content: '디바운스 경계 값', entryDate: entryDate);
        async.elapse(const Duration(milliseconds: 799));
        async.flushMicrotasks();

        verifyNever(
          () => mockSave.execute(
            '디바운스 경계 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

        verify(
          () => mockSave.execute(
            '디바운스 경계 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);
      });
    });

    test('c. onChanged 연속 3회는 마지막 값만 한 번 저장한다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);

        controller().onChanged(content: '첫 값', entryDate: entryDate);
        controller().onChanged(content: '둘째 값', entryDate: entryDate);
        controller().onChanged(
          content: '마지막 값',
          entryDate: entryDate,
          imagePaths: ['draft.jpg'],
        );
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => mockSave.execute('첫 값', entryDate: entryDate, imagePaths: null),
        );
        verifyNever(
          () =>
              mockSave.execute('둘째 값', entryDate: entryDate, imagePaths: null),
        );
        final capturedImagePaths = verify(
          () => mockSave.execute(
            '마지막 값',
            entryDate: entryDate,
            imagePaths: captureAny(named: 'imagePaths'),
          ),
        ).captured.single;
        expect(capturedImagePaths, ['draft.jpg']);
      });
    });

    test('d. onChanged 직후 flush는 타이머를 취소하고 flush 값만 저장한다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);

        controller().onChanged(content: '취소되어야 할 값', entryDate: entryDate);
        unawaited(
          controller().flush(
            content: '즉시 저장할 값',
            entryDate: entryDate,
            imagePaths: ['latest.jpg'],
          ),
        );
        async.flushMicrotasks();

        final capturedImagePaths = verify(
          () => mockSave.execute(
            '즉시 저장할 값',
            entryDate: entryDate,
            imagePaths: captureAny(named: 'imagePaths'),
          ),
        ).captured.single;
        expect(capturedImagePaths, ['latest.jpg']);

        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => mockSave.execute(
            '취소되어야 할 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );
        verifyNoMoreInteractions(mockSave);
      });
    });

    test('e. discard 후 대기 중 디바운스가 만료돼도 저장하지 않는다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);

        controller().onChanged(content: '먼저 저장되는 값', entryDate: entryDate);
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();
        verify(
          () => mockSave.execute(
            '먼저 저장되는 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);

        controller().onChanged(content: '폐기로 취소될 값', entryDate: entryDate);
        unawaited(controller().discard());
        async.flushMicrotasks();
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verify(() => mockClear.execute()).called(1);
        verifyNever(
          () => mockSave.execute(
            '폐기로 취소될 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );
      });
    });

    test('f. restore가 초안을 반환하면 Restored 상태에 같은 초안을 담는다', () {
      fakeAsync((async) {
        openContainer();
        final draft = DiaryDraft(
          content: '복원할 초안',
          entryDate: entryDate,
          updatedAt: DateTime(2026, 8, 27, 12),
          imagePaths: const ['restored.jpg'],
        );
        when(() => mockGet.execute()).thenAnswer((_) async => draft);

        unawaited(controller().restore());
        async.flushMicrotasks();

        final state = container.read(diaryDraftControllerProvider);
        expect(state, isA<DiaryDraftRestored>());
        expect((state as DiaryDraftRestored).draft, same(draft));
      });
    });

    test('g. restore가 null을 반환하면 Absent 상태가 된다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);
      });
    });

    test('h. dismissBanner는 clear 없이 Absent 상태로만 바꾼다', () {
      fakeAsync((async) {
        openContainer();
        final draft = DiaryDraft(
          content: '배너를 닫을 초안',
          entryDate: entryDate,
          updatedAt: DateTime(2026, 8, 27, 12),
        );
        when(() => mockGet.execute()).thenAnswer((_) async => draft);
        unawaited(controller().restore());
        async.flushMicrotasks();
        expect(
          container.read(diaryDraftControllerProvider),
          isA<DiaryDraftRestored>(),
        );

        controller().dismissBanner();

        expect(
          container.read(diaryDraftControllerProvider),
          isA<DiaryDraftAbsent>(),
        );
        verifyNever(() => mockClear.execute());
      });
    });

    test('i. save UseCase의 Failure가 flush 밖으로 새지 않는다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);
        when(
          () => mockSave.execute(
            '저장 실패 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).thenAnswer(
          (_) async => throw const ValidationFailure(message: '초안 저장 실패'),
        );
        var completedNormally = false;

        unawaited(
          controller().flush(content: '저장 실패 값', entryDate: entryDate).then((
            _,
          ) {
            completedNormally = true;
          }),
        );
        async.flushMicrotasks();

        expect(completedNormally, isTrue);
        verify(
          () => mockSave.execute(
            '저장 실패 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);
      });
    });

    test('저장은 단일 슬롯에서 직렬화되고 최신 요청 순서로 완료된다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);
        final firstSave = Completer<void>();
        when(
          () => mockSave.execute(
            '먼저 시작한 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).thenAnswer((_) => firstSave.future);

        unawaited(
          controller().flush(content: '먼저 시작한 값', entryDate: entryDate),
        );
        async.flushMicrotasks();
        verify(
          () => mockSave.execute(
            '먼저 시작한 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);

        unawaited(controller().flush(content: '최신 값', entryDate: entryDate));
        async.flushMicrotasks();
        verifyNever(
          () =>
              mockSave.execute('최신 값', entryDate: entryDate, imagePaths: null),
        );

        firstSave.complete();
        async.flushMicrotasks();
        verify(
          () =>
              mockSave.execute('최신 값', entryDate: entryDate, imagePaths: null),
        ).called(1);
      });
    });

    test('discard는 진행 중 저장 완료 뒤 clear하여 초안 부활을 막는다', () {
      fakeAsync((async) {
        openContainer();
        restoreAbsent(async);
        final inFlightSave = Completer<void>();
        when(
          () => mockSave.execute(
            '진행 중 저장',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).thenAnswer((_) => inFlightSave.future);

        unawaited(controller().flush(content: '진행 중 저장', entryDate: entryDate));
        async.flushMicrotasks();
        verify(
          () => mockSave.execute(
            '진행 중 저장',
            entryDate: entryDate,
            imagePaths: null,
          ),
        ).called(1);

        unawaited(controller().discard());
        async.flushMicrotasks();
        verifyNever(() => mockClear.execute());

        inFlightSave.complete();
        async.flushMicrotasks();

        verify(() => mockClear.execute()).called(1);
        expect(
          container.read(diaryDraftControllerProvider),
          isA<DiaryDraftAbsent>(),
        );
      });
    });

    test('discard Failure는 밖으로 새지 않고 기존 상태를 유지한다', () {
      fakeAsync((async) {
        openContainer();
        final draft = DiaryDraft(
          content: '유지할 초안',
          entryDate: entryDate,
          updatedAt: DateTime(2026, 8, 27, 12),
        );
        when(() => mockGet.execute()).thenAnswer((_) async => draft);
        when(
          () => mockClear.execute(),
        ).thenAnswer((_) async => throw const CacheFailure(message: '폐기 실패'));
        unawaited(controller().restore());
        async.flushMicrotasks();
        var completedNormally = false;

        unawaited(
          controller().discard().then((_) {
            completedNormally = true;
          }),
        );
        async.flushMicrotasks();

        expect(completedNormally, isTrue);
        final state = container.read(diaryDraftControllerProvider);
        expect(state, isA<DiaryDraftRestored>());
        expect((state as DiaryDraftRestored).draft, same(draft));
      });
    });

    test('dispose는 대기 타이머를 취소하고 저장하지 않는다', () {
      fakeAsync((async) {
        openContainer();
        final localContainer = ProviderContainer(
          overrides: [
            saveDiaryDraftUseCaseProvider.overrideWithValue(mockSave),
            getDiaryDraftUseCaseProvider.overrideWithValue(mockGet),
            clearDiaryDraftUseCaseProvider.overrideWithValue(mockClear),
          ],
        );
        localContainer.listen(
          diaryDraftControllerProvider,
          (_, _) {},
          fireImmediately: true,
        );
        final localController = localContainer.read(
          diaryDraftControllerProvider.notifier,
        );
        unawaited(localController.restore());
        async.flushMicrotasks();
        localController.onChanged(
          content: 'dispose로 취소될 값',
          entryDate: entryDate,
        );

        localContainer.dispose();
        async.elapse(AppConstants.diaryDraftDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => mockSave.execute(
            'dispose로 취소될 값',
            entryDate: entryDate,
            imagePaths: null,
          ),
        );
      });
    });
  });
}
