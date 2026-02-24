import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/notification_scheduler_impl.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// NotificationSchedulerImpl + NotificationSettingsService 통합 테스트
///
/// TASK-003 (REQ-064): EmotionAware UseCase 통합 테스트 (알림 스케줄러 연계)
/// - NotificationSchedulerImpl.apply() → NotificationSettingsService.applySettings() 위임 검증
/// - recentEmotionScore 파라미터의 end-to-end 전파 검증
/// - emotionAware 모드에서 감정 근접 메시지가 스케줄링됨을 검증
void main() {
  const scheduler = NotificationSchedulerImpl();

  // 테스트 픽스처 팩토리
  SelfEncouragementMessage makeMsg(
    String id,
    String content, {
    double? score,
  }) {
    return SelfEncouragementMessage(
      id: id,
      content: content,
      createdAt: DateTime(2026, 1, 1),
      displayOrder: 0,
      writtenEmotionScore: score,
    );
  }

  NotificationSettings makeSettings({
    bool isEnabled = true,
    MessageRotationMode mode = MessageRotationMode.emotionAware,
    int lastDisplayedIndex = 0,
  }) {
    return NotificationSettings(
      isReminderEnabled: isEnabled,
      reminderHour: 20,
      reminderMinute: 0,
      isMindcareTopicEnabled: false,
      rotationMode: mode,
      lastDisplayedIndex: lastDisplayedIndex,
    );
  }

  // 스케줄링 호출 기록용 콜렉터
  late List<Map<String, dynamic>> scheduleCalls;

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    NotificationSettingsService.resetForTesting();
    scheduleCalls = [];

    NotificationSettingsService.areNotificationsEnabledOverride =
        () async => true;
    NotificationSettingsService.canScheduleExactAlarmsOverride =
        () async => true;
    NotificationSettingsService.isIgnoringBatteryOverride = () async => true;
    NotificationSettingsService.scheduleDailyReminderOverride = ({
      required int hour,
      required int minute,
      required String title,
      String? body,
      String? payload,
      AndroidScheduleMode? scheduleMode,
    }) async {
      scheduleCalls.add({'hour': hour, 'minute': minute, 'body': body});
      return true;
    };
    NotificationSettingsService.cancelDailyReminderOverride = () async {};
    NotificationSettingsService.subscribeToTopicOverride = (_) async {};
    NotificationSettingsService.unsubscribeFromTopicOverride = (_) async {};
    NotificationSettingsService.scheduleWeeklyInsightOverride =
        ({required bool enabled}) async => true;
    NotificationSettingsService.analyticsLog = [];
  });

  tearDown(() {
    NotificationSettingsService.resetForTesting();
  });

  group('NotificationSchedulerImpl (통합)', () {
    group('기본 위임 동작', () {
      test('apply()는 올바른 시간 파라미터로 스케줄링을 호출한다', () async {
        final settings = NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 8,
          reminderMinute: 30,
          isMindcareTopicEnabled: false,
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 0,
        );
        final messages = [makeMsg('m1', '아침 응원 메시지')];

        await scheduler.apply(settings, messages: messages, source: 'test');

        expect(scheduleCalls, hasLength(1));
        expect(scheduleCalls[0]['hour'], 8);
        expect(scheduleCalls[0]['minute'], 30);
        expect(scheduleCalls[0]['body'], '아침 응원 메시지');
      });

      test('isReminderEnabled=false이면 스케줄링을 취소하고 body를 전달하지 않는다', () async {
        bool cancelCalled = false;
        NotificationSettingsService.cancelDailyReminderOverride =
            () async => cancelCalled = true;

        final settings = makeSettings(isEnabled: false);
        final messages = [makeMsg('m1', '취소용 메시지')];

        await scheduler.apply(settings, messages: messages);

        expect(cancelCalled, isTrue);
        expect(scheduleCalls, isEmpty);
      });

      test('source 파라미터가 analyticsLog에 기록된다', () async {
        final settings = makeSettings(mode: MessageRotationMode.sequential);
        final messages = [makeMsg('m1', '소스 테스트')];

        await scheduler.apply(
          settings,
          messages: messages,
          source: 'app_start',
        );

        final log = NotificationSettingsService.analyticsLog!;
        final scheduleEvent = log.firstWhere(
          (e) => e['event'] == 'reminder_scheduled',
          orElse: () => {},
        );
        expect(scheduleEvent['source'], 'app_start');
      });
    });

    group('emotionAware 모드: recentEmotionScore 전파', () {
      test(
        'recentEmotionScore=null이면 메시지를 스케줄링한다 (랜덤 폴백)',
        () async {
          final settings = makeSettings();
          final messages = [makeMsg('m1', '감정 없음 메시지')];

          await scheduler.apply(settings, messages: messages);

          // score 없어도 단일 메시지는 항상 스케줄링됨
          expect(scheduleCalls, hasLength(1));
          expect(scheduleCalls[0]['body'], '감정 없음 메시지');
        },
      );

      test(
        'recentEmotionScore와 거리≤1인 메시지(1개)가 항상 선택된다',
        () async {
          // 단일 메시지: writtenEmotionScore=5.0, recentEmotionScore=5.0 → distance=0 → weight=3
          // Random().nextInt(3) 결과와 무관하게 pick - 3 < 0 → 항상 첫 번째 메시지 선택
          final settings = makeSettings();
          final messages = [makeMsg('close', '감정 일치 메시지', score: 5.0)];

          await scheduler.apply(
            settings,
            messages: messages,
            recentEmotionScore: 5.0,
          );

          expect(scheduleCalls, hasLength(1));
          expect(scheduleCalls[0]['body'], '감정 일치 메시지');
        },
      );

      test(
        'writtenEmotionScore 없는 메시지(1개)도 스케줄링된다 (weight=1 폴백)',
        () async {
          // score 없는 메시지는 weight=1로 처리; 단일 메시지라면 항상 선택
          final settings = makeSettings();
          final messages = [makeMsg('noscore', '점수 없는 메시지')];

          await scheduler.apply(
            settings,
            messages: messages,
            recentEmotionScore: 7.0,
          );

          expect(scheduleCalls, hasLength(1));
          expect(scheduleCalls[0]['body'], '점수 없는 메시지');
        },
      );

      test(
        'messages가 비어 있으면 스케줄링이 호출되지 않는다',
        () async {
          final settings = makeSettings();

          await scheduler.apply(
            settings,
            messages: const [],
            recentEmotionScore: 5.0,
          );

          expect(scheduleCalls, isEmpty);
        },
      );
    });

    group('sequential 모드: 인덱스 진행', () {
      test('apply() 결과로 다음 인덱스를 반환한다', () async {
        final settings = makeSettings(
          mode: MessageRotationMode.sequential,
          lastDisplayedIndex: 0,
        );
        final messages = [
          makeMsg('m0', '메시지0'),
          makeMsg('m1', '메시지1'),
          makeMsg('m2', '메시지2'),
        ];

        final nextIndex = await scheduler.apply(settings, messages: messages);

        // sequential: currentIndex=0으로 m0 선택 → nextIndex = (0+1) % 3 = 1
        expect(nextIndex, 1);
        expect(scheduleCalls[0]['body'], '메시지0');
      });

      test('마지막 인덱스에서 wrap-around된다', () async {
        final settings = makeSettings(
          mode: MessageRotationMode.sequential,
          lastDisplayedIndex: 2,
        );
        final messages = [
          makeMsg('m0', '메시지0'),
          makeMsg('m1', '메시지1'),
          makeMsg('m2', '메시지2'),
        ];

        final nextIndex = await scheduler.apply(settings, messages: messages);

        // sequential: currentIndex=2로 m2 선택 → nextIndex = (2+1) % 3 = 0
        expect(nextIndex, 0);
        expect(scheduleCalls[0]['body'], '메시지2');
      });
    });
  });
}
