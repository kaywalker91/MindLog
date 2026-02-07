import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

void main() {
  // 테스트용 메시지 팩토리
  SelfEncouragementMessage createMessage(int order, {String? content}) {
    return SelfEncouragementMessage(
      id: 'msg_$order',
      content: content ?? '메시지 $order',
      createdAt: DateTime(2026, 1, 1),
      displayOrder: order,
    );
  }

  NotificationSettings createSettings({
    bool isReminderEnabled = true,
    int reminderHour = 19,
    int reminderMinute = 0,
    bool isMindcareTopicEnabled = false,
    MessageRotationMode mode = MessageRotationMode.sequential,
    int lastDisplayedIndex = 0,
  }) {
    return NotificationSettings(
      isReminderEnabled: isReminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      isMindcareTopicEnabled: isMindcareTopicEnabled,
      rotationMode: mode,
      lastDisplayedIndex: lastDisplayedIndex,
    );
  }

  group('NotificationSettingsService.selectMessage', () {
    group('공통 동작', () {
      test('빈 메시지 목록이면 null을 반환해야 한다', () {
        final settings = createSettings();
        final result =
            NotificationSettingsService.selectMessage(settings, []);
        expect(result, isNull);
      });
    });

    group('순차 모드 (sequential)', () {
      test('lastDisplayedIndex=0이면 첫 번째 메시지를 반환해야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        final settings = createSettings(lastDisplayedIndex: 0);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[0]));
      });

      test('lastDisplayedIndex=2이면 세 번째 메시지를 반환해야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        final settings = createSettings(lastDisplayedIndex: 2);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[2]));
      });

      test('lastDisplayedIndex가 메시지 수를 초과하면 modulo로 래핑해야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        // 5 % 3 = 2 → messages[2]
        final settings = createSettings(lastDisplayedIndex: 5);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[2]));
      });

      test('lastDisplayedIndex가 메시지 수와 같으면 첫 번째로 돌아가야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        // 3 % 3 = 0 → messages[0]
        final settings = createSettings(lastDisplayedIndex: 3);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[0]));
      });

      test('메시지가 1개일 때 항상 해당 메시지를 반환해야 한다', () {
        final messages = [createMessage(0, content: '유일한 메시지')];

        for (var i = 0; i < 5; i++) {
          final settings = createSettings(lastDisplayedIndex: i);
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, equals(messages[0]), reason: 'index=$i');
        }
      });

      test('큰 lastDisplayedIndex도 안전하게 처리해야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
        ];
        // 999 % 2 = 1 → messages[1]
        final settings = createSettings(lastDisplayedIndex: 999);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[1]));
      });

      test('lastDisplayedIndex=0, 메시지 10개 → 첫 번째 반환', () {
        final messages =
            List.generate(10, (i) => createMessage(i));
        final settings = createSettings(lastDisplayedIndex: 0);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[0]));
      });

      test('lastDisplayedIndex=9, 메시지 10개 → 마지막 반환', () {
        final messages =
            List.generate(10, (i) => createMessage(i));
        final settings = createSettings(lastDisplayedIndex: 9);

        final result =
            NotificationSettingsService.selectMessage(settings, messages);

        expect(result, equals(messages[9]));
      });
    });

    group('랜덤 모드 (random)', () {
      test('반환된 메시지가 목록에 포함되어야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        final settings = createSettings(
          mode: MessageRotationMode.random,
        );

        // 100회 반복으로 항상 유효한 메시지 반환 검증
        for (var i = 0; i < 100; i++) {
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, isNotNull);
          expect(messages, contains(result));
        }
      });

      test('메시지가 1개일 때 항상 해당 메시지를 반환해야 한다', () {
        final messages = [createMessage(0, content: '유일한 메시지')];
        final settings = createSettings(
          mode: MessageRotationMode.random,
        );

        for (var i = 0; i < 20; i++) {
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, equals(messages[0]));
        }
      });

      test('여러 메시지에서 다양한 선택이 이루어져야 한다 (통계적 검증)', () {
        final messages = List.generate(5, (i) => createMessage(i));
        final settings = createSettings(
          mode: MessageRotationMode.random,
        );

        final selectedIds = <String>{};
        // 200회 실행 시 5개 메시지 중 최소 2개 이상 선택되어야 함
        for (var i = 0; i < 200; i++) {
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          selectedIds.add(result!.id);
        }

        expect(
          selectedIds.length,
          greaterThanOrEqualTo(2),
          reason: '200회 시행 시 최소 2종류 이상 선택되어야 함',
        );
      });

      test('lastDisplayedIndex가 랜덤 모드 선택에 영향을 주지 않아야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];

        // 다양한 lastDisplayedIndex로 테스트
        for (final idx in [0, 1, 5, 99]) {
          final settings = createSettings(
            mode: MessageRotationMode.random,
            lastDisplayedIndex: idx,
          );
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, isNotNull);
          expect(messages, contains(result));
        }
      });
    });

    group('경계값 테스트', () {
      test('메시지 최대 개수(10개)에서 순차 모드가 올바르게 작동해야 한다', () {
        final messages = List.generate(
          SelfEncouragementMessage.maxMessageCount,
          (i) => createMessage(i),
        );

        for (var i = 0; i < SelfEncouragementMessage.maxMessageCount; i++) {
          final settings = createSettings(lastDisplayedIndex: i);
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, equals(messages[i]), reason: 'index=$i');
        }
      });

      test('메시지 최대 개수에서 래핑이 올바르게 작동해야 한다', () {
        const max = SelfEncouragementMessage.maxMessageCount;
        final messages = List.generate(max, (i) => createMessage(i));

        // index=max → messages[0] (래핑)
        final settings = createSettings(lastDisplayedIndex: max);
        final result =
            NotificationSettingsService.selectMessage(settings, messages);
        expect(result, equals(messages[0]));
      });

      test('메시지 최대 개수에서 랜덤 모드가 올바르게 작동해야 한다', () {
        final messages = List.generate(
          SelfEncouragementMessage.maxMessageCount,
          (i) => createMessage(i),
        );
        final settings = createSettings(
          mode: MessageRotationMode.random,
        );

        for (var i = 0; i < 50; i++) {
          final result =
              NotificationSettingsService.selectMessage(settings, messages);
          expect(result, isNotNull);
          expect(messages, contains(result));
        }
      });
    });
  });

  // ── applySettings 통합 테스트 ──

  group('NotificationSettingsService.applySettings', () {
    // 스케줄링 호출 기록
    late List<Map<String, dynamic>> scheduleCalls;
    late bool cancelCalled;
    late List<String> subscribedTopics;
    late List<String> unsubscribedTopics;

    setUp(() {
      NotificationSettingsService.resetForTesting();
      scheduleCalls = [];
      cancelCalled = false;
      subscribedTopics = [];
      unsubscribedTopics = [];

      // 기본 mock 설정
      NotificationSettingsService.areNotificationsEnabledOverride =
          () async => true;
      NotificationSettingsService.canScheduleExactAlarmsOverride =
          () async => true;
      NotificationSettingsService.isIgnoringBatteryOverride =
          () async => true;
      NotificationSettingsService.scheduleDailyReminderOverride = ({
        required int hour,
        required int minute,
        required String title,
        String? body,
        String? payload,
        AndroidScheduleMode? scheduleMode,
      }) async {
        scheduleCalls.add({
          'hour': hour,
          'minute': minute,
          'title': title,
          'body': body,
          'payload': payload,
          'scheduleMode': scheduleMode,
        });
        return true;
      };
      NotificationSettingsService.cancelDailyReminderOverride = () async {
        cancelCalled = true;
      };
      NotificationSettingsService.subscribeToTopicOverride = (topic) async {
        subscribedTopics.add(topic);
      };
      NotificationSettingsService.unsubscribeFromTopicOverride = (topic) async {
        unsubscribedTopics.add(topic);
      };
      NotificationSettingsService.scheduleWeeklyInsightOverride = ({
        required bool enabled,
      }) async {
        return true;
      };
      NotificationSettingsService.analyticsLog = [];
    });

    tearDown(() {
      NotificationSettingsService.resetForTesting();
    });

    group('리마인더 활성화 + 메시지 있음', () {
      test('스케줄링이 올바른 파라미터로 호출되어야 한다', () async {
        final messages = [createMessage(0, content: '힘내세요!')];
        final settings = createSettings(
          reminderHour: 8,
          reminderMinute: 30,
        );

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          source: 'user_toggle',
        );

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['hour'], 8);
        expect(scheduleCalls[0]['minute'], 30);
        // 제목은 cheerMeTitles 풀에서 선택됨 (개인화 적용)
        final title = scheduleCalls[0]['title'] as String;
        final allCheerMeTitles = NotificationMessages.cheerMeTitles.map(
          (t) => NotificationMessages.applyNamePersonalization(t, null),
        );
        expect(allCheerMeTitles, contains(title));
        expect(scheduleCalls[0]['body'], '힘내세요!');
        expect(
          scheduleCalls[0]['payload'],
          NotificationSettingsService.reminderPayload,
        );
      });

      test('exact alarm 권한이 있으면 EXACT 모드로 스케줄링해야 한다', () async {
        final messages = [createMessage(0)];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(
          scheduleCalls[0]['scheduleMode'],
          AndroidScheduleMode.exactAllowWhileIdle,
        );
      });

      test('exact alarm 권한 없으면 INEXACT fallback이어야 한다', () async {
        NotificationSettingsService.canScheduleExactAlarmsOverride =
            () async => false;
        final messages = [createMessage(0)];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(
          scheduleCalls[0]['scheduleMode'],
          AndroidScheduleMode.inexactAllowWhileIdle,
        );
      });

      test('스케줄링 성공 시 analytics 이벤트가 기록되어야 한다', () async {
        final messages = [createMessage(0)];
        final settings = createSettings(reminderHour: 21, reminderMinute: 0);

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          source: 'time_change',
        );

        final log = NotificationSettingsService.analyticsLog!;
        expect(log.length, greaterThanOrEqualTo(1));
        expect(log[0]['event'], 'reminder_scheduled');
        expect(log[0]['hour'], 21);
        expect(log[0]['minute'], 0);
        expect(log[0]['source'], 'time_change');
      });

      test('스케줄링 실패 시 실패 analytics 이벤트가 기록되어야 한다', () async {
        NotificationSettingsService.scheduleDailyReminderOverride = ({
          required int hour,
          required int minute,
          required String title,
          String? body,
          String? payload,
          AndroidScheduleMode? scheduleMode,
        }) async {
          scheduleCalls.add({'hour': hour});
          return false; // 실패
        };
        final messages = [createMessage(0)];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        final log = NotificationSettingsService.analyticsLog!;
        expect(log.length, greaterThanOrEqualTo(1));
        expect(log[0]['event'], 'reminder_schedule_failed');
        expect(log[0]['errorType'], 'schedule_returned_false');
      });
    });

    group('순차 모드 nextIndex 계산', () {
      test('순차 모드에서 nextIndex를 반환해야 한다', () async {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        // lastDisplayedIndex=0 → nextIndex = (0+1)%3 = 1
        final settings = createSettings(lastDisplayedIndex: 0);

        final result = await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(result, 1);
      });

      test('마지막 인덱스에서 0으로 래핑해야 한다', () async {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        // lastDisplayedIndex=2 → nextIndex = (2+1)%3 = 0
        final settings = createSettings(lastDisplayedIndex: 2);

        final result = await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(result, 0);
      });

      test('랜덤 모드에서는 현재 인덱스를 유지해야 한다', () async {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        final settings = createSettings(
          mode: MessageRotationMode.random,
          lastDisplayedIndex: 5,
        );

        final result = await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(result, 5); // 변경 없음
      });
    });

    group('리마인더 비활성화', () {
      test('cancelDailyReminder가 호출되어야 한다', () async {
        final settings = createSettings(isReminderEnabled: false);

        await NotificationSettingsService.applySettings(settings);

        expect(cancelCalled, isTrue);
        expect(scheduleCalls, isEmpty);
      });

      test('취소 analytics 이벤트가 기록되어야 한다', () async {
        final settings = createSettings(isReminderEnabled: false);

        await NotificationSettingsService.applySettings(
          settings,
          source: 'user_toggle',
        );

        final log = NotificationSettingsService.analyticsLog!;
        expect(log.length, greaterThanOrEqualTo(1));
        expect(log[0]['event'], 'reminder_cancelled');
        expect(log[0]['source'], 'user_toggle');
      });
    });

    group('메시지 없음 (활성화 상태)', () {
      test('메시지가 없으면 cancel이 호출되어야 한다', () async {
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: [],
        );

        expect(cancelCalled, isTrue);
        expect(scheduleCalls, isEmpty);
      });
    });

    group('FCM 토픽 관리', () {
      test('mindcareTopicEnabled=true면 구독해야 한다', () async {
        final settings = createSettings(
          isReminderEnabled: false,
          isMindcareTopicEnabled: true,
        );

        await NotificationSettingsService.applySettings(settings);

        expect(subscribedTopics, ['mindlog_mindcare']);
        expect(unsubscribedTopics, isEmpty);
      });

      test('mindcareTopicEnabled=false면 구독 해제해야 한다', () async {
        final settings = createSettings(
          isReminderEnabled: false,
          isMindcareTopicEnabled: false,
        );

        await NotificationSettingsService.applySettings(settings);

        expect(unsubscribedTopics, ['mindlog_mindcare']);
        expect(subscribedTopics, isEmpty);
      });

      test('FCM 토픽 구독 실패 시 에러를 삼키고 analytics에 기록해야 한다', () async {
        NotificationSettingsService.subscribeToTopicOverride = (topic) async {
          throw Exception('Network error');
        };
        final settings = createSettings(
          isReminderEnabled: false,
          isMindcareTopicEnabled: true,
        );

        // 예외 없이 완료되어야 함
        final result =
            await NotificationSettingsService.applySettings(settings);

        expect(result, 0); // 정상 반환
        final log = NotificationSettingsService.analyticsLog!;
        final topicError =
            log.where((e) => e['event'] == 'fcm_topic_error').toList();
        expect(topicError, hasLength(1));
        expect(topicError[0]['action'], 'subscribe');
      });
    });

    group('이름 개인화 (userName)', () {
      test('userName이 있으면 메시지 본문이 개인화되어야 한다', () async {
        final messages = [
          createMessage(0, content: '{name}님, 힘내세요!'),
        ];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: '지수',
        );

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['body'], '지수님, 힘내세요!');
      });

      test('userName이 null이면 {name} 패턴이 제거되어야 한다', () async {
        final messages = [
          createMessage(0, content: '{name}님, 힘내세요!'),
        ];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: null,
        );

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['body'], '힘내세요!');
      });

      test('userName이 빈 문자열이면 {name} 패턴이 제거되어야 한다', () async {
        final messages = [
          createMessage(0, content: '{name}님의 하루'),
        ];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: '',
        );

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['body'], '하루');
      });

      test('{name}이 없는 메시지는 변경 없이 전달되어야 한다', () async {
        final messages = [
          createMessage(0, content: '오늘도 화이팅!'),
        ];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: '지수',
        );

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['body'], '오늘도 화이팅!');
      });

      test('userName 미전달(기본값) 시 기존 동작 유지', () async {
        final messages = [
          createMessage(0, content: '{name}님, 좋은 하루!'),
        ];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          // userName 미전달 → null 기본값
        );

        expect(scheduleCalls, hasLength(1));
        // userName=null → {name}님, 패턴 제거
        expect(scheduleCalls[0]['body'], '좋은 하루!');
      });
    });

    group('알림 제목 개인화 (cheerMeTitle)', () {
      test('userName이 있으면 제목에 이름이 포함되어야 한다', () async {
        final messages = [createMessage(0, content: '화이팅!')];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: '지수',
        );

        expect(scheduleCalls, hasLength(1));
        final title = scheduleCalls[0]['title'] as String;
        // cheerMeTitles 풀에서 선택된 제목이어야 함
        final allTitles = NotificationMessages.cheerMeTitles.map(
          (t) => NotificationMessages.applyNamePersonalization(t, '지수'),
        );
        expect(allTitles, contains(title));
        // {name} 패턴이 남아있으면 안 됨
        expect(title, isNot(contains('{name}')));
      });

      test('userName이 null이면 제목에서 {name} 패턴이 제거되어야 한다', () async {
        final messages = [createMessage(0, content: '화이팅!')];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          userName: null,
        );

        expect(scheduleCalls, hasLength(1));
        final title = scheduleCalls[0]['title'] as String;
        expect(title, isNot(contains('{name}')));
        // cheerMeTitles 풀에서 선택된 제목이어야 함
        final allTitles = NotificationMessages.cheerMeTitles.map(
          (t) => NotificationMessages.applyNamePersonalization(t, null),
        );
        expect(allTitles, contains(title));
      });

      test('제목이 cheerMeTitles 풀에서 선택되어야 한다', () async {
        final messages = [createMessage(0, content: '테스트')];
        final settings = createSettings();

        // 10회 반복으로 다양한 제목 선택 확인
        for (var i = 0; i < 10; i++) {
          scheduleCalls.clear();
          await NotificationSettingsService.applySettings(
            settings,
            messages: messages,
            userName: '민수',
          );

          final title = scheduleCalls[0]['title'] as String;
          final allTitles = NotificationMessages.cheerMeTitles.map(
            (t) => NotificationMessages.applyNamePersonalization(t, '민수'),
          );
          expect(allTitles, contains(title), reason: 'title "$title" not in pool');
        }
      });
    });

    group('복합 시나리오', () {
      test('리마인더 + FCM 토픽 동시 설정이 정상 작동해야 한다', () async {
        final messages = [createMessage(0, content: '화이팅!')];
        final settings = createSettings(
          reminderHour: 7,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        );

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
          source: 'app_start',
        );

        // 스케줄링 호출 확인
        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['body'], '화이팅!');

        // FCM 구독 확인
        expect(subscribedTopics, ['mindlog_mindcare']);

        // Analytics 확인
        final log = NotificationSettingsService.analyticsLog!;
        expect(
          log.where((e) => e['event'] == 'reminder_scheduled').length,
          1,
        );
      });

      test('canScheduleExact=null일 때 INEXACT fallback해야 한다', () async {
        NotificationSettingsService.canScheduleExactAlarmsOverride =
            () async => null;
        final messages = [createMessage(0)];
        final settings = createSettings();

        await NotificationSettingsService.applySettings(
          settings,
          messages: messages,
        );

        expect(
          scheduleCalls[0]['scheduleMode'],
          AndroidScheduleMode.inexactAllowWhileIdle,
        );
      });
    });

    group('주간 인사이트 설정', () {
      test('isWeeklyInsightEnabled=true일 때 scheduleWeeklyInsight이 호출되어야 한다', () async {
        final settings = createSettings(
          isReminderEnabled: false,
          isMindcareTopicEnabled: false,
        ).copyWith(isWeeklyInsightEnabled: true);

        await NotificationSettingsService.applySettings(settings);

        // Analytics 확인
        final log = NotificationSettingsService.analyticsLog!;
        expect(
          log.where((e) => e['event'] == 'weekly_insight_scheduled').length,
          1,
          reason: 'weekly_insight_scheduled 이벤트가 기록되어야 함',
        );
      });

      test('isWeeklyInsightEnabled=false일 때 취소 이벤트가 기록되어야 한다', () async {
        final settings = createSettings(
          isReminderEnabled: false,
          isMindcareTopicEnabled: false,
        ).copyWith(isWeeklyInsightEnabled: false);

        await NotificationSettingsService.applySettings(settings);

        // Analytics 확인
        final log = NotificationSettingsService.analyticsLog!;
        expect(
          log.where((e) => e['event'] == 'weekly_insight_cancelled').length,
          1,
          reason: 'weekly_insight_cancelled 이벤트가 기록되어야 함',
        );
      });
    });

    group('emotionAware 모드', () {
      test('recentEmotionScore가 null이면 랜덤 메시지를 선택해야 한다', () {
        final messages = [
          createMessage(0).copyWith(writtenEmotionScore: 3.0),
          createMessage(1).copyWith(writtenEmotionScore: 7.0),
          createMessage(2).copyWith(writtenEmotionScore: 9.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // 100회 반복으로 랜덤 선택 확인
        for (var i = 0; i < 100; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: null,
          );
          expect(result, isNotNull);
          expect(messages, contains(result));
        }
      });

      test('모든 메시지의 writtenEmotionScore가 null이면 동일 가중치로 선택해야 한다', () {
        final messages = [
          createMessage(0),
          createMessage(1),
          createMessage(2),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // 100회 반복으로 다양한 선택 확인
        final selectedIds = <String>{};
        for (var i = 0; i < 100; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.0,
          );
          selectedIds.add(result!.id);
        }

        // 최소 2개 이상 선택되어야 함
        expect(
          selectedIds.length,
          greaterThanOrEqualTo(2),
          reason: '모든 메시지가 동일 가중치로 선택되어야 함',
        );
      });

      test('거리 ≤ 1.0인 메시지는 가중치 3을 가져야 한다', () {
        final messages = [
          createMessage(0, content: '5.0 점수').copyWith(writtenEmotionScore: 5.0),
          createMessage(1, content: '5.5 점수').copyWith(writtenEmotionScore: 5.5),
          createMessage(2, content: '9.0 점수').copyWith(writtenEmotionScore: 9.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=5.2일 때:
        // - msg[0]: 거리 0.2 → 가중치 3
        // - msg[1]: 거리 0.3 → 가중치 3
        // - msg[2]: 거리 3.8 → 가중치 1
        // 총 가중치 7, 5.0/5.5 메시지가 6/7 = ~85% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.2,
          );
          selectedContents.add(result!.content);
        }

        final closeMsgCount = selectedContents
            .where((c) => c == '5.0 점수' || c == '5.5 점수')
            .length;
        final ratio = closeMsgCount / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.70),
          reason: '거리 1.0 이하 메시지가 70% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('거리 ≤ 3.0인 메시지는 가중치 2를 가져야 한다', () {
        final messages = [
          createMessage(0, content: '4.0 점수').copyWith(writtenEmotionScore: 4.0),
          createMessage(1, content: '9.0 점수').copyWith(writtenEmotionScore: 9.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=6.0일 때:
        // - msg[0]: 거리 2.0 → 가중치 2
        // - msg[1]: 거리 3.0 → 가중치 2
        // 동일 가중치이므로 균등 분포
        final selectedContents = <String>[];
        for (var i = 0; i < 500; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 6.0,
          );
          selectedContents.add(result!.content);
        }

        final msg0Count = selectedContents.where((c) => c == '4.0 점수').length;
        final ratio = msg0Count / 500;

        // 동일 가중치이므로 40-60% 범위 (통계적 변동 고려)
        expect(
          ratio,
          greaterThanOrEqualTo(0.35),
          reason: '균등 분포 확인 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
        expect(
          ratio,
          lessThanOrEqualTo(0.65),
          reason: '균등 분포 확인 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('거리 > 3.0인 메시지는 가중치 1을 가져야 한다', () {
        final messages = [
          createMessage(0, content: '2.0 점수').copyWith(writtenEmotionScore: 2.0),
          createMessage(1, content: '9.0 점수').copyWith(writtenEmotionScore: 9.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=6.0일 때:
        // - msg[0]: 거리 4.0 → 가중치 1
        // - msg[1]: 거리 3.0 → 가중치 2
        // 총 가중치 3, 9.0 메시지가 2/3 = ~67% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 6.0,
          );
          selectedContents.add(result!.content);
        }

        final msg1Count = selectedContents.where((c) => c == '9.0 점수').length;
        final ratio = msg1Count / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.55),
          reason: '거리 3.0 이하 메시지가 55% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('writtenEmotionScore가 null인 메시지는 가중치 1을 가져야 한다', () {
        final messages = [
          createMessage(0, content: '점수 없음'),
          createMessage(1, content: '5.0 점수').copyWith(writtenEmotionScore: 5.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=5.0일 때:
        // - msg[0]: null → 가중치 1
        // - msg[1]: 거리 0.0 → 가중치 3
        // 총 가중치 4, 5.0 메시지가 3/4 = 75% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.0,
          );
          selectedContents.add(result!.content);
        }

        final msg1Count = selectedContents.where((c) => c == '5.0 점수').length;
        final ratio = msg1Count / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.65),
          reason: '점수 있는 메시지가 65% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('혼합 메시지(점수 있음/없음)에서 올바른 가중치가 적용되어야 한다', () {
        final messages = [
          createMessage(0, content: '점수 없음 1'),
          createMessage(1, content: '5.0 점수').copyWith(writtenEmotionScore: 5.0),
          createMessage(2, content: '점수 없음 2'),
          createMessage(3, content: '8.0 점수').copyWith(writtenEmotionScore: 8.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=5.5일 때:
        // - msg[0]: null → 가중치 1
        // - msg[1]: 거리 0.5 → 가중치 3
        // - msg[2]: null → 가중치 1
        // - msg[3]: 거리 2.5 → 가중치 2
        // 총 가중치 7, 점수 있는 메시지가 5/7 = ~71% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.5,
          );
          selectedContents.add(result!.content);
        }

        final withScoreCount = selectedContents
            .where((c) => c == '5.0 점수' || c == '8.0 점수')
            .length;
        final ratio = withScoreCount / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.60),
          reason: '점수 있는 메시지가 60% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('거리 경계값 1.0에서 정확히 가중치 3이 적용되어야 한다', () {
        final messages = [
          createMessage(0, content: '정확히 1.0').copyWith(writtenEmotionScore: 4.0),
          createMessage(1, content: '1.1 초과').copyWith(writtenEmotionScore: 6.2),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=5.0일 때:
        // - msg[0]: 거리 1.0 → 가중치 3
        // - msg[1]: 거리 1.2 → 가중치 2
        // 총 가중치 5, msg[0]이 3/5 = 60% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.0,
          );
          selectedContents.add(result!.content);
        }

        final msg0Count = selectedContents.where((c) => c == '정확히 1.0').length;
        final ratio = msg0Count / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.50),
          reason: '거리 1.0 메시지가 50% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('거리 경계값 3.0에서 정확히 가중치 2가 적용되어야 한다', () {
        final messages = [
          createMessage(0, content: '정확히 3.0').copyWith(writtenEmotionScore: 2.0),
          createMessage(1, content: '3.1 초과').copyWith(writtenEmotionScore: 8.2),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // recentEmotionScore=5.0일 때:
        // - msg[0]: 거리 3.0 → 가중치 2
        // - msg[1]: 거리 3.2 → 가중치 1
        // 총 가중치 3, msg[0]이 2/3 = ~67% 비율
        final selectedContents = <String>[];
        for (var i = 0; i < 1000; i++) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: 5.0,
          );
          selectedContents.add(result!.content);
        }

        final msg0Count = selectedContents.where((c) => c == '정확히 3.0').length;
        final ratio = msg0Count / 1000;

        expect(
          ratio,
          greaterThanOrEqualTo(0.55),
          reason: '거리 3.0 메시지가 55% 이상 선택되어야 함 (실제: ${(ratio * 100).toStringAsFixed(1)}%)',
        );
      });

      test('감정 점수가 1.0-10.0 범위의 모든 값에서 동작해야 한다', () {
        final messages = [
          createMessage(0).copyWith(writtenEmotionScore: 1.0),
          createMessage(1).copyWith(writtenEmotionScore: 5.5),
          createMessage(2).copyWith(writtenEmotionScore: 10.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        // 1.0부터 10.0까지 0.5 간격으로 테스트
        for (var score = 1.0; score <= 10.0; score += 0.5) {
          final result = NotificationSettingsService.selectMessage(
            settings,
            messages,
            recentEmotionScore: score,
          );
          expect(result, isNotNull, reason: 'score=$score에서 메시지 선택 실패');
          expect(messages, contains(result), reason: 'score=$score에서 잘못된 메시지 선택');
        }
      });

      test('메시지 1개만 있어도 emotionAware 모드가 동작해야 한다', () {
        final messages = [
          createMessage(0).copyWith(writtenEmotionScore: 5.0),
        ];
        final settings = createSettings(mode: MessageRotationMode.emotionAware);

        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          recentEmotionScore: 7.0,
        );

        expect(result, equals(messages[0]));
      });
    });
  });
}
