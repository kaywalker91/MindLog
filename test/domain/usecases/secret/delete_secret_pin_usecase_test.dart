import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/secret/delete_secret_pin_usecase.dart';

import '../../../mocks/mock_repositories.dart';

Diary _makeSecretDiary(String id) => Diary(
  id: id,
  content: '비밀 내용',
  createdAt: DateTime(2024),
  status: DiaryStatus.analyzed,
  isSecret: true,
);

Diary _makeNormalDiary(String id) => Diary(
  id: id,
  content: '일반 내용',
  createdAt: DateTime(2024),
  status: DiaryStatus.analyzed,
);

void main() {
  late DeleteSecretPinUseCase useCase;
  late MockSecretPinRepository mockPinRepository;
  late MockDiaryRepository mockDiaryRepository;

  setUp(() {
    mockPinRepository = MockSecretPinRepository();
    mockDiaryRepository = MockDiaryRepository();
    useCase = DeleteSecretPinUseCase(mockPinRepository, mockDiaryRepository);
  });

  group('DeleteSecretPinUseCase', () {
    group('정상 케이스', () {
      test('should delete PIN when called', () async {
        // Act
        await useCase.execute();

        // Assert
        expect(mockPinRepository.deletePinCalled, true);
      });

      test('should unset all secret diaries when PIN is deleted', () async {
        // Arrange — 비밀일기 2개 + 일반 1개
        mockDiaryRepository.diaries = [
          _makeSecretDiary('d1'),
          _makeSecretDiary('d2'),
          _makeNormalDiary('d3'),
        ];

        // Act
        await useCase.execute();

        // Assert
        expect(mockPinRepository.deletePinCalled, true);
        // 비밀일기 2개만 해제 호출됨
        expect(mockDiaryRepository.setSecretCalls.length, 2);
        expect(mockDiaryRepository.setSecretValues['d1'], false);
        expect(mockDiaryRepository.setSecretValues['d2'], false);
        // 일반 일기는 호출 안 됨
        expect(mockDiaryRepository.setSecretValues.containsKey('d3'), false);
      });

      test('should work when there are no secret diaries', () async {
        // Arrange
        mockDiaryRepository.diaries = [_makeNormalDiary('d1')];

        // Act
        await useCase.execute();

        // Assert
        expect(mockPinRepository.deletePinCalled, true);
        expect(mockDiaryRepository.setSecretCalls, isEmpty);
      });
    });

    group('오류 처리', () {
      test('should rethrow Failure from PIN repository', () async {
        // Arrange
        mockPinRepository.shouldThrow = true;
        mockPinRepository.failureToThrow = const CacheFailure(message: '삭제 실패');

        // Act & Assert
        expect(() => useCase.execute(), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
