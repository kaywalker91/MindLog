import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/sos_card.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// MockUrlLauncherPlatform — url_launcher 플랫폼 모킹
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
  late bool onCloseCalled;

  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  setUp(() {
    mockUrlLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncher;
    onCloseCalled = false;
  });

  /// SosCard가 세로로 길어서 기본 뷰포트(800x600)에 다 안 들어감
  /// 모든 테스트에서 뷰포트를 확장해서 전체 위젯이 보이도록 함
  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
  }

  /// 모든 애니메이션 완료
  /// AnimationController duration=1200ms + flutter_animate delay 600ms + duration 400ms
  /// = 최대 1200ms, pump를 여러 번 나눠서 충분히 진행
  Future<void> pumpPastAnimations(WidgetTester tester) async {
    // 전체 애니메이션이 완료되도록 충분히 pump
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Widget buildTestWidget({VoidCallback? onClose}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SosCard(onClose: onClose ?? () => onCloseCalled = true),
        ),
      ),
    );
  }

  group('SosCard (메인)', () {
    group('렌더링', () {
      testWidgets('공감 헤더 텍스트가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('많이 힘드셨군요'), findsOneWidget);
      });

      testWidgets('부제목이 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('당신의 마음을 들었어요'), findsOneWidget);
      });

      testWidgets('공감 메시지가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.textContaining('당신은 혼자가 아닙니다'), findsOneWidget);
      });

      testWidgets('잠시 쉬어가도 괜찮아요 텍스트가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('잠시 쉬어가도 괜찮아요'), findsOneWidget);
      });

      testWidgets('자살예방 상담전화 연락처가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('자살예방 상담전화'), findsOneWidget);
        expect(find.text('24시간 무료 상담 (109)'), findsOneWidget);
      });

      testWidgets('정신건강 상담센터 연락처가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('정신건강 상담센터'), findsOneWidget);
        expect(find.text('전문가 상담'), findsOneWidget);
      });

      testWidgets('긴급 배지가 자살예방 상담전화에 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('긴급'), findsOneWidget);
      });

      testWidgets('안내 메시지가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.textContaining('다른 내용으로 마음을 기록'), findsOneWidget);
      });

      testWidgets('다른 내용 작성하기 버튼이 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.text('다른 내용 작성하기'), findsOneWidget);
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
      testWidgets('다른 내용 작성하기 탭 시 onClose가 호출되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('다른 내용 작성하기'));
        await tester.pump();

        expect(onCloseCalled, isTrue);
      });

      testWidgets('상담 연결하기 버튼 탭 시 109로 전화를 시도해야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('상담 연결하기'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:109');
        expect(mockUrlLauncher.launchCallCount, 1);
      });

      testWidgets('자살예방 상담전화 카드 탭 시 109로 전화를 시도해야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('자살예방 상담전화'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:109');
      });

      testWidgets('정신건강 상담센터 카드 탭 시 1577-0199로 전화를 시도해야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('정신건강 상담센터'));
        await tester.pump();

        expect(mockUrlLauncher.lastLaunchedUrl, 'tel:1577-0199');
      });
    });

    group('레이아웃', () {
      testWidgets('최대 너비 600px 제약이 적용되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        final constrainedBoxFinder = find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxWidth == 600,
        );
        expect(constrainedBoxFinder, findsOneWidget);
      });
    });

    group('에러 처리', () {
      testWidgets('전화 연결 실패 시 SnackBar가 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());
        mockUrlLauncher.shouldThrow = true;

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        await tester.tap(find.text('자살예방 상담전화'));
        await tester.pump(); // tap 처리
        await tester.pump(); // SnackBar 표시

        expect(find.text('통화 연결에 실패했습니다.'), findsOneWidget);
      });
    });

    group('아이콘', () {
      testWidgets('하트 아이콘이 공감 헤더에 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      });

      testWidgets('spa 아이콘이 공감 메시지에 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      });

      testWidgets('전화 아이콘이 연락처 카드에 표시되어야 한다', (tester) async {
        await setLargeViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await pumpPastAnimations(tester);

        expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
        expect(find.byIcon(Icons.psychology), findsOneWidget);
        expect(find.byIcon(Icons.phone), findsNWidgets(2));
      });
    });
  });
}
