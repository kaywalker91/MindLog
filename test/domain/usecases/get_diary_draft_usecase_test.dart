import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/utils/clock.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/domain/usecases/get_diary_draft_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late GetDiaryDraftUseCase useCase;
  late MockDiaryDraftRepository mockRepository;

  final updatedAt = DateTime(2026, 8, 20, 12);
  const seededContent = 'TTL경계검증초안내용';

  DiaryDraft seededDraft({
    DateTime? at,
    List<String>? imagePaths,
  }) {
    return DiaryDraft(
      content: seededContent,
      entryDate: DateTime(2026, 8, 20),
      updatedAt: at ?? updatedAt,
      imagePaths: imagePaths,
    );
  }

  void stubDraft(DiaryDraft? draft) {
    when(() => mockRepository.getDraft()).thenAnswer((_) async => draft);
    clearInteractions(mockRepository);
  }

  setUp(() {
    mockRepository = MockDiaryDraftRepository();
    useCase = GetDiaryDraftUseCase(
      mockRepository,
      clock: FixedClock(updatedAt),
    );

    when(() => mockRepository.getDraft()).thenAnswer((_) async => null);
    when(() => mockRepository.clearDraft()).thenAnswer((_) async {});
    clearInteractions(mockRepository);
  });

  group('GetDiaryDraftUseCase', () {
    group('조회', () {
      test('저장된 초안이 없으면 null을 반환하고 clearDraft를 호출하지 않아야 한다', () async {
        stubDraft(null);

        final result = await useCase.execute();

        expect(result, isNull);
        verify(() => mockRepository.getDraft()).called(1);
        verifyNever(() => mockRepository.clearDraft());
      });

      test('만료되지 않은 초안은 이미지 경로를 포함해 그대로 반환해야 한다', () async {
        const imagePaths = ['/tmp/keep.jpg'];
        final draft = seededDraft(imagePaths: imagePaths);
        stubDraft(draft);

        final result = await useCase.execute();

        expect(result, isNotNull);
        expect(result!.content, seededContent);
        expect(result.imagePaths, imagePaths);
        expect(result.updatedAt, updatedAt);
        verifyNever(() => mockRepository.clearDraft());
      });
    });

    group('TTL 경계', () {
      test('6일 23시간 경과 초안은 반환되고 clearDraft를 호출하지 않아야 한다', () async {
        final draft = seededDraft();
        final justBeforeExpiry = updatedAt.add(
          const Duration(days: 6, hours: 23),
        );
        expect(
          justBeforeExpiry.difference(updatedAt) < AppConstants.diaryDraftTtl,
          isTrue,
        );
        expect(draft.isExpired(justBeforeExpiry, AppConstants.diaryDraftTtl), isFalse);

        stubDraft(draft);
        useCase = GetDiaryDraftUseCase(
          mockRepository,
          clock: FixedClock(justBeforeExpiry),
        );

        final result = await useCase.execute();

        expect(result, isNotNull);
        expect(result!.content, seededContent);
        expect(result.updatedAt, updatedAt);
        verify(() => mockRepository.getDraft()).called(1);
        verifyNever(() => mockRepository.clearDraft());
      });

      test('7일 정각 경과 초안은 null을 반환하고 clearDraft를 호출해야 한다', () async {
        final draft = seededDraft();
        final atExpiry = updatedAt.add(AppConstants.diaryDraftTtl);
        expect(atExpiry.difference(updatedAt), AppConstants.diaryDraftTtl);
        expect(draft.isExpired(atExpiry, AppConstants.diaryDraftTtl), isTrue);

        stubDraft(draft);
        useCase = GetDiaryDraftUseCase(
          mockRepository,
          clock: FixedClock(atExpiry),
        );

        final result = await useCase.execute();

        expect(result, isNull);
        verify(() => mockRepository.getDraft()).called(1);
        verify(() => mockRepository.clearDraft()).called(1);
      });
    });

    group('에러 처리', () {
      test('Repository Failure는 그대로 재던져야 한다', () async {
        when(() => mockRepository.getDraft()).thenAnswer(
          (_) async => throw const CacheFailure(message: '초안 조회 실패'),
        );
        clearInteractions(mockRepository);

        await expectLater(
          useCase.execute(),
          throwsA(isA<CacheFailure>()),
        );
        verifyNever(() => mockRepository.clearDraft());
      });

      test('일반 Exception은 UnknownFailure로 감싸 던져야 한다', () async {
        when(
          () => mockRepository.getDraft(),
        ).thenAnswer((_) async => throw Exception('unexpected'));
        clearInteractions(mockRepository);

        await expectLater(
          useCase.execute(),
          throwsA(isA<UnknownFailure>()),
        );
      });
    });
  });
}
