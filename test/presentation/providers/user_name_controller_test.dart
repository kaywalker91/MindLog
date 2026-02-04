import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/user_name_controller.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late ProviderContainer container;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();

    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('UserNameController', () {
    group('build', () {
      test('초기 로드 시 Repository에서 이름을 조회해야 한다', () async {
        // Arrange
        mockRepository.setMockUserName('홍길동');

        // Act
        final userName = await container.read(userNameProvider.future);

        // Assert
        expect(userName, '홍길동');
      });

      test('이름이 설정되지 않았으면 null을 반환해야 한다', () async {
        // Act
        final userName = await container.read(userNameProvider.future);

        // Assert
        expect(userName, isNull);
      });

      test('Repository 에러 시 AsyncError 상태여야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGet = true;
        mockRepository.failureToThrow = const Failure.cache(
          message: '이름 조회 실패',
        );

        // Act
        await container.read(userNameProvider.future).catchError((_) => null);

        // Assert
        final state = container.read(userNameProvider);
        expect(state, isA<AsyncError<String?>>());
      });
    });

    group('setUserName', () {
      test('이름 설정 시 Repository에 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('김철수');

        // Assert - Repository에서 저장 확인
        final savedName = await mockRepository.getUserName();
        expect(savedName, '김철수');
      });

      test('설정 후 상태가 업데이트되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('이영희');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '이영희');
      });

      test('null 전달 시 이름이 삭제되어야 한다', () async {
        // Arrange
        mockRepository.setMockUserName('기존이름');
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName(null);

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('빈 문자열은 null로 변환되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('공백만 있는 문자열은 null로 변환되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('   ');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('앞뒤 공백이 제거되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('  홍길동  ');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '홍길동');
      });

      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);
        mockRepository.shouldThrowOnSet = true;
        mockRepository.failureToThrow = const Failure.cache(message: '저장 실패');

        // Act & Assert
        await expectLater(
          notifier.setUserName('테스트'),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('연속 이름 변경이 올바르게 동작해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('이름1');
        await notifier.setUserName('이름2');
        await notifier.setUserName('이름3');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '이름3');
      });

      test('이름 설정 후 다시 null로 변경할 수 있어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동');
        expect(container.read(userNameProvider).value, '홍길동');

        await notifier.setUserName(null);

        // Assert
        expect(container.read(userNameProvider).value, isNull);
      });
    });

    group('특수 문자 처리', () {
      test('한글 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동');

        // Assert
        expect(container.read(userNameProvider).value, '홍길동');
      });

      test('영문 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('John Doe');

        // Assert
        expect(container.read(userNameProvider).value, 'John Doe');
      });

      test('이모지가 포함된 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동 😊');

        // Assert
        expect(container.read(userNameProvider).value, '홍길동 😊');
      });
    });
  });
}
