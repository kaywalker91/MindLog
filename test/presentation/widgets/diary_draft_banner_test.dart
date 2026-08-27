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
      testWidgets('라이트 테마에서 렌더되고 텍스트 색이 AppColors.primary가 아님을 단언한다', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            theme: ThemeData.light(useMaterial3: true),
          ),
        );
        await pumpSafely(tester);

        expect(find.byType(DiaryDraftBanner), findsOneWidget);

        final textWidgets = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(DiaryDraftBanner),
            matching: find.byType(Text),
          ),
        );

        expect(textWidgets.isNotEmpty, isTrue);
        for (final text in textWidgets) {
          expect(
            text.style?.color,
            isNot(equals(AppColors.primary)),
            reason: '배너 내 모든 텍스트의 색상은 AppColors.primary여서는 안 됩니다',
          );
        }
      });

      testWidgets('다크 테마에서 렌더되고 텍스트 색이 AppColors.primary가 아님을 단언한다', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            theme: ThemeData.dark(useMaterial3: true),
          ),
        );
        await pumpSafely(tester);

        expect(find.byType(DiaryDraftBanner), findsOneWidget);

        final textWidgets = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(DiaryDraftBanner),
            matching: find.byType(Text),
          ),
        );

        expect(textWidgets.isNotEmpty, isTrue);
        for (final text in textWidgets) {
          expect(
            text.style?.color,
            isNot(equals(AppColors.primary)),
            reason: '배너 내 모든 텍스트의 색상은 AppColors.primary여서는 안 됩니다',
          );
        }
      });
    });
  });
}
