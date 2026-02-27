import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/presentation/providers/app_info_provider.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/ui_state_providers.dart';
import 'package:mindlog/presentation/widgets/weekly_insight_guide_dialog.dart';
import 'package:mindlog/presentation/widgets/settings/settings_sections.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/mock_repositories.dart';

/// Settings Section 위젯 테스트
///
/// 분해된 5개 Section 위젯의 렌더링 및 상호작용 테스트
void main() {
  group('AppInfoSection', () {
    late ProviderContainer container;

    Widget buildTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AppInfoSection())),
        ),
      );
    }

    group('렌더링', () {
      testWidgets('앱 정보 섹션 헤더가 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async =>
                  const AppVersionInfo(version: '1.4.31', buildNumber: '123'),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('앱 정보'), findsOneWidget);
      });

      testWidgets('앱 버전 항목이 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async =>
                  const AppVersionInfo(version: '1.4.31', buildNumber: '123'),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('앱 버전'), findsOneWidget);
        expect(find.text('v1.4.31 (123)'), findsOneWidget);
      });

      testWidgets('업데이트 확인 항목이 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async =>
                  const AppVersionInfo(version: '1.4.31', buildNumber: '123'),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('업데이트 확인'), findsOneWidget);
      });

      testWidgets('개인정보 처리방침 항목이 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async =>
                  const AppVersionInfo(version: '1.4.31', buildNumber: '123'),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('개인정보 처리방침'), findsOneWidget);
      });
    });

    group('로딩 상태', () {
      testWidgets('버전 정보 로딩 중 상태가 표시되어야 한다', (tester) async {
        // Arrange - Completer를 사용하여 로딩 상태 유지
        final completer = Completer<AppVersionInfo>();
        container = ProviderContainer(
          overrides: [appInfoProvider.overrideWith((ref) => completer.future)],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        // 로딩 상태 확인 (pump() 한 번만)

        // Assert
        expect(find.text('불러오는 중...'), findsOneWidget);

        // 테스트 종료 전 future 완료 (타이머 경고 방지)
        completer.complete(
          const AppVersionInfo(version: '1.0.0', buildNumber: '1'),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('버전 정보 로딩 실패 시 에러 메시지가 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith((ref) async {
              throw Exception('Platform error');
            }),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('버전 확인 실패'), findsOneWidget);
      });
    });

    group('아이콘', () {
      testWidgets('각 항목에 올바른 아이콘이 표시되어야 한다', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) async =>
                  const AppVersionInfo(version: '1.4.31', buildNumber: '123'),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.byIcon(Icons.system_update), findsOneWidget);
        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      });
    });

    tearDown(() {
      container.dispose();
    });
  });

  group('EmotionCareSection', () {
    late ProviderContainer container;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockSettingsRepo = MockSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      mockSettingsRepo.reset();
      container.dispose();
    });

    testWidgets('AI 캐릭터 섹션이 렌더링되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockCharacter(AiCharacter.warmCounselor);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: EmotionCareSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('감정 케어'), findsOneWidget);
      expect(find.text('AI 캐릭터'), findsOneWidget);
      expect(find.text('내 이름'), findsOneWidget);
    });

    testWidgets('AI 캐릭터 라벨이 올바르게 표시되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockCharacter(AiCharacter.realisticCoach);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: EmotionCareSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 현실적인 코치 캐릭터 이름 표시
      expect(find.text(AiCharacter.realisticCoach.displayName), findsOneWidget);
    });
  });

  group('NotificationSection', () {
    late ProviderContainer container;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockSettingsRepo = MockSettingsRepository();

      NotificationSettingsService.resetForTesting();
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
        dynamic scheduleMode,
      }) async => true;
      NotificationSettingsService.cancelDailyReminderOverride = () async {};
      NotificationSettingsService.subscribeToTopicOverride = (_) async {};
      NotificationSettingsService.unsubscribeFromTopicOverride = (_) async {};
      NotificationSettingsService.scheduleWeeklyInsightOverride =
          ({required bool enabled}) async => true;
      NotificationSettingsService.analyticsLog = [];

      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      mockSettingsRepo.reset();
      container.dispose();
      NotificationSettingsService.resetForTesting();
    });

    testWidgets('알림 섹션이 렌더링되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockNotificationSettings(
        NotificationSettings.defaults(),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('알림'), findsOneWidget);
      expect(find.text('Cheer Me — 자기 응원'), findsOneWidget);
      expect(find.text('응원 메시지 관리'), findsOneWidget);
      expect(find.text('메시지 순서'), findsOneWidget);
      expect(find.text('알림 시간'), findsOneWidget);
      expect(find.text('테스트 알림 보내기'), findsOneWidget);
      expect(find.text('마음케어'), findsOneWidget);
    });

    testWidgets('리마인더 토글 상태가 올바르게 표시되어야 한다', (tester) async {
      // Arrange - 리마인더 비활성화 상태
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Switch 위젯이 OFF 상태
      final switchFinder = find.byType(Switch).first;
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, false);
    });

    testWidgets('알림 섹션이 2개의 AccentSettingsCard로 분리되어 렌더링되어야 한다', (
      tester,
    ) async {
      // Arrange
      mockSettingsRepo.setMockNotificationSettings(
        NotificationSettings.defaults(),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 2개의 AccentSettingsCard가 존재 (Cheer Me + 마음케어)
      // _AccentSettingsCard는 ClipRRect를 사용하므로 이를 통해 확인
      expect(find.byType(ClipRRect), findsAtLeast(2));

      // 두 섹션의 타이틀이 모두 존재하는지 확인
      expect(find.text('Cheer Me — 자기 응원'), findsOneWidget);
      expect(find.text('마음케어'), findsOneWidget);
    });

    testWidgets('마음케어 비활성화 시 테스트 알림이 비활성화되어야 한다', (tester) async {
      // Arrange - 마음케어 비활성화 상태
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 테스트 알림 항목이 존재
      final testAlertText = find.text('테스트 알림 보내기');
      expect(testAlertText, findsOneWidget);

      // 테스트 알림 항목의 Text 위젯 확인 - 비활성화 시 색상이 적용되어 있음
      final textWidget = tester.widget<Text>(testAlertText);
      // 비활성화 시 titleColor(outline)가 적용됨 → style.color가 null이 아님
      expect(textWidget.style?.color, isNotNull);
    });

    testWidgets('마음케어 활성화 시 테스트 알림이 활성화되어야 한다', (tester) async {
      // Arrange - 마음케어 활성화 상태
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: true,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
        ),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 테스트 알림 항목이 존재
      expect(find.text('테스트 알림 보내기'), findsOneWidget);
    });

    testWidgets('주간 인사이트 첫 활성화 시 가이드 다이얼로그가 표시되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
          isWeeklyInsightEnabled: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('주간 감정 인사이트'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(WeeklyInsightGuideDialog), findsOneWidget);
    });

    testWidgets('주간 인사이트 가이드를 이미 본 경우 다이얼로그가 표시되지 않아야 한다', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'weekly_insight_first_activation_shown': true,
      });
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
          isWeeklyInsightEnabled: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('주간 감정 인사이트'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(WeeklyInsightGuideDialog), findsNothing);
    });

    testWidgets('주간 인사이트 가이드에서 통계 보기를 누르면 통계 탭/주간 기간으로 전환되어야 한다', (
      tester,
    ) async {
      // Arrange
      mockSettingsRepo.setMockNotificationSettings(
        const NotificationSettings(
          isReminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 0,
          isMindcareTopicEnabled: true,
          isWeeklyInsightEnabled: false,
        ),
      );
      container.read(selectedTabIndexProvider.notifier).state = 2;
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.month;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('주간 감정 인사이트'));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyInsightGuideDialog), findsOneWidget);

      await tester.tap(find.text('통계 보기'));
      await tester.pumpAndSettle();

      // Assert
      expect(container.read(selectedTabIndexProvider), 1);
      expect(
        container.read(selectedStatisticsPeriodProvider),
        StatisticsPeriod.week,
      );
    });
  });

  group('DataManagementSection', () {
    late ProviderContainer container;
    late MockDiaryRepository mockDiaryRepo;

    setUp(() {
      mockDiaryRepo = MockDiaryRepository();
      container = ProviderContainer(
        overrides: [diaryRepositoryProvider.overrideWithValue(mockDiaryRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('데이터 관리 섹션이 렌더링되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: DataManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('데이터 관리'), findsOneWidget);
      expect(find.text('모든 일기 삭제'), findsOneWidget);
    });

    testWidgets('삭제 버튼 탭 시 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: DataManagementSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 삭제 버튼 탭
      await tester.tap(find.text('모든 일기 삭제'));
      await tester.pumpAndSettle();

      // Assert - 확인 다이얼로그 표시
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  group('SupportSection', () {
    testWidgets('지원 섹션이 렌더링되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: SupportSection())),
        ),
      );

      // Assert
      expect(find.text('지원'), findsOneWidget);
      expect(find.text('도움말'), findsOneWidget);
      expect(find.text('문의하기'), findsOneWidget);
    });

    testWidgets('도움말 탭 시 다이얼로그가 표시되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: SupportSection())),
        ),
      );

      // 도움말 탭
      await tester.tap(find.text('도움말'));
      await tester.pumpAndSettle();

      // Assert - HelpDialog 표시
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
