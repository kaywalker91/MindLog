import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/result_card/sos_card.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// MockUrlLauncherPlatform — 프로젝트 표준 url_launcher 모킹 패턴
///
/// [UrlLauncherPlatform]을 extends하고 [MockPlatformInterfaceMixin]을 사용하여
/// PlatformInterface.verify를 우회합니다.
class MockUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool canLaunchResult = true;
  bool launchResult = true;
  bool shouldThrow = false;
  String? lastLaunchedUrl;
  int launchCallCount = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    lastLaunchedUrl = url;
    if (shouldThrow) throw Exception('Mock canLaunch error');
    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    launchCallCount++;
    if (shouldThrow) throw Exception('Mock launch error');
    return launchResult;
  }

  void reset() {
    canLaunchResult = true;
    launchResult = true;
    shouldThrow = false;
    lastLaunchedUrl = null;
    launchCallCount = 0;
  }
}

void main() {
  late MockUrlLauncherPlatform mockUrlLauncher;

  setUpAll(() {
    // flutter_animate 테스트 환경 설정
    Animate.restartOnHotReload = false;
  });

  setUp(() {
    mockUrlLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncher;
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SOSCard())),
    );
  }

  group('SOSCard (result_card)', () {
    group('렌더링', () {
      testWidgets('경고 아이콘이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('헤더 텍스트가 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('전문가의 도움이 필요할 수 있어요'), findsOneWidget);
      });

      testWidgets('설명 텍스트가 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('혼자서 너무 힘들어하지 마세요'), findsOneWidget);
        expect(find.textContaining('전문가가 기다리고 있습니다'), findsOneWidget);
      });

      testWidgets('자살예방상담전화 버튼이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('24시간 자살예방상담전화 (109)'), findsOneWidget);
      });

      testWidgets('정신건강상담전화 버튼이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('정신건강상담전화'), findsOneWidget);
      });

      testWidgets('전화 아이콘이 버튼에 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
        expect(find.byIcon(Icons.support_agent), findsOneWidget);
      });
    });

    group('인터랙션', () {
      testWidgets('자살예방상담전화 버튼 탭 시 109로 전화 연결을 시도해야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('24시간 자살예방상담전화 (109)'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:109');
      });

      testWidgets('정신건강상담전화 버튼 탭 시 1577-0199로 전화 연결을 시도해야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('정신건강상담전화'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:1577-0199');
      });

      testWidgets('canLaunchUrl이 false면 launchUrl이 호출되지 않아야 한다', (
        tester,
      ) async {
        mockUrlLauncher.canLaunchResult = false;

        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('24시간 자살예방상담전화 (109)'));
        await tester.pump();

        // canLaunch는 호출되지만, launchUrl은 호출되지 않음
        // SOSCard의 _EmergencyButton이 canLaunchUrl 체크를 함
        expect(mockUrlLauncher.launchCallCount, 0);
      });
    });
  });
}
