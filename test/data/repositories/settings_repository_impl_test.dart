import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/data/repositories/settings_repository_impl.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';

import '../../mocks/mock_datasources.dart';

void main() {
  late SettingsRepositoryImpl repository;
  late MockPreferencesLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockPreferencesLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: mockDataSource);
  });

  tearDown(() {
    mockDataSource.reset();
  });

  group('SettingsRepositoryImpl', () {
    group('AI Character', () {
      test('기본값으로 warmCounselor를 반환해야 한다', () async {
        // Act
        final result = await repository.getSelectedAiCharacter();

        // Assert
        expect(result, AiCharacter.warmCounselor);
      });

      test('캐릭터를 저장하고 조회할 수 있어야 한다', () async {
        // Arrange
        const targetCharacter = AiCharacter.realisticCoach;

        // Act
        await repository.setSelectedAiCharacter(targetCharacter);
        final result = await repository.getSelectedAiCharacter();

        // Assert
        expect(result, targetCharacter);
      });

      test('cheerfulFriend 캐릭터를 저장할 수 있어야 한다', () async {
        // Arrange
        const targetCharacter = AiCharacter.cheerfulFriend;

        // Act
        await repository.setSelectedAiCharacter(targetCharacter);
        final result = await repository.getSelectedAiCharacter();

        // Assert
        expect(result, targetCharacter);
      });

      test('조회 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getSelectedAiCharacter(),
          throwsA(isA<Failure>()),
        );
      });

      test('저장 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnSet = true;

        // Act & Assert
        await expectLater(
          repository.setSelectedAiCharacter(AiCharacter.realisticCoach),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('Notification Settings', () {
      test('기본 설정을 반환해야 한다', () async {
        // Act
        final result = await repository.getNotificationSettings();

        // Assert
        expect(result.isReminderEnabled, false);
        expect(result.reminderHour, 19);
        expect(result.reminderMinute, 0);
        expect(result.isMindcareTopicEnabled, false);
      });

      test('설정을 저장하고 조회할 수 있어야 한다', () async {
        // Arrange
        const newSettings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        // Act
        await repository.setNotificationSettings(newSettings);
        final result = await repository.getNotificationSettings();

        // Assert
        expect(result.isReminderEnabled, true);
        expect(result.reminderHour, 21);
        expect(result.reminderMinute, 30);
        expect(result.isMindcareTopicEnabled, true);
      });

      test('부분 업데이트가 올바르게 동작해야 한다', () async {
        // Arrange
        const initialSettings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 18,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        await repository.setNotificationSettings(initialSettings);

        // Act - 시간만 변경
        final updated = initialSettings.copyWith(reminderHour: 20, reminderMinute: 45);
        await repository.setNotificationSettings(updated);
        final result = await repository.getNotificationSettings();

        // Assert
        expect(result.isReminderEnabled, true); // 유지
        expect(result.reminderHour, 20); // 변경됨
        expect(result.reminderMinute, 45); // 변경됨
        expect(result.isMindcareTopicEnabled, false); // 유지
      });

      test('조회 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getNotificationSettings(),
          throwsA(isA<Failure>()),
        );
      });

      test('저장 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnSet = true;

        // Act & Assert
        await expectLater(
          repository.setNotificationSettings(NotificationSettings.defaults()),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('User Name', () {
      test('미설정 시 null을 반환해야 한다', () async {
        // Act
        final result = await repository.getUserName();

        // Assert
        expect(result, isNull);
      });

      test('이름을 저장하고 조회할 수 있어야 한다', () async {
        // Arrange
        const userName = '김민지';

        // Act
        await repository.setUserName(userName);
        final result = await repository.getUserName();

        // Assert
        expect(result, userName);
      });

      test('빈 문자열은 null로 변환해야 한다', () async {
        // Arrange
        mockDataSource.setMockUserName('기존이름');

        // Act
        await repository.setUserName('');
        final result = await repository.getUserName();

        // Assert
        expect(result, isNull);
      });

      test('공백만 있는 문자열은 null로 변환해야 한다', () async {
        // Arrange
        mockDataSource.setMockUserName('기존이름');

        // Act
        await repository.setUserName('   ');
        final result = await repository.getUserName();

        // Assert
        expect(result, isNull);
      });

      test('이름 앞뒤 공백을 제거해야 한다', () async {
        // Act
        await repository.setUserName('  홍길동  ');
        final result = await repository.getUserName();

        // Assert
        expect(result, '홍길동');
      });

      test('조회 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getUserName(),
          throwsA(isA<Failure>()),
        );
      });

      test('저장 실패 시 CacheFailure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnSet = true;

        // Act & Assert
        await expectLater(
          repository.setUserName('테스트'),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('통합 시나리오', () {
      test('여러 설정을 독립적으로 저장/조회할 수 있어야 한다', () async {
        // Arrange & Act
        await repository.setSelectedAiCharacter(AiCharacter.realisticCoach);
        await repository.setNotificationSettings(const NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 8,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        ));
        await repository.setUserName('테스트유저');

        // Assert - 각각 독립적으로 저장됨
        final character = await repository.getSelectedAiCharacter();
        final notifications = await repository.getNotificationSettings();
        final userName = await repository.getUserName();

        expect(character, AiCharacter.realisticCoach);
        expect(notifications.isReminderEnabled, true);
        expect(notifications.reminderHour, 8);
        expect(userName, '테스트유저');
      });
    });
  });
}
