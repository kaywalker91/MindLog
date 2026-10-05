import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/core/theme/app_colors.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/usecases/secret/set_secret_pin_usecase.dart';
import 'package:mindlog/presentation/providers/secret_diary_providers.dart';
import 'package:mindlog/presentation/screens/secret_pin_setup_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

class _HostScreen extends StatelessWidget {
  const _HostScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.push('/setup'),
          child: const Text('Open Setup'),
        ),
      ),
    );
  }
}

Widget _buildHarness({required MockSecretPinRepository mockPinRepo}) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(path: '/host', builder: (context, state) => const _HostScreen()),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SecretPinSetupScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      setSecretPinUseCaseProvider.overrideWithValue(
        SetSecretPinUseCase(mockPinRepo),
      ),
      hasPinProvider.overrideWith((ref) async => false),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

Future<void> _openSetup(WidgetTester tester) async {
  await tester.tap(find.text('Open Setup'));
  await tester.pumpAndSettle();
}

Future<void> _tapPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    final keypadDigit = find.descendant(
      of: find.byKey(const Key('secret_pin_keypad')),
      matching: find.text(digit),
    );
    expect(keypadDigit, findsOneWidget);
    await tester.tap(keypadDigit);
    await tester.pump();
  }
  await tester.pump();
}

// Small viewports scroll the keypad; bring each key into the safe area first.
Future<void> _tapPinVisible(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    final key = find.descendant(
      of: find.byKey(const Key('secret_pin_keypad')),
      matching: find.text(digit),
    );
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    expect(key.hitTestable(), findsOneWidget);
    expect(tester.getRect(key).bottom, lessThanOrEqualTo(480 - 48));
    await tester.tap(key);
    await tester.pump();
  }
  await tester.pump();
}

