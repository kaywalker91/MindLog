import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/utils/clock.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/domain/usecases/save_diary_draft_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late SaveDiaryDraftUseCase useCase;
  late MockDiaryDraftRepository mockRepository;
  late DiaryDraft? storedDraft;

  final now = DateTime(2026, 8, 27, 15, 30);
  final entryDate = DateTime(2026, 8, 20);

  DiaryDraft seededDraft() {
    return DiaryDraft(
      content: '이미 저장된 초안 본문입니다',
      entryDate: entryDate,
      updatedAt: DateTime(2026, 8, 26, 10),
      imagePaths: const ['/tmp/seeded.jpg'],
    );
  }

  DiaryDraft capturedSavedDraft() {
    return verify(
      () => mockRepository.saveDraft(captureAny()),
    ).captured.single as DiaryDraft;
  }

  setUpAll(() {
    registerFallbackValue(
      DiaryDraft(
        content: 'fallback',
        entryDate: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockDiaryDraftRepository();
    storedDraft = null;
    useCase = SaveDiaryDraftUseCase(
      mockRepository,
      clock: FixedClock(now),
    );

    when(() => mockRepository.saveDraft(any())).thenAnswer((inv) async {
      storedDraft = inv.positionalArguments.first as DiaryDraft;
    });
    when(
      () => mockRepository.getDraft(),
    ).thenAnswer((_) async => storedDraft);
    when(() => mockRepository.clearDraft()).thenAnswer((_) async {
      storedDraft = null;
    });
    // when() 클로저가 호출 카운트를 선증가시키므로 스텁 후 리셋
    clearInteractions(mockRepository);
  });

  group('SaveDiaryDraftUseCase', () {
    group('정상 저장', () {
      test('9자 저장 후 getDraft 결과가 동일한 content여야 한다', () async {
        const content = '123456789';
        expect(content.length, 9);
        expect(content.length, lessThan(AppConstants.diaryMinLength));
        expect(storedDraft, isNull);

        await useCase.execute(content, entryDate: entryDate);

        final loaded = await mockRepository.getDraft();
        expect(loaded, isNotNull);
        expect(loaded!.content, content);
        expect(loaded.content.length, 9);
        verify(() => mockRepository.saveDraft(any())).called(1);
        verifyNever(() => mockRepository.clearDraft());
      });

      test('1자 초안도 최소 길이 제한 없이 저장되어야 한다', () async {
        await useCase.execute('한', entryDate: entryDate);

        final loaded = await mockRepository.getDraft();
        expect(loaded, isNotNull);
        expect(loaded!.content, '한');
        verifyNever(() => mockRepository.clearDraft());
      });

      test('5000자 초안은 저장되어야 한다', () async {
        final content = 'a' * AppConstants.diaryMaxLength;

        await useCase.execute(content, entryDate: entryDate);

        final loaded = await mockRepository.getDraft();
        expect(loaded, isNotNull);
        expect(loaded!.content.length, AppConstants.diaryMaxLength);
        expect(loaded.content, content);
        verifyNever(() => mockRepository.clearDraft());
      });

      test('저장 시 content가 trim되어 들어가야 한다', () async {
        const raw = '  123456789  ';

        await useCase.execute(raw, entryDate: entryDate);

        final saved = capturedSavedDraft();
        expect(saved.content, '123456789');
        expect(saved.content.startsWith(' '), isFalse);
        expect(saved.content.endsWith(' '), isFalse);
      });

      test('content 공백 + 이미지가 있으면 저장되고 clear되면 안 된다', () async {
        const imagePaths = ['/tmp/only-image.jpg'];

        await useCase.execute(
          '   \n\t  ',
          entryDate: entryDate,
          imagePaths: imagePaths,
        );

        final saved = capturedSavedDraft();
        expect(saved.content, isEmpty);
        expect(saved.imagePaths, imagePaths);
        verifyNever(() => mockRepository.clearDraft());
      });

      test('imagePaths가 빈 리스트이면 null로 정규화되어 저장되어야 한다', () async {
        await useCase.execute(
          '123456789',
          entryDate: entryDate,
          imagePaths: const [],
        );

        final saved = capturedSavedDraft();
        expect(saved.imagePaths, isNull);
      });

      test('updatedAt은 clock.now 이고 entryDate는 인자 값이어야 한다', () async {
        await useCase.execute('123456789', entryDate: entryDate);

        final saved = capturedSavedDraft();
        expect(saved.updatedAt, now);
        expect(saved.entryDate, entryDate);
      });
    });

    group('공백 입력 시 삭제', () {
      test('초안을 시드한 뒤 공백 입력 저장 시 clearDraft가 호출되어야 한다', () async {
        storedDraft = seededDraft();
        expect(storedDraft, isNotNull);

        await useCase.execute('   ', entryDate: entryDate);

        verify(() => mockRepository.clearDraft()).called(1);
        verifyNever(() => mockRepository.saveDraft(any()));
        expect(storedDraft, isNull);
      });

      test('시드된 초안에서 빈 내용 + 빈 이미지 리스트는 clearDraft를 호출해야 한다', () async {
        storedDraft = seededDraft();

        await useCase.execute(
          '',
          entryDate: entryDate,
          imagePaths: const [],
        );

        verify(() => mockRepository.clearDraft()).called(1);
        verifyNever(() => mockRepository.saveDraft(any()));
        expect(storedDraft, isNull);
      });
    });

    group('입력 유효성 검사', () {
      test('5001자는 ValidationFailure를 던지고 저장하지 않아야 한다', () async {
        final content = 'a' * (AppConstants.diaryMaxLength + 1);
        expect(content.length, AppConstants.diaryMaxLength + 1);

        await expectLater(
          useCase.execute(content, entryDate: entryDate),
          throwsA(isA<ValidationFailure>()),
        );

        expect(storedDraft, isNull);
        verifyNever(() => mockRepository.saveDraft(any()));
        verifyNever(() => mockRepository.clearDraft());
      });
    });

    group('에러 처리', () {
      test('Repository Failure는 그대로 재던져야 한다', () async {
        when(() => mockRepository.saveDraft(any())).thenAnswer(
          (_) async => throw const CacheFailure(message: '초안 저장 실패'),
        );
        clearInteractions(mockRepository);

        await expectLater(
          useCase.execute('123456789', entryDate: entryDate),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('일반 Exception은 UnknownFailure로 감싸 던져야 한다', () async {
        when(
          () => mockRepository.saveDraft(any()),
        ).thenAnswer((_) async => throw Exception('unexpected'));
        clearInteractions(mockRepository);

        await expectLater(
          useCase.execute('123456789', entryDate: entryDate),
          throwsA(isA<UnknownFailure>()),
        );
      });
    });
  });
}
