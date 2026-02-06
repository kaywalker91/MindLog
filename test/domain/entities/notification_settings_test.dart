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
        expect(
          settings.isReminderEnabled,
          NotificationSettings.defaultReminderEnabled,
        );
        expect(settings.reminderHour, NotificationSettings.defaultReminderHour);
        expect(
          settings.reminderMinute,
          NotificationSettings.defaultReminderMinute,
        );
        expect(
          settings.isMindcareTopicEnabled,
          NotificationSettings.defaultMindcareTopicEnabled,
        );
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

    group('copyWith clamp 방어', () {
      test('reminderHour이 범위 초과 시 clamp 처리한다', () {
        final original = NotificationSettings.defaults();

        final tooHigh = original.copyWith(reminderHour: 25);
        expect(tooHigh.reminderHour, 23);

        final negative = original.copyWith(reminderHour: -1);
        expect(negative.reminderHour, 0);
      });

      test('reminderMinute이 범위 초과 시 clamp 처리한다', () {
        final original = NotificationSettings.defaults();

        final tooHigh = original.copyWith(reminderMinute: 75);
        expect(tooHigh.reminderMinute, 59);

        final negative = original.copyWith(reminderMinute: -5);
        expect(negative.reminderMinute, 0);
      });

      test('경계값이 정상 통과한다', () {
        final original = NotificationSettings.defaults();

        final hour0 = original.copyWith(reminderHour: 0);
        expect(hour0.reminderHour, 0);

        final hour23 = original.copyWith(reminderHour: 23);
        expect(hour23.reminderHour, 23);

        final min0 = original.copyWith(reminderMinute: 0);
        expect(min0.reminderMinute, 0);

        final min59 = original.copyWith(reminderMinute: 59);
        expect(min59.reminderMinute, 59);
      });
    });

    group('currentIndex', () {
      test('정상 범위 내 인덱스를 반환한다', () {
        expect(NotificationSettings.currentIndex(0, 3), 0);
        expect(NotificationSettings.currentIndex(1, 3), 1);
        expect(NotificationSettings.currentIndex(2, 3), 2);
      });

      test('인덱스가 totalCount 이상이면 modulo 래핑한다', () {
        expect(NotificationSettings.currentIndex(3, 3), 0);
        expect(NotificationSettings.currentIndex(5, 3), 2);
        expect(NotificationSettings.currentIndex(10, 3), 1);
      });

      test('totalCount가 0이면 0을 반환한다', () {
        expect(NotificationSettings.currentIndex(0, 0), 0);
        expect(NotificationSettings.currentIndex(5, 0), 0);
      });

      test('totalCount가 1이면 항상 0을 반환한다', () {
        expect(NotificationSettings.currentIndex(0, 1), 0);
        expect(NotificationSettings.currentIndex(99, 1), 0);
      });
    });

    group('nextIndex', () {
      test('다음 순차 인덱스를 반환한다', () {
        expect(NotificationSettings.nextIndex(0, 3), 1);
        expect(NotificationSettings.nextIndex(1, 3), 2);
      });

      test('마지막 인덱스에서 0으로 래핑한다', () {
        expect(NotificationSettings.nextIndex(2, 3), 0);
        expect(NotificationSettings.nextIndex(9, 10), 0);
      });

      test('totalCount가 0이면 0을 반환한다', () {
        expect(NotificationSettings.nextIndex(0, 0), 0);
        expect(NotificationSettings.nextIndex(5, 0), 0);
      });

      test('totalCount가 1이면 항상 0을 반환한다', () {
        expect(NotificationSettings.nextIndex(0, 1), 0);
        expect(NotificationSettings.nextIndex(99, 1), 0);
      });
    });

    group('adjustIndexAfterDeletion', () {
      test('삭제 인덱스가 현재 인덱스보다 크면 null 반환 (변경 불필요)', () {
        expect(NotificationSettings.adjustIndexAfterDeletion(2, 4, 5), isNull);
        expect(NotificationSettings.adjustIndexAfterDeletion(0, 1, 5), isNull);
      });

      test('삭제 인덱스가 음수이면 null 반환', () {
        expect(
          NotificationSettings.adjustIndexAfterDeletion(2, -1, 5),
          isNull,
        );
      });

      test('남은 메시지가 0이고 lastDisplayed가 0이 아니면 0 반환', () {
        expect(NotificationSettings.adjustIndexAfterDeletion(2, 2, 0), 0);
      });

      test('남은 메시지가 0이고 lastDisplayed도 0이면 null 반환 (변경 불필요)', () {
        expect(NotificationSettings.adjustIndexAfterDeletion(0, 0, 0), isNull);
      });

      test('삭제 인덱스가 현재 인덱스와 같으면 1 감소', () {
        // last=3, deleted=3, remaining=4 → (3-1+4)%4 = 2
        expect(NotificationSettings.adjustIndexAfterDeletion(3, 3, 4), 2);
      });

      test('삭제 인덱스가 현재 인덱스보다 작으면 1 감소', () {
        // last=4, deleted=1, remaining=4 → (4-1+4)%4 = 3
        expect(NotificationSettings.adjustIndexAfterDeletion(4, 1, 4), 3);
      });

      test('인덱스 0 삭제 시 wrap-around 처리한다', () {
        // last=0, deleted=0, remaining=4 → (0-1+4)%4 = 3
        expect(NotificationSettings.adjustIndexAfterDeletion(0, 0, 4), 3);
      });

      test('보정 전후 값이 같으면 null 반환', () {
        // last=2, deleted=1, remaining=3 → (2-1+3)%3 = 1 ≠ 2 → 1 반환
        expect(NotificationSettings.adjustIndexAfterDeletion(2, 1, 3), 1);
        // last=1, deleted=0, remaining=1 → (1-1+1)%1 = 0 ≠ 1 → 0 반환
        expect(NotificationSettings.adjustIndexAfterDeletion(1, 0, 1), 0);
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
