import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';
import 'package:mindlog/presentation/providers/secret_diary_providers.dart';
import 'package:mindlog/presentation/screens/secret_diary_unlock_screen.dart';

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
  });

  group('SecretDiaryUnlockScreen', () {
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
      // correctPin = null → 모든 PIN 검증 실패

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