int _filledDotCount(WidgetTester tester) {
  final dots = tester.widgetList<AnimatedContainer>(
    find.descendant(
      of: find.byKey(const Key('secret_pin_dot_row')),
      matching: find.byType(AnimatedContainer),
    ),
  );

  return dots.where((dot) {
    final decoration = dot.decoration as BoxDecoration?;
    return decoration?.color == AppColors.statsPrimaryDark;
  }).length;
}

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
    registerMockFallbackValues();
  });

  group('SecretPinSetupScreen', () {
    testWidgets('작은 화면에서 마지막 숫자와 삭제 키까지 스크롤하고 조작해야 한다', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 48);
      addTearDown(tester.view.reset);
      final repo = MockSecretPinRepository();
      await tester.pumpWidget(_buildHarness(mockPinRepo: repo));
      await _openSetup(tester);
      await tester.pumpAndSettle();
      final zero = find.descendant(
        of: find.byKey(const Key('secret_pin_keypad')),
        matching: find.text('0'),
      );
      await tester.ensureVisible(zero);
      await tester.pumpAndSettle();
      expect(zero.hitTestable(), findsOneWidget);
      expect(tester.getRect(zero).bottom, lessThanOrEqualTo(480 - 48));
      await tester.tap(zero);
      await tester.pump();
      final erase = find.byIcon(Icons.backspace_outlined);
      await tester.ensureVisible(erase);
      await tester.tap(erase);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('작은 화면 글자 $scale배에서 확인·불일치·재설정 흐름을 조작해야 한다', (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 32, bottom: 48);
        tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 48);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = MockSecretPinRepository();
        when(() => repo.setPin(any())).thenAnswer((_) async {});
        await tester.pumpWidget(_buildHarness(mockPinRepo: repo));
        await _openSetup(tester);

        await _tapPinVisible(tester, '1234');
        expect(find.text('PIN을 한 번 더 입력해주세요'), findsOneWidget);
        await _tapPinVisible(tester, '1235');
        await tester.pump(const Duration(milliseconds: 500));
        final error = find.text('PIN이 일치하지 않습니다. 다시 입력해주세요.');
        expect(error, findsOneWidget);
        await tester.ensureVisible(error);
        await tester.pumpAndSettle();
        final errorRect = tester.getRect(error);
        expect(errorRect.top, greaterThanOrEqualTo(32));
        expect(errorRect.bottom, lessThanOrEqualTo(480 - 48));
        expect(_filledDotCount(tester), 0);
        // The error must not cover the keypad while the user retries.
        expect(
          find.descendant(
            of: find.byKey(const Key('secret_pin_content_card')),
            matching: error,
          ),
          findsOneWidget,
        );
        for (final key in [
          find.descendant(
            of: find.byKey(const Key('secret_pin_keypad')),
            matching: find.text('0'),
          ),
          find.byIcon(Icons.backspace_outlined),
        ]) {
          await tester.ensureVisible(key);
          await tester.pumpAndSettle();
          expect(key.hitTestable(), findsOneWidget);
          expect(tester.getRect(key).bottom, lessThanOrEqualTo(480 - 48));
        }

        // A mismatch keeps the confirm step; one matching entry completes setup.
        await _tapPinVisible(tester, '1234');
        await tester.pumpAndSettle();
        verify(() => repo.setPin(any())).called(1);
        expect(find.text('Open Setup'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    for (final inset in [0.0, 48.0]) {
      testWidgets('하단 인셋 $inset 에서 불필요한 스크롤 없이 중앙 정렬', (tester) async {
        tester.view.physicalSize = const Size(412, 1400);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(top: 32, bottom: inset);
        tester.view.viewPadding = FakeViewPadding(top: 32, bottom: inset);
        addTearDown(() {
          tester.view.reset();
        });
        final repo = MockSecretPinRepository();
        await tester.pumpWidget(_buildHarness(mockPinRepo: repo));
        await _openSetup(tester);
        await tester.pumpAndSettle();
        final scroll = find.byType(SingleChildScrollView).first;
        final position = tester
            .state<ScrollableState>(
              find
                  .descendant(of: scroll, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        expect(position.maxScrollExtent, closeTo(0, 0.5));
        final view = tester.getRect(scroll);
        final center = find
            .descendant(of: scroll, matching: find.byType(Center))
            .first;
        expect(
          tester.getRect(center).center.dy,
          closeTo(view.center.dy - inset / 2, 0.5),
        );
      });
    }

    testWidgets('초기 상태에서 1단계 PIN 설정 UI가 표시되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.setPin(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      expect(find.text('비밀일기 PIN 설정'), findsOneWidget);
      expect(find.text('새 PIN을 입력해주세요'), findsOneWidget);
      expect(find.text('4자리 숫자로 비밀일기를 보호합니다'), findsOneWidget);
      expect(find.byKey(const Key('secret_pin_content_card')), findsOneWidget);
      expect(find.byKey(const Key('secret_pin_keypad')), findsOneWidget);
    });

    testWidgets('4자리 입력 시 2단계 확인 화면으로 전환되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.setPin(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      await _tapPin(tester, '1234');

      expect(find.text('PIN을 한 번 더 입력해주세요'), findsOneWidget);
      expect(find.text('입력한 PIN을 확인합니다'), findsOneWidget);
    });

    testWidgets('확인 PIN 불일치 시 에러 메시지와 도트 리셋이 동작해야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.setPin(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      await _tapPin(tester, '1234');
      await _tapPin(tester, '1235');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PIN이 일치하지 않습니다. 다시 입력해주세요.'), findsOneWidget);
      expect(_filledDotCount(tester), 0);
    });

    testWidgets('불일치 문구는 재입력 시작 시 사라지고 다시 틀리면 새 live region으로 표시', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.setPin(any())).thenAnswer((_) async {});
      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      const message = 'PIN이 일치하지 않습니다. 다시 입력해주세요.';
      await _tapPin(tester, '1234');
      await _tapPin(tester, '1235');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(message), findsOneWidget);
      expect(
        tester.getSemantics(find.text(message)),
        containsSemantics(label: message, isLiveRegion: true),
      );

      await _tapPin(tester, '1');
      expect(find.text(message), findsNothing);

      await _tapPin(tester, '235');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(message), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('확인 PIN 일치 시 저장 후 이전 화면으로 pop되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.setPin(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      await _tapPin(tester, '1234');
      await _tapPin(tester, '1234');
      await tester.pumpAndSettle();

      verify(() => mockPinRepo.setPin(any())).called(1);
      expect(find.text('Open Setup'), findsOneWidget);
      expect(find.text('비밀일기 PIN 설정'), findsNothing);
    });
  });
}
