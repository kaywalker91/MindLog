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
  });

  group('SecretPinSetupScreen', () {
    testWidgets('초기 상태에서 1단계 PIN 설정 UI가 표시되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
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
      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      await _tapPin(tester, '1234');
      await _tapPin(tester, '1235');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PIN이 일치하지 않습니다. 다시 입력해주세요.'), findsOneWidget);
      expect(_filledDotCount(tester), 0);
    });

    testWidgets('확인 PIN 일치 시 저장 후 이전 화면으로 pop되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPinRepo = MockSecretPinRepository();
      await tester.pumpWidget(_buildHarness(mockPinRepo: mockPinRepo));
      await tester.pumpAndSettle();
      await _openSetup(tester);

      await _tapPin(tester, '1234');
      await _tapPin(tester, '1234');
      await tester.pumpAndSettle();

      expect(mockPinRepo.setPinCallCount, 1);
      expect(find.text('Open Setup'), findsOneWidget);
      expect(find.text('비밀일기 PIN 설정'), findsNothing);
    });
  });
}
