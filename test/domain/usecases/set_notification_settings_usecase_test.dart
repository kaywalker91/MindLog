import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late SetNotificationSettingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SetNotificationSettingsUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('SetNotificationSettingsUseCase', () {
    group('정상 저장', () {
      test('Repository에 알림 설정을 저장해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await useCase.execute(settings);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.isReminderEnabled, true);
        expect(savedSettings.reminderHour, 21);
        expect(savedSettings.reminderMinute, 0);
      });

      test('알림 비활성화 설정을 저장해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await useCase.execute(settings);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.isReminderEnabled, false);
      });

      test('커스텀 시간 설정을 저장해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 7,
          reminderMinute: 30,
          isMindcareTopicEnabled: false,
        );

        // Act
        await useCase.execute(settings);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.reminderHour, 7);
        expect(savedSettings.reminderMinute, 30);
      });

      test('isMindcareTopicEnabled 설정을 저장해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        );

        // Act
        await useCase.execute(settings);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.isMindcareTopicEnabled, true);
      });

      test('연속 설정 변경이 올바르게 동작해야 한다', () async {
        // Arrange
        const settings1 = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 9,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        const settings2 = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        // Act
        await useCase.execute(settings1);
        await useCase.execute(settings2);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.isReminderEnabled, false);
        expect(savedSettings.reminderHour, 21);
        expect(savedSettings.reminderMinute, 30);
        expect(savedSettings.isMindcareTopicEnabled, true);
      });
    });

    group('에지 케이스', () {
      test('자정 시간 설정을 저장해야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 0,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await useCase.execute(settings);

        // Assert
        final savedSettings = await mockRepository.getNotificationSettings();
        expect(savedSettings.reminderHour, 0);
        expect(savedSettings.reminderMinute, 0);
      });
    });

    group('에러 처리', () {
      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnSet = true;
        mockRepository.failureToThrow = const Failure.cache(
          message: '알림 설정 저장 실패',
        );

        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act & Assert
        await expectLater(
          useCase.execute(settings),
          throwsA(isA<CacheFailure>()),
        );
      });
    });
  });
}
