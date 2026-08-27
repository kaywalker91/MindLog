import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_colors.dart';
import 'package:mindlog/presentation/widgets/diary/diary_draft_banner.dart';

void main() {
  /// 테스트용 위젯 빌드 헬퍼
  Widget buildTestWidget({
    required DateTime savedAt,
    VoidCallback? onDelete,
    VoidCallback? onDismiss,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: DiaryDraftBanner(
          savedAt: savedAt,
          onDelete: onDelete ?? () {},
          onDismiss: onDismiss ?? () {},
        ),
      ),
    );
  }

  /// 무한 애니메이션 타임아웃을 방지하기 위한 안전한 pump 헬퍼 (pumpAndSettle 대체)
  Future<void> pumpSafely(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  group('DiaryDraftBanner', () {
    group('기본 렌더링', () {
      testWidgets('배너의 문구, 아이콘, 버튼이 올바르게 렌더링된다', (tester) async {
        final savedAt = DateTime.now().subtract(const Duration(minutes: 5));

        await tester.pumpWidget(buildTestWidget(savedAt: savedAt));
        await pumpSafely(tester);

        expect(find.byType(DiaryDraftBanner), findsOneWidget);
        expect(find.text('이전에 작성하던 내용을 불러왔어요'), findsOneWidget);
        expect(find.text('5분 전'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
        expect(find.byIcon(Icons.restore_page_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('사용자 인터랙션 (케이스 a, b)', () {
      testWidgets('a: [삭제] 탭 시 onDelete가 정확히 1회 호출되고 onDismiss는 호출되지 않는다', (
        tester,
      ) async {
        var deleteCallCount = 0;
        var dismissCallCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            onDelete: () => deleteCallCount++,
            onDismiss: () => dismissCallCount++,
          ),
        );
        await pumpSafely(tester);

        final deleteButton = find.text('삭제');
        expect(deleteButton, findsOneWidget);

        await tester.tap(deleteButton);
        await pumpSafely(tester);

        expect(deleteCallCount, 1);
        expect(dismissCallCount, 0);
      });

      testWidgets('b: 닫기 아이콘 탭 시 onDismiss가 정확히 1회 호출되고 onDelete는 호출되지 않는다', (
        tester,
      ) async {
        var deleteCallCount = 0;
        var dismissCallCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            onDelete: () => deleteCallCount++,
            onDismiss: () => dismissCallCount++,
          ),
        );
        await pumpSafely(tester);

        final closeIcon = find.byIcon(Icons.close);
        expect(closeIcon, findsOneWidget);

        await tester.tap(closeIcon);
        await pumpSafely(tester);

        expect(dismissCallCount, 1);
        expect(deleteCallCount, 0);
      });
    });

    group('상대 시간 표시 (케이스 c)', () {
      testWidgets('savedAt이 30초 전이면 "방금 전"을 표시한다', (tester) async {
        final savedAt = DateTime.now().subtract(const Duration(seconds: 30));

        await tester.pumpWidget(buildTestWidget(savedAt: savedAt));
        await pumpSafely(tester);

        expect(find.text('방금 전'), findsOneWidget);
        expect(find.text('이전에 작성하던 내용을 불러왔어요'), findsOneWidget);
      });

      testWidgets('savedAt이 5분 전이면 "5분 전"을 표시한다', (tester) async {
        final savedAt = DateTime.now().subtract(const Duration(minutes: 5));

        await tester.pumpWidget(buildTestWidget(savedAt: savedAt));
        await pumpSafely(tester);

        expect(find.text('5분 전'), findsOneWidget);
      });

      testWidgets('savedAt이 3시간 전이면 "3시간 전"을 표시한다', (tester) async {
        final savedAt = DateTime.now().subtract(const Duration(hours: 3));

        await tester.pumpWidget(buildTestWidget(savedAt: savedAt));
        await pumpSafely(tester);

        expect(find.text('3시간 전'), findsOneWidget);
      });

      testWidgets('savedAt이 2일 전이면 "2일 전"을 표시한다', (tester) async {
        final savedAt = DateTime.now().subtract(const Duration(days: 2));

        await tester.pumpWidget(buildTestWidget(savedAt: savedAt));
        await pumpSafely(tester);

        expect(find.text('2일 전'), findsOneWidget);
      });
    });

    group('테마 렌더링 및 디자인 토큰 단언 (케이스 d)', () {
      /// 배너 내 특정 문구의 실제 렌더 색을 뽑는다.
      Color? colorOf(WidgetTester tester, String text) {
        return tester
            .widget<Text>(
              find.descendant(
                of: find.byType(DiaryDraftBanner),
                matching: find.text(text),
              ),
            )
            .style
            ?.color;
      }

      /// 각 테마에서 문구별로 **지정된 토큰과 같은지**를 단언한다.
      /// 이전 버전은 `isNot(AppColors.primary)` 부정 단언이라, 색이 누락되거나
      /// 엉뚱한 값으로 바뀌어도 통과했다.
      Future<void> expectTokenColors(
        WidgetTester tester,
        ThemeData theme,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            theme: theme,
          ),
        );
        await pumpSafely(tester);

        expect(find.byType(DiaryDraftBanner), findsOneWidget);

        final colorScheme = Theme.of(
          tester.element(find.byType(DiaryDraftBanner)),
        ).colorScheme;

        expect(
          colorOf(tester, '이전에 작성하던 내용을 불러왔어요'),
          colorScheme.onSurface,
          reason: '제목은 colorScheme.onSurface 를 써야 한다',
        );
        expect(
          colorOf(tester, '5분 전'),
          colorScheme.onSurfaceVariant,
          reason: '저장 시각은 colorScheme.onSurfaceVariant 를 써야 한다',
        );
        expect(
          colorOf(tester, '삭제'),
          AppColors.error,
          reason: '삭제 액션은 AppColors.error 를 써야 한다',
        );
      }

      testWidgets('라이트 테마에서 문구별 지정 토큰 색이 적용된다', (tester) async {
        await expectTokenColors(tester, ThemeData.light(useMaterial3: true));
      });

      testWidgets('다크 테마에서 문구별 지정 토큰 색이 적용된다', (tester) async {
        await expectTokenColors(tester, ThemeData.dark(useMaterial3: true));
      });
    });
  });
}
