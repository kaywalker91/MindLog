import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/data/datasources/local/preferences_local_datasource.dart';

void main() {
  late PreferencesLocalDataSource dataSource;

  setUp(() {
    // SharedPreferences 모킹 초기화
    SharedPreferences.setMockInitialValues({});
    dataSource = PreferencesLocalDataSource();
  });

  group('PreferencesLocalDataSource', () {
    group('AI 캐릭터 설정', () {
      test('기본값은 warmCounselor여야 한다', () async {
        final character = await dataSource.getSelectedAiCharacter();

        expect(character, AiCharacter.warmCounselor);
      });

      test('설정한 캐릭터를 올바르게 반환해야 한다', () async {
        await dataSource.setSelectedAiCharacter(AiCharacter.realisticCoach);

        final character = await dataSource.getSelectedAiCharacter();

        expect(character, AiCharacter.realisticCoach);
      });

      test('cheerfulFriend 캐릭터도 올바르게 저장/조회되어야 한다', () async {
        await dataSource.setSelectedAiCharacter(AiCharacter.cheerfulFriend);

        final character = await dataSource.getSelectedAiCharacter();

        expect(character, AiCharacter.cheerfulFriend);
      });

      test('알 수 없는 ID는 기본 캐릭터(warmCounselor)로 대체해야 한다', () async {
        // 직접 SharedPreferences에 알 수 없는 값 설정
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_character', 'unknown_character_id');

        final character = await dataSource.getSelectedAiCharacter();

        // aiCharacterFromId에서 알 수 없는 ID는 warmCounselor로 반환
        expect(character, AiCharacter.warmCounselor);
      });
    });

    group('알림 설정', () {
      test('기본값은 NotificationSettings.defaults()여야 한다', () async {
        final settings = await dataSource.getNotificationSettings();

        expect(settings.isReminderEnabled, NotificationSettings.defaultReminderEnabled);
        expect(settings.reminderHour, NotificationSettings.defaultReminderHour);
        expect(settings.reminderMinute, NotificationSettings.defaultReminderMinute);
        expect(settings.isMindcareTopicEnabled, NotificationSettings.defaultMindcareTopicEnabled);
      });

      test('설정한 값을 올바르게 저장/조회해야 한다', () async {
        final customSettings = const NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 20,
          reminderMinute: 30,
          isMindcareTopicEnabled: true,
        );

        await dataSource.setNotificationSettings(customSettings);
        final retrieved = await dataSource.getNotificationSettings();

        expect(retrieved.isReminderEnabled, true);
        expect(retrieved.reminderHour, 20);
        expect(retrieved.reminderMinute, 30);
        expect(retrieved.isMindcareTopicEnabled, true);
      });

      test('부분 설정만 있어도 기본값으로 채워야 한다', () async {
        // reminderEnabled만 설정하고 나머지는 기본값
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_reminder_enabled', true);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.isReminderEnabled, true);
        expect(settings.reminderHour, NotificationSettings.defaultReminderHour);
        expect(settings.reminderMinute, NotificationSettings.defaultReminderMinute);
        expect(settings.isMindcareTopicEnabled, NotificationSettings.defaultMindcareTopicEnabled);
      });

      test('reminderHour과 reminderMinute만 설정된 경우도 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_hour', 8);
        await prefs.setInt('notification_reminder_minute', 45);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.isReminderEnabled, NotificationSettings.defaultReminderEnabled);
        expect(settings.reminderHour, 8);
        expect(settings.reminderMinute, 45);
      });
    });

    group('유저 이름', () {
      test('미설정 시 null을 반환해야 한다', () async {
        final userName = await dataSource.getUserName();

        expect(userName, isNull);
      });

      test('설정한 이름을 올바르게 반환해야 한다', () async {
        await dataSource.setUserName('홍길동');

        final userName = await dataSource.getUserName();

        expect(userName, '홍길동');
      });

      test('빈 문자열 설정 시 삭제해야 한다', () async {
        await dataSource.setUserName('초기이름');
        await dataSource.setUserName('');

        final userName = await dataSource.getUserName();

        expect(userName, isNull);
      });

      test('공백만 있는 경우 삭제해야 한다', () async {
        await dataSource.setUserName('초기이름');
        await dataSource.setUserName('   ');

        final userName = await dataSource.getUserName();

        expect(userName, isNull);
      });

      test('정상 이름은 trim 후 저장해야 한다', () async {
        await dataSource.setUserName('  김철수  ');

        final userName = await dataSource.getUserName();

        expect(userName, '김철수');
      });

      test('null 설정 시 삭제해야 한다', () async {
        await dataSource.setUserName('초기이름');
        await dataSource.setUserName(null);

        final userName = await dataSource.getUserName();

        expect(userName, isNull);
      });
    });

    group('업데이트 버전', () {
      test('dismiss된 버전을 저장/조회해야 한다', () async {
        await dataSource.setDismissedUpdateVersion('1.2.0');

        final version = await dataSource.getDismissedUpdateVersion();

        expect(version, '1.2.0');
      });

      test('미설정 시 null을 반환해야 한다', () async {
        final version = await dataSource.getDismissedUpdateVersion();

        expect(version, isNull);
      });

      test('clearDismissedUpdateVersion으로 삭제해야 한다', () async {
        await dataSource.setDismissedUpdateVersion('1.2.0');
        await dataSource.clearDismissedUpdateVersion();

        final version = await dataSource.getDismissedUpdateVersion();

        expect(version, isNull);
      });

      test('lastSeenAppVersion을 저장/조회해야 한다', () async {
        await dataSource.setLastSeenAppVersion('1.4.18');

        final version = await dataSource.getLastSeenAppVersion();

        expect(version, '1.4.18');
      });

      test('lastSeenAppVersion 미설정 시 null을 반환해야 한다', () async {
        final version = await dataSource.getLastSeenAppVersion();

        expect(version, isNull);
      });

      test('버전을 덮어쓰기할 수 있어야 한다', () async {
        await dataSource.setDismissedUpdateVersion('1.0.0');
        await dataSource.setDismissedUpdateVersion('2.0.0');

        final version = await dataSource.getDismissedUpdateVersion();

        expect(version, '2.0.0');
      });
    });

    group('데이터 격리', () {
      test('각 설정 키가 독립적으로 동작해야 한다', () async {
        // 모든 설정을 동시에 저장
        await dataSource.setSelectedAiCharacter(AiCharacter.realisticCoach);
        await dataSource.setUserName('테스트유저');
        await dataSource.setNotificationSettings(const NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        ));
        await dataSource.setDismissedUpdateVersion('1.5.0');
        await dataSource.setLastSeenAppVersion('1.4.18');

        // 각각 독립적으로 조회
        expect(await dataSource.getSelectedAiCharacter(), AiCharacter.realisticCoach);
        expect(await dataSource.getUserName(), '테스트유저');

        final settings = await dataSource.getNotificationSettings();
        expect(settings.isReminderEnabled, true);
        expect(settings.reminderHour, 21);

        expect(await dataSource.getDismissedUpdateVersion(), '1.5.0');
        expect(await dataSource.getLastSeenAppVersion(), '1.4.18');
      });
    });
  });
}
