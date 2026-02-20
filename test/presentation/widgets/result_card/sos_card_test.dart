import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/sos_card.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// MockUrlLauncherPlatform — 프로젝트 표준 url_launcher 모킹 패턴
///
/// [UrlLauncherPlatform]을 extends하고 [MockPlatformInterfaceMixin]을 사용하여
/// PlatformInterface.verify를 우회합니다.
class MockUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool launchResult = true;
  bool shouldThrow = false;
  String? lastLaunchedUrl;
  int launchCallCount = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    launchCallCount++;
    if (shouldThrow) throw Exception('Mock launch error');
    return launchResult;
  }

  void reset() {
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

  /// SosCard가 세로로 길어서 기본 뷰포트(800x600)에 다 안 들어감
  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
  }

  /// 애니메이션 완료 (AnimationController 1200ms + flutter_animate delay 600ms)
  Future<void> pumpPastAnimations(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// SosCard를 onClose 없이 사용 (result_card 컨텍스트)
  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SosCard())),
    );
  }

  group('SosCard (onClose 없음, result_card 컨텍스트)', () {
    group('렌더링', () {
      testWidgets('공감 아이콘이 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      });

      testWidgets('헤더 텍스트가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('많이 힘드셨군요'), findsOneWidget);
      });

      testWidgets('공감 메시지가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.textContaining('당신은 혼자가 아닙니다'), findsOneWidget);
      });

      testWidgets('자살예방 상담전화 카드가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('자살예방 상담전화'), findsOneWidget);
      });

      testWidgets('정신건강 상담센터 카드가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('정신건강 상담센터'), findsOneWidget);
      });

      testWidgets('onClose 없으면 닫기 버튼이 표시되지 않아야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('다른 내용 작성하기'), findsNothing);
      });

      testWidgets('상담 연결하기 버튼이 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('상담 연결하기'), findsOneWidget);
      });
    });

    group('인터랙션', () {
      testWidgets('자살예방 상담전화 카드 탭 시 109로 전화 연결을 시도해야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('자살예방 상담전화'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:109');
      });

      testWidgets('상담 연결하기 버튼 탭 시 109로 전화 연결을 시도해야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('상담 연결하기'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:109');
      });
    });
  });
}
