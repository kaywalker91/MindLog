import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/notification_diagnostic_service.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/presentation/widgets/settings/notification_diagnostic_widget.dart';

void main() {
  double contrastRatio(Color foreground, Color background) {
    final lighter =
        foreground.computeLuminance() > background.computeLuminance()
        ? foreground
        : background;
    final darker = lighter == foreground ? background : foreground;
    return (lighter.computeLuminance() + 0.05) /
        (darker.computeLuminance() + 0.05);
  }

  tearDown(() {
    NotificationDiagnosticService.resetForTesting();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SingleChildScrollView(child: NotificationDiagnosticWidget()),
      ),
    );
  }

  Widget buildTestWidgetWithWidth(double width) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const Scaffold(
          body: SingleChildScrollView(child: NotificationDiagnosticWidget()),
        ),
      ),
    );
  }

  Color iconColorOf(WidgetTester tester, IconData iconData) {
    final icon = tester.widget<Icon>(find.byIcon(iconData));
    return icon.color!;
  }

  NotificationDiagnosticData createData({
    List<({int id, String? title})> pendingNotifications = const [],
    bool? canScheduleExact = true,
    bool isIgnoringBattery = true,
    bool? notificationsEnabled = true,
    String timezoneName = 'Asia/Seoul',
  }) {
    return NotificationDiagnosticData(
      pendingNotifications: pendingNotifications,
      canScheduleExact: canScheduleExact,
      isIgnoringBattery: isIgnoringBattery,
      notificationsEnabled: notificationsEnabled,
      timezoneName: timezoneName,
    );
  }

  group('NotificationDiagnosticWidget', () {
    group('접근성 대비', () {
      test('상태칩/배너 톤이 라이트·다크에서 AA 대비(4.5:1) 이상이어야 한다', () {
        final lightPairs = [
          (fg: const Color(0xFF1D5E2D), bg: const Color(0xFFE8F3EA)),
          (fg: const Color(0xFF8A4E00), bg: const Color(0xFFFFF1E2)),
        ];
        final darkPairs = [
          (fg: const Color(0xFFA5D6A7), bg: const Color(0xFF22362A)),
          (fg: const Color(0xFFFFCC80), bg: const Color(0xFF3A2C1D)),
        ];

        for (final pair in [...lightPairs, ...darkPairs]) {
          expect(contrastRatio(pair.fg, pair.bg), greaterThanOrEqualTo(4.5));
        }
      });
    });

    group('로딩 상태', () {
      testWidgets('로딩 중 텍스트가 표시되어야 한다', (tester) async {
        final completer = Completer<NotificationDiagnosticData>();
        NotificationDiagnosticService.collectOverride = () => completer.future;

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('알림 상태를 확인하고 있어요...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete to avoid pending timer
        completer.complete(createData());
        await tester.pumpAndSettle();
      });
    });

    group('모두 정상 상태', () {
      testWidgets('정상 요약 배너가 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('모든 알림이 정상이에요'), findsOneWidget);
      });

      testWidgets('4개 항목이 모두 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('알림 예약'), findsOneWidget);
        expect(find.text('정확한 알람'), findsOneWidget);
        expect(find.text('배터리 최적화'), findsOneWidget);
        expect(find.text('시간대'), findsOneWidget);
      });

      testWidgets('정상 상태 칩이 올바르게 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('1개 예약됨'), findsOneWidget);
        expect(find.text('허용됨'), findsOneWidget);
        expect(find.text('제외됨'), findsOneWidget);
        expect(find.text('Asia/Seoul'), findsOneWidget);
      });
    });

    group('문제 있는 상태', () {
      testWidgets('경고 요약 배너가 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          canScheduleExact: false,
          isIgnoringBattery: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('2개 항목을 확인해주세요'), findsOneWidget);
      });

      testWidgets('정확한 알람 문제 시 설정 액션 버튼이 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          canScheduleExact: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('권한 필요'), findsNothing); // action chip replaces status
        expect(find.text('설정'), findsOneWidget);
      });

      testWidgets('배터리 문제 시 해제 액션 버튼이 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          isIgnoringBattery: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('활성'), findsNothing); // action chip replaces status
        expect(find.text('해제'), findsOneWidget);
      });

      testWidgets('알림 예약 없음 시 경고 칩이 표시되어야 한다 (액션 버튼 없음)', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: []);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('없음'), findsOneWidget);
        expect(find.text('알림 예약을 확인해주세요'), findsOneWidget);
      });
    });

    group('시간대', () {
      testWidgets('시간대 이름이 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          timezoneName: 'America/New_York',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('America/New_York'), findsOneWidget);
      });

      testWidgets('시간대 상태 칩은 중립 톤으로 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          timezoneName: 'Asia/Seoul',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final context = tester.element(
          find.byType(NotificationDiagnosticWidget),
        );
        final expectedNeutralChipForeground = Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.90);
        final timezoneText = tester.widget<Text>(find.text('Asia/Seoul'));
        expect(timezoneText.style?.color, expectedNeutralChipForeground);
      });
    });

    group('색상 계층', () {
      testWidgets('상태 행 아이콘은 모두 동일한 중립 톤이어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [],
          canScheduleExact: false,
          isIgnoringBattery: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final context = tester.element(
          find.byType(NotificationDiagnosticWidget),
        );
        final expectedNeutralIconColor = Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.86);
        expect(
          iconColorOf(tester, Icons.notifications_active_outlined),
          expectedNeutralIconColor,
        );
        expect(
          iconColorOf(tester, Icons.alarm_on_outlined),
          expectedNeutralIconColor,
        );
        expect(
          iconColorOf(tester, Icons.battery_saver_outlined),
          expectedNeutralIconColor,
        );
        expect(
          iconColorOf(tester, Icons.language_outlined),
          expectedNeutralIconColor,
        );
      });
    });

    group('레이아웃 폭', () {
      testWidgets('320/360/412dp에서 overflow 없이 렌더링되어야 한다', (tester) async {
        for (final width in [320.0, 360.0, 412.0]) {
          NotificationDiagnosticService.collectOverride = () async =>
              createData(
                pendingNotifications: [],
                canScheduleExact: false,
                isIgnoringBattery: false,
                timezoneName: 'Asia/Seoul',
              );

          await tester.pumpWidget(buildTestWidgetWithWidth(width));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(NotificationDiagnosticWidget), findsOneWidget);
        }
      });
    });

    group('에모지 및 ID 노출 금지', () {
      testWidgets('에모지 텍스트가 포함되지 않아야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async => createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          canScheduleExact: false,
          isIgnoringBattery: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // No emoji text should be present
        expect(find.textContaining('\u2705'), findsNothing);
        expect(find.textContaining('\u26a0'), findsNothing);
      });

      testWidgets('내부 ID가 노출되지 않아야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('ID: 1001'), findsNothing);
        expect(find.textContaining('1001'), findsNothing);
      });
    });

    group('새로고침', () {
      testWidgets('새로고침 버튼이 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('새로고침 탭 시 데이터를 다시 로드해야 한다', (tester) async {
        var callCount = 0;
        NotificationDiagnosticService.collectOverride = () async {
          callCount++;
          return createData(
            pendingNotifications: [(id: 1001, title: 'Cheer Me')],
          );
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        expect(callCount, 1);

        // Tap refresh
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(callCount, 2);
      });
    });

    group('접기 버튼', () {
      testWidgets('접기 버튼이 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('접기 버튼 탭 시 상세가 숨겨지고 다시 펼칠 수 있어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('알림 예약'), findsOneWidget);
        expect(find.text('모든 알림이 정상이에요'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.expand_less));
        await tester.pumpAndSettle();

        expect(find.text('알림 예약'), findsNothing);
        expect(find.text('모든 알림이 정상이에요'), findsNothing);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);

        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('알림 예약'), findsOneWidget);
        expect(find.text('모든 알림이 정상이에요'), findsOneWidget);
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });
    });

    group('헤더', () {
      testWidgets('알림 상태 헤더가 표시되어야 한다', (tester) async {
        NotificationDiagnosticService.collectOverride = () async =>
            createData(pendingNotifications: [(id: 1001, title: 'Cheer Me')]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('알림 상태'), findsOneWidget);
        expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
      });
    });
  });
}
