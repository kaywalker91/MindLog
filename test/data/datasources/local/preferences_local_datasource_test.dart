import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
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

      test('설정한 값을 올바르게 저장/조회해야 한다', () async {
        const customSettings = NotificationSettings(
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
        expect(
          settings.reminderMinute,
          NotificationSettings.defaultReminderMinute,
        );
        expect(
          settings.isMindcareTopicEnabled,
          NotificationSettings.defaultMindcareTopicEnabled,
        );
      });

      test('reminderHour과 reminderMinute만 설정된 경우도 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_hour', 8);
        await prefs.setInt('notification_reminder_minute', 45);

        final settings = await dataSource.getNotificationSettings();

        expect(
          settings.isReminderEnabled,
          NotificationSettings.defaultReminderEnabled,
        );
        expect(settings.reminderHour, 8);
        expect(settings.reminderMinute, 45);
      });
    });

    group('메시지 로테이션 모드 직렬화', () {
      test('random 모드가 올바르게 저장/조회되어야 한다', () async {
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
          rotationMode: MessageRotationMode.random,
        );

        await dataSource.setNotificationSettings(settings);
        final retrieved = await dataSource.getNotificationSettings();

        expect(retrieved.rotationMode, MessageRotationMode.random);
      });

      test('sequential 모드가 올바르게 저장/조회되어야 한다', () async {
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
          rotationMode: MessageRotationMode.sequential,
        );

        await dataSource.setNotificationSettings(settings);
        final retrieved = await dataSource.getNotificationSettings();

        expect(retrieved.rotationMode, MessageRotationMode.sequential);
      });

      test('emotionAware 모드가 "emotionAware" 문자열로 직렬화되어야 한다', () async {
        const settings = NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
          rotationMode: MessageRotationMode.emotionAware,
        );

        await dataSource.setNotificationSettings(settings);

        // SharedPreferences에서 직접 문자열 확인
        final prefs = await SharedPreferences.getInstance();
        final modeStr = prefs.getString('message_rotation_mode');

        expect(modeStr, 'emotionAware');
      });

      test('"emotionAware" 문자열이 emotionAware 모드로 역직렬화되어야 한다', () async {
        // SharedPreferences에 직접 문자열 설정
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('message_rotation_mode', 'emotionAware');

        final settings = await dataSource.getNotificationSettings();

        expect(settings.rotationMode, MessageRotationMode.emotionAware);
      });

      test('"sequential" 문자열이 sequential 모드로 역직렬화되어야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('message_rotation_mode', 'sequential');

        final settings = await dataSource.getNotificationSettings();

        expect(settings.rotationMode, MessageRotationMode.sequential);
      });

      test('알 수 없는 모드 문자열은 random으로 대체되어야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('message_rotation_mode', 'unknown_mode');

        final settings = await dataSource.getNotificationSettings();

        expect(settings.rotationMode, MessageRotationMode.random);
      });

      test('모드 미설정 시 기본값은 random이어야 한다', () async {
        final settings = await dataSource.getNotificationSettings();

        expect(settings.rotationMode, MessageRotationMode.random);
      });

      test('모든 모드가 왕복 직렬화/역직렬화되어야 한다', () async {
        for (final mode in MessageRotationMode.values) {
          final settings = NotificationSettings(
            isReminderEnabled: false,
            reminderHour: 19,
            reminderMinute: 0,
            isMindcareTopicEnabled: false,
            rotationMode: mode,
          );

          await dataSource.setNotificationSettings(settings);
          final retrieved = await dataSource.getNotificationSettings();

          expect(
            retrieved.rotationMode,
            mode,
            reason: '$mode 모드가 왕복 후 변경됨',
          );
        }
      });
    });

    group('알림 시간 clamp 방어', () {
      test('범위 초과 reminderHour을 clamp 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_hour', 25);
        await prefs.setInt('notification_reminder_minute', 0);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.reminderHour, 23);
      });

      test('음수 reminderHour을 0으로 clamp 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_hour', -1);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.reminderHour, 0);
      });

      test('범위 초과 reminderMinute을 clamp 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_minute', 75);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.reminderMinute, 59);
      });

      test('음수 reminderMinute을 0으로 clamp 처리해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_reminder_minute', -10);

        final settings = await dataSource.getNotificationSettings();

        expect(settings.reminderMinute, 0);
      });
    });

    group('개인 응원 메시지 손상 JSON 방어', () {
      test('손상된 JSON 저장 시 빈 리스트를 반환해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('self_encouragement_messages', 'invalid json{{{');

        final messages = await dataSource.getSelfEncouragementMessages();

        expect(messages, isEmpty);
      });

      test('손상된 JSON은 제거되어야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('self_encouragement_messages', 'not a json');

        await dataSource.getSelfEncouragementMessages();

        // 손상 데이터가 제거되었으므로 다시 조회하면 빈 리스트
        final secondRead = await dataSource.getSelfEncouragementMessages();
        expect(secondRead, isEmpty);

        // SharedPreferences에서도 키가 제거됨
        expect(prefs.getString('self_encouragement_messages'), isNull);
      });

      test('빈 문자열 저장 시 빈 리스트를 반환해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('self_encouragement_messages', '');

        final messages = await dataSource.getSelfEncouragementMessages();

        expect(messages, isEmpty);
      });

      test('null 키 시 빈 리스트를 반환해야 한다', () async {
        final messages = await dataSource.getSelfEncouragementMessages();

        expect(messages, isEmpty);
      });

      test('유효하지 않은 구조의 JSON 배열 시 빈 리스트를 반환해야 한다', () async {
        final prefs = await SharedPreferences.getInstance();
        // 배열이지만 Map이 아닌 요소
        await prefs.setString(
          'self_encouragement_messages',
          '[1, 2, "hello"]',
        );

        final messages = await dataSource.getSelfEncouragementMessages();

        expect(messages, isEmpty);
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
        await dataSource.setNotificationSettings(
          const NotificationSettings(
            isReminderEnabled: true,
            reminderHour: 21,
            reminderMinute: 0,
            isMindcareTopicEnabled: true,
          ),
        );
        await dataSource.setDismissedUpdateVersion('1.5.0');
        await dataSource.setLastSeenAppVersion('1.4.18');

        // 각각 독립적으로 조회
        expect(
          await dataSource.getSelectedAiCharacter(),
          AiCharacter.realisticCoach,
        );
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
