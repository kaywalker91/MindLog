import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/domain/usecases/clear_diary_draft_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late ClearDiaryDraftUseCase useCase;
  late MockDiaryDraftRepository mockRepository;
  late DiaryDraft? storedDraft;

  setUp(() {
    mockRepository = MockDiaryDraftRepository();
    storedDraft = null;
    useCase = ClearDiaryDraftUseCase(mockRepository);

    when(
      () => mockRepository.getDraft(),
    ).thenAnswer((_) async => storedDraft);
    when(() => mockRepository.clearDraft()).thenAnswer((_) async {
      storedDraft = null;
    });
    clearInteractions(mockRepository);
  });

  group('ClearDiaryDraftUseCase', () {
    group('정상 삭제', () {
      test('시드된 초안을 삭제한 뒤 getDraft는 null이어야 한다', () async {
        storedDraft = DiaryDraft(
          content: '삭제될 초안 본문입니다',
          entryDate: DateTime(2026, 8, 20),
          updatedAt: DateTime(2026, 8, 26, 10),
          imagePaths: const ['/tmp/seeded.jpg'],
        );
        expect(await mockRepository.getDraft(), isNotNull);

        await useCase.execute();

        verify(() => mockRepository.clearDraft()).called(1);
        expect(storedDraft, isNull);
        expect(await mockRepository.getDraft(), isNull);
      });

      test('초안이 없어도 clearDraft를 호출하고 성공해야 한다', () async {
        expect(storedDraft, isNull);

        await useCase.execute();

        verify(() => mockRepository.clearDraft()).called(1);
        expect(storedDraft, isNull);
      });
    });

    group('에러 처리', () {
      test('Repository Failure는 그대로 재던져야 한다', () async {
        when(() => mockRepository.clearDraft()).thenAnswer(
          (_) async => throw const CacheFailure(message: '초안 삭제 실패'),
        );
        clearInteractions(mockRepository);

        await expectLater(
          useCase.execute(),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('일반 Exception은 UnknownFailure로 감싸 던져야 한다', () async {
        when(
          () => mockRepository.clearDraft(),
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
