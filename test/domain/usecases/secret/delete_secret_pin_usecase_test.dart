import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/secret/delete_secret_pin_usecase.dart';

import '../../../helpers/mock_fallbacks.dart';
import '../../../mocks/mock_repositories.dart';

Diary _makeSecretDiary(String id) => Diary(
  id: id,
  content: '비밀 내용',
  createdAt: DateTime(2024),
  status: DiaryStatus.analyzed,
  isSecret: true,
);


void main() {
  late DeleteSecretPinUseCase useCase;
  late MockSecretPinRepository mockPinRepository;
  late MockDiaryRepository mockDiaryRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockPinRepository = MockSecretPinRepository();
    mockDiaryRepository = MockDiaryRepository();
    useCase = DeleteSecretPinUseCase(mockPinRepository, mockDiaryRepository);

    // Default stubs
    when(() => mockPinRepository.deletePin()).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.getSecretDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockDiaryRepository.setDiarySecret(any(), any()),
    ).thenAnswer((_) async {});
  });

  group('DeleteSecretPinUseCase', () {
    group('정상 케이스', () {
      test('should delete PIN when called', () async {
        // Act
        await useCase.execute();

        // Assert
        verify(() => mockPinRepository.deletePin()).called(1);
      });

      test('should unset all secret diaries when PIN is deleted', () async {
        // Arrange — 비밀일기 2개 (getSecretDiaries는 비밀일기만 반환)
        when(
          () => mockDiaryRepository.getSecretDiaries(),
        ).thenAnswer(
          (_) async => [
            _makeSecretDiary('d1'),
            _makeSecretDiary('d2'),
          ],
        );

        // Act
        await useCase.execute();

        // Assert
        verify(() => mockPinRepository.deletePin()).called(1);
        // 비밀일기 2개 각각 해제 호출됨
        verify(
          () => mockDiaryRepository.setDiarySecret('d1', false),
        ).called(1);
        verify(
          () => mockDiaryRepository.setDiarySecret('d2', false),
        ).called(1);
      });

      test('should work when there are no secret diaries', () async {
        // Arrange — getSecretDiaries returns empty (no secret diaries)
        when(
          () => mockDiaryRepository.getSecretDiaries(),
        ).thenAnswer((_) async => []);

        // Act
        await useCase.execute();

        // Assert
        verify(() => mockPinRepository.deletePin()).called(1);
        verifyNever(
          () => mockDiaryRepository.setDiarySecret(any(), any()),
        );
      });
    });

    group('오류 처리', () {
      test('should rethrow Failure from PIN repository', () async {
        // Arrange
        when(
          () => mockPinRepository.deletePin(),
        ).thenAnswer((_) async => throw const CacheFailure(message: '삭제 실패'));

        // Act & Assert
        await expectLater(useCase.execute(), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
