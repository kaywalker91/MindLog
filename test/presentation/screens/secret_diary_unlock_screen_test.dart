import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';
import 'package:mindlog/presentation/providers/secret_diary_providers.dart';
import 'package:mindlog/presentation/screens/secret_diary_unlock_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

Widget _buildHarness({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SecretDiaryUnlockScreen(),
    ),
  );
}

/// PIN을 4자리 탭 (1234)
Future<void> _tapPin1234(WidgetTester tester) async {
  await tester.tap(find.text('1'));
  await tester.pump();
  await tester.tap(find.text('2'));
  await tester.pump();
  await tester.tap(find.text('3'));
  await tester.pump();
  await tester.tap(find.text('4'));
  // 마지막 탭 후: isLoading=true (setState), async future 시작
  await tester.pump();
  // async future 완료 (MockRepo는 즉시 false 반환)
  await tester.pump();
  // shake 애니메이션 처리
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
    registerMockFallbackValues();
  });

  group('SecretDiaryUnlockScreen', () {
    testWidgets('작은 화면에서 마지막 숫자와 삭제 키까지 스크롤하고 조작해야 한다', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 48);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_buildHarness());
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
      testWidgets('작은 화면 글자 $scale배에서 실패 안내와 초기화 링크를 조작해야 한다', (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 32, bottom: 48);
        tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 48);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = MockSecretPinRepository();
        when(() => repo.hasPin()).thenAnswer((_) async => true);
        when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
        await tester.pumpWidget(
          _buildHarness(
            overrides: [
              verifySecretPinUseCaseProvider.overrideWithValue(
                VerifySecretPinUseCase(repo),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Future<void> fail() async {
          for (final digit in '1234'.split('')) {
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
          await tester.pump(const Duration(milliseconds: 500));
        }

        for (var i = 0; i < 3; i++) {
          await fail();
        }
        final error = find.text('PIN이 일치하지 않습니다. 아래 링크를 통해 초기화할 수 있습니다.');
        expect(error, findsOneWidget);
        await tester.ensureVisible(error);
        await tester.pumpAndSettle();
        expect(tester.getRect(error).top, greaterThanOrEqualTo(32));
        expect(tester.getRect(error).bottom, lessThanOrEqualTo(480 - 48));

        final link = find.text('비밀번호를 잊으셨나요?');
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        expect(link.hitTestable(), findsOneWidget);
        expect(tester.getRect(link).bottom, lessThanOrEqualTo(480 - 48));
        await tester.tap(link);
        await tester.pumpAndSettle();
        for (final label in ['취소', '초기화']) {
          final button = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(label),
          );
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getRect(button).top, greaterThanOrEqualTo(32));
          expect(tester.getRect(button).bottom, lessThanOrEqualTo(480 - 48));
        }
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
        await tester.pumpWidget(_buildHarness());
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

    testWidgets('320~360/412+/대형 뷰포트에서 overflow 없이 렌더링', (tester) async {
      const sizes = [
        Size(320, 640),
        Size(360, 780),
        Size(412, 915),
        Size(800, 2000),
      ];

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(_buildHarness());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('secret_pin_content_card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'size: $size');
      }
    });

    testWidgets('대형 화면에서 PIN 카드가 본문 중앙에 가깝게 배치되어야 한다', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      final bodyRect = tester.getRect(find.byType(SingleChildScrollView).first);
      final cardRect = tester.getRect(
        find.byKey(const Key('secret_pin_content_card')),
      );
      final deltaY = (cardRect.center.dy - bodyRect.center.dy).abs();

      expect(deltaY, lessThanOrEqualTo(120));
    });

    testWidgets('초기 렌더링: PIN 입력 화면 표시', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // 제목
      expect(find.text('PIN을 입력해주세요'), findsOneWidget);
      // 키패드 숫자
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      // 초기에는 forgot-pin 링크 없음
      expect(find.text('비밀번호를 잊으셨나요?'), findsNothing);
    });

    testWidgets('3회 PIN 실패 후 "비밀번호를 잊으셨나요?" 링크 표시', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPinRepo = MockSecretPinRepository();
      // hasPin() → true, verifyPin('1234') → false (모든 PIN 검증 실패)
      when(() => mockPinRepo.hasPin()).thenAnswer((_) async => true);
      when(() => mockPinRepo.verifyPin(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _buildHarness(
          overrides: [
            verifySecretPinUseCaseProvider.overrideWithValue(
              VerifySecretPinUseCase(mockPinRepo),
            ),
          ],
        ),
      );
      await tester.pump();

      // 초기 상태: 링크 없음
      expect(find.text('비밀번호를 잊으셨나요?'), findsNothing);

      // 1회 실패
      await _tapPin1234(tester);
      expect(find.text('비밀번호를 잊으셨나요?'), findsNothing);

      // 2회 실패
      await _tapPin1234(tester);
      expect(find.text('비밀번호를 잊으셨나요?'), findsNothing);

      // 3회 실패 → 링크 표시
      await _tapPin1234(tester);
      expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);
    });

    testWidgets('"비밀번호를 잊으셨나요?" 탭 시 초기화 다이얼로그 표시', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPinRepo = MockSecretPinRepository();
      when(() => mockPinRepo.hasPin()).thenAnswer((_) async => true);
      when(() => mockPinRepo.verifyPin(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _buildHarness(
          overrides: [
            verifySecretPinUseCaseProvider.overrideWithValue(
              VerifySecretPinUseCase(mockPinRepo),
            ),
          ],
        ),
      );
      await tester.pump();

      // 3회 실패 → forgot-pin 링크 표시
      await _tapPin1234(tester);
      await _tapPin1234(tester);
      await _tapPin1234(tester);

      expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);

      // forgot-pin 링크 탭 → 다이얼로그 표시
      await tester.tap(find.text('비밀번호를 잊으셨나요?'));
      await tester.pump();

      // 다이얼로그 내용 확인
      expect(find.text('비밀일기 초기화'), findsOneWidget);
      expect(
        find.text('PIN을 초기화하면 모든 비밀일기도 일반 일기로 전환됩니다.\n계속하시겠습니까?'),
        findsOneWidget,
      );
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('초기화'), findsOneWidget);
    });
  });
}
