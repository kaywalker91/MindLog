import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/usecases/get_notification_settings_usecase.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late GetNotificationSettingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetNotificationSettingsUseCase(mockRepository);
  });

  group('GetNotificationSettingsUseCase', () {
    group('정상 조회', () {
      test('Repository에서 알림 설정을 반환해야 한다', () async {
        // Arrange
        final settings = NotificationSettings.defaults();
        when(
          () => mockRepository.getNotificationSettings(),
        ).thenAnswer((_) async => settings);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isReminderEnabled, settings.isReminderEnabled);
        expect(result.reminderHour, settings.reminderHour);
        expect(result.reminderMinute, settings.reminderMinute);
      });

      test('알림이 비활성화된 설정을 반환해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        when(
          () => mockRepository.getNotificationSettings(),
        ).thenAnswer((_) async => settings);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isReminderEnabled, false);
      });

      test('커스텀 시간 설정을 반환해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 9,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );
        when(
          () => mockRepository.getNotificationSettings(),
        ).thenAnswer((_) async => settings);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.reminderHour, 9);
        expect(result.reminderMinute, 30);
      });

      test('isMindcareTopicEnabled 설정도 올바르게 반환해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        );
        when(
          () => mockRepository.getNotificationSettings(),
        ).thenAnswer((_) async => settings);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isMindcareTopicEnabled, true);
      });
    });

    group('에러 처리', () {
      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getNotificationSettings(),
        ).thenAnswer((_) async => throw const Failure.cache(message: '알림 설정 조회 실패'));

        // Act & Assert
        await expectLater(useCase.execute(), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
