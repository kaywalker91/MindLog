import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    group('생성자', () {
      test('모든 필수 필드를 올바르게 설정한다', () {
        // Given & When
        const settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        // Then
        expect(settings.isReminderEnabled, true);
        expect(settings.reminderHour, 21);
        expect(settings.reminderMinute, 30);
        expect(settings.isMindcareTopicEnabled, true);
      });
    });

    group('defaults 팩토리', () {
      test('기본값으로 설정을 생성한다', () {
        // When
        final settings = NotificationSettings.defaults();

        // Then
        expect(settings.isReminderEnabled, NotificationSettings.defaultReminderEnabled);
        expect(settings.reminderHour, NotificationSettings.defaultReminderHour);
        expect(settings.reminderMinute, NotificationSettings.defaultReminderMinute);
        expect(settings.isMindcareTopicEnabled, NotificationSettings.defaultMindcareTopicEnabled);
      });

      test('기본값 상수가 올바르게 정의되어 있다', () {
        // 직장인 퇴근 후 여유 시간대 (17:00-20:00 연구 기반)
        expect(NotificationSettings.defaultReminderHour, 19);
        expect(NotificationSettings.defaultReminderMinute, 0);
        expect(NotificationSettings.defaultReminderEnabled, false);
        expect(NotificationSettings.defaultMindcareTopicEnabled, false);
      });
    });

    group('copyWith', () {
      test('isReminderEnabled만 변경한다', () {
        // Given
        final original = NotificationSettings.defaults();

        // When
        final updated = original.copyWith(isReminderEnabled: true);

        // Then
        expect(updated.isReminderEnabled, true);
        expect(updated.reminderHour, original.reminderHour);
        expect(updated.reminderMinute, original.reminderMinute);
        expect(updated.isMindcareTopicEnabled, original.isMindcareTopicEnabled);
      });

      test('reminderHour만 변경한다', () {
        // Given
        final original = NotificationSettings.defaults();

        // When
        final updated = original.copyWith(reminderHour: 9);

        // Then
        expect(updated.isReminderEnabled, original.isReminderEnabled);
        expect(updated.reminderHour, 9);
        expect(updated.reminderMinute, original.reminderMinute);
        expect(updated.isMindcareTopicEnabled, original.isMindcareTopicEnabled);
      });

      test('reminderMinute만 변경한다', () {
        // Given
        final original = NotificationSettings.defaults();

        // When
        final updated = original.copyWith(reminderMinute: 45);

        // Then
        expect(updated.isReminderEnabled, original.isReminderEnabled);
        expect(updated.reminderHour, original.reminderHour);
        expect(updated.reminderMinute, 45);
        expect(updated.isMindcareTopicEnabled, original.isMindcareTopicEnabled);
      });

      test('isMindcareTopicEnabled만 변경한다', () {
        // Given
        final original = NotificationSettings.defaults();

        // When
        final updated = original.copyWith(isMindcareTopicEnabled: true);

        // Then
        expect(updated.isReminderEnabled, original.isReminderEnabled);
        expect(updated.reminderHour, original.reminderHour);
        expect(updated.reminderMinute, original.reminderMinute);
        expect(updated.isMindcareTopicEnabled, true);
      });

      test('여러 필드를 동시에 변경한다', () {
        // Given
        final original = NotificationSettings.defaults();

        // When
        final updated = original.copyWith(
          isReminderEnabled: true,
          reminderHour: 8,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        // Then
        expect(updated.isReminderEnabled, true);
        expect(updated.reminderHour, 8);
        expect(updated.reminderMinute, 30);
        expect(updated.isMindcareTopicEnabled, true);
      });

      test('null 전달 시 기존 값을 유지한다', () {
        // Given
        const original = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 7,
          reminderMinute: 15,
          isMindcareTopicEnabled: true,
        );

        // When
        final updated = original.copyWith();

        // Then
        expect(updated.isReminderEnabled, true);
        expect(updated.reminderHour, 7);
        expect(updated.reminderMinute, 15);
        expect(updated.isMindcareTopicEnabled, true);
      });
    });

    group('시간 값 유효성', () {
      test('유효한 시간 범위를 허용한다 (0-23시)', () {
        // 0시 (자정)
        const midnight = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 0,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        expect(midnight.reminderHour, 0);

        // 23시
        const latNight = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 23,
          reminderMinute: 59,
          isMindcareTopicEnabled: false,
        );
        expect(latNight.reminderHour, 23);
        expect(latNight.reminderMinute, 59);
      });

      test('일반적인 알림 시간대를 설정할 수 있다', () {
        // 아침 8시
        const morning = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 8,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        expect(morning.reminderHour, 8);

        // 점심 12시
        const noon = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 12,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        expect(noon.reminderHour, 12);

        // 저녁 21시 (기본값)
        const evening = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        );
        expect(evening.reminderHour, 21);
      });
    });
  });
}
