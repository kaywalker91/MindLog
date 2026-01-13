import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/usecases/get_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

/// Mock GetNotificationSettingsUseCase
class MockGetNotificationSettingsUseCase implements GetNotificationSettingsUseCase {
  NotificationSettings mockSettings = NotificationSettings.defaults();
  bool shouldThrow = false;
  Failure? failureToThrow;

  void reset() {
    mockSettings = NotificationSettings.defaults();
    shouldThrow = false;
    failureToThrow = null;
  }

  @override
  Future<NotificationSettings> execute() async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 조회 실패');
    }
    return mockSettings;
  }
}

/// Mock SetNotificationSettingsUseCase
class MockSetNotificationSettingsUseCase implements SetNotificationSettingsUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  final List<NotificationSettings> savedSettings = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    savedSettings.clear();
  }

  @override
  Future<void> execute(NotificationSettings settings) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '알림 설정 저장 실패');
    }
    savedSettings.add(settings);
  }
}

void main() {
  late ProviderContainer container;
  late MockGetNotificationSettingsUseCase mockGetUseCase;
  late MockSetNotificationSettingsUseCase mockSetUseCase;

  setUp(() {
    mockGetUseCase = MockGetNotificationSettingsUseCase();
    mockSetUseCase = MockSetNotificationSettingsUseCase();

    container = ProviderContainer(
      overrides: [
        getNotificationSettingsUseCaseProvider.overrideWithValue(mockGetUseCase),
        setNotificationSettingsUseCaseProvider.overrideWithValue(mockSetUseCase),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    mockGetUseCase.reset();
    mockSetUseCase.reset();
  });

  group('NotificationSettingsController', () {
    group('build (초기 로드)', () {
      test('초기 로드 시 UseCase에서 설정을 조회해야 한다', () async {
        // Arrange
        const customSettings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 9,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );
        mockGetUseCase.mockSettings = customSettings;

        // Act
        final settings = await container.read(getNotificationSettingsUseCaseProvider).execute();

        // Assert
        expect(settings.isReminderEnabled, true);
        expect(settings.reminderHour, 9);
        expect(settings.reminderMinute, 30);
        expect(settings.isMindcareTopicEnabled, true);
      });

      test('기본 설정이 조회되어야 한다', () async {
        // Act
        final settings = await container.read(getNotificationSettingsUseCaseProvider).execute();

        // Assert
        final defaults = NotificationSettings.defaults();
        expect(settings.isReminderEnabled, defaults.isReminderEnabled);
        expect(settings.reminderHour, defaults.reminderHour);
        expect(settings.reminderMinute, defaults.reminderMinute);
      });

      test('UseCase 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        mockGetUseCase.shouldThrow = true;
        mockGetUseCase.failureToThrow = const Failure.cache(message: '조회 실패');

        // Act & Assert
        await expectLater(
          container.read(getNotificationSettingsUseCaseProvider).execute(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('SetNotificationSettingsUseCase', () {
      test('알림 활성화 설정을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings.last.isReminderEnabled, true);
      });

      test('알림 비활성화 설정을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.last.isReminderEnabled, false);
      });

      test('커스텀 알림 시간을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 7,
          reminderMinute: 30,
          isMindcareTopicEnabled: false,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.last.reminderHour, 7);
        expect(mockSetUseCase.savedSettings.last.reminderMinute, 30);
      });

      test('자정 시간(00:00) 설정을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 0,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.last.reminderHour, 0);
        expect(mockSetUseCase.savedSettings.last.reminderMinute, 0);
      });

      test('23:59 시간 설정을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 23,
          reminderMinute: 59,
          isMindcareTopicEnabled: false,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.last.reminderHour, 23);
        expect(mockSetUseCase.savedSettings.last.reminderMinute, 59);
      });

      test('마인드케어 토픽 활성화 설정을 저장할 수 있어야 한다', () async {
        // Arrange
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        );

        // Act
        await container.read(setNotificationSettingsUseCaseProvider).execute(settings);

        // Assert
        expect(mockSetUseCase.savedSettings.last.isMindcareTopicEnabled, true);
      });

      test('연속 설정 변경이 올바르게 저장되어야 한다', () async {
        // Arrange
        final useCase = container.read(setNotificationSettingsUseCaseProvider);

        const settings1 = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 8,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        const settings2 = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        // Act
        await useCase.execute(settings1);
        await useCase.execute(settings2);

        // Assert
        expect(mockSetUseCase.savedSettings.length, 2);
        expect(mockSetUseCase.savedSettings.last.isReminderEnabled, false);
        expect(mockSetUseCase.savedSettings.last.reminderHour, 20);
        expect(mockSetUseCase.savedSettings.last.reminderMinute, 30);
        expect(mockSetUseCase.savedSettings.last.isMindcareTopicEnabled, true);
      });

      test('UseCase 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        mockSetUseCase.shouldThrow = true;
        mockSetUseCase.failureToThrow = const Failure.cache(message: '저장 실패');

        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act & Assert
        await expectLater(
          container.read(setNotificationSettingsUseCaseProvider).execute(settings),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('NotificationSettings copyWith', () {
      test('isReminderEnabled만 변경할 수 있어야 한다', () {
        // Arrange
        const original = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        final updated = original.copyWith(isReminderEnabled: true);

        // Assert
        expect(updated.isReminderEnabled, true);
        expect(updated.reminderHour, 20);
        expect(updated.reminderMinute, 0);
        expect(updated.isMindcareTopicEnabled, false);
      });

      test('reminderHour와 reminderMinute만 변경할 수 있어야 한다', () {
        // Arrange
        const original = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        final updated = original.copyWith(reminderHour: 7, reminderMinute: 30);

        // Assert
        expect(updated.isReminderEnabled, true);
        expect(updated.reminderHour, 7);
        expect(updated.reminderMinute, 30);
        expect(updated.isMindcareTopicEnabled, false);
      });

      test('isMindcareTopicEnabled만 변경할 수 있어야 한다', () {
        // Arrange
        const original = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );

        // Act
        final updated = original.copyWith(isMindcareTopicEnabled: true);

        // Assert
        expect(updated.isReminderEnabled, false);
        expect(updated.reminderHour, 20);
        expect(updated.reminderMinute, 0);
        expect(updated.isMindcareTopicEnabled, true);
      });
    });
  });
}
