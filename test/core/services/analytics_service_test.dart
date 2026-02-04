import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/analytics_service.dart';

import '../../helpers/firebase_test_helpers.dart';

void main() {
  setUpAll(() {
    setupFirebaseCoreMocks();
  });

  group('AnalyticsService', () {
    // AnalyticsService는 static 메서드로 Firebase Analytics를 래핑합니다.
    // 실제 Firebase 호출은 Mock Platform으로 대체되므로 에러 없이 완료되는지 확인합니다.

    group('logDiaryCreated', () {
      test('diary_created 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        // 에러 없이 완료되는지 확인
        await expectLater(
          AnalyticsService.logDiaryCreated(
            contentLength: 100,
            aiCharacterId: 'warmCounselor',
          ),
          completes,
        );
      });

      test('aiCharacterId가 null이어도 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logDiaryCreated(
            contentLength: 50,
            aiCharacterId: null,
          ),
          completes,
        );
      });
    });

    group('logDiaryAnalyzed', () {
      test('diary_analyzed 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logDiaryAnalyzed(
            aiCharacterId: 'realisticCoach',
            sentimentScore: 7,
            energyLevel: 8,
          ),
          completes,
        );
      });
    });

    group('logActionItemCompleted', () {
      test('action_item_completed 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logActionItemCompleted(actionItemText: '산책하기'),
          completes,
        );
      });

      test('50자 이상의 텍스트도 에러 없이 처리되어야 한다', () async {
        final longText = 'a' * 100;
        await expectLater(
          AnalyticsService.logActionItemCompleted(actionItemText: longText),
          completes,
        );
      });
    });

    group('logAiCharacterChanged', () {
      test('ai_character_changed 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logAiCharacterChanged(
            fromCharacterId: 'warmCounselor',
            toCharacterId: 'cheerfulFriend',
          ),
          completes,
        );
      });
    });

    group('logStatisticsViewed', () {
      test('statistics_viewed 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logStatisticsViewed(period: 'weekly'),
          completes,
        );
      });
    });

    group('logReminderScheduled', () {
      test('reminder_scheduled 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logReminderScheduled(
            hour: 21,
            minute: 0,
            source: 'user_toggle',
          ),
          completes,
        );
      });
    });

    group('logReminderCancelled', () {
      test('reminder_cancelled 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logReminderCancelled(source: 'user_toggle'),
          completes,
        );
      });
    });

    group('logReminderScheduleFailed', () {
      test('reminder_schedule_failed 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logReminderScheduleFailed(
            errorType: 'permission_denied',
          ),
          completes,
        );
      });
    });

    group('logMindcareEnabled/Disabled', () {
      test('mindcare_enabled 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(AnalyticsService.logMindcareEnabled(), completes);
      });

      test('mindcare_disabled 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(AnalyticsService.logMindcareDisabled(), completes);
      });
    });

    group('setUserProperty', () {
      test('사용자 속성 설정이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.setUserProperty(name: 'user_type', value: 'premium'),
          completes,
        );
      });

      test('null 값도 에러 없이 설정되어야 한다', () async {
        await expectLater(
          AnalyticsService.setUserProperty(name: 'user_type', value: null),
          completes,
        );
      });
    });

    group('logScreenView', () {
      test('screen_view 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(
          AnalyticsService.logScreenView('HomeScreen'),
          completes,
        );
      });
    });

    group('logAppOpen', () {
      test('app_open 이벤트 로깅이 에러 없이 완료되어야 한다', () async {
        await expectLater(AnalyticsService.logAppOpen(), completes);
      });
    });

    group('observer', () {
      test('observer getter는 null이 아니어야 한다 (initialize 후)', () async {
        await AnalyticsService.initialize();
        // observer는 initialize 후 설정됨
        expect(AnalyticsService.observer, isNotNull);
      });
    });
  });
}
