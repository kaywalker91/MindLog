import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/presentation/providers/providers.dart';
import 'package:mindlog/presentation/widgets/delete_diary_dialog.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('DeleteDiaryDialog', () {
    late MockDiaryRepository mockDiaryRepo;
    late ProviderContainer container;

    setUp(() {
      mockDiaryRepo = MockDiaryRepository();
      container = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepo),
        ],
      );
    });

    tearDown(() {
      mockDiaryRepo.reset();
      container.dispose();
    });

    Widget buildTestWidget({
      required Widget child,
      bool useRouter = false,
    }) {
      if (useRouter) {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => child,
            ),
          ],
        );
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        );
      }
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: child),
      );
    }

    group('렌더링', () {
      testWidgets('다이얼로그가 올바른 UI 요소를 표시해야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            child: Scaffold(
              body: DeleteDiaryDialog(diary: diary),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('소중한 기록을 지우시겠어요?'), findsOneWidget);
        expect(find.textContaining('삭제 후에는 되돌릴 수 없어요'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
      });

      testWidgets('삭제 아이콘이 표시되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            child: Scaffold(
              body: DeleteDiaryDialog(diary: diary),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      });

      testWidgets('둥근 모서리가 적용되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            child: Scaffold(
              body: DeleteDiaryDialog(diary: diary),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.shape, isA<RoundedRectangleBorder>());

        final shape = dialog.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(24));
      });
    });

    group('show() 메서드', () {
      testWidgets('다이얼로그가 올바르게 표시되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteDiaryDialog.show(context, diary: diary),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시 전
        expect(find.byType(Dialog), findsNothing);

        // 버튼 탭
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('소중한 기록을 지우시겠어요?'), findsOneWidget);
      });
    });

    group('버튼 상호작용', () {
      testWidgets('취소 버튼 탭 시 다이얼로그가 닫혀야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteDiaryDialog.show(context, diary: diary),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);

        // Act - 취소 버튼 탭
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsNothing);
      });

      testWidgets('삭제 버튼 탭 시 일기가 삭제되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'to-delete');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteDiaryDialog.show(context, diary: diary),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 삭제 버튼 탭
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        // Assert - 삭제 호출 확인
        expect(mockDiaryRepo.deletedDiaryIds, contains('to-delete'));
      });

      testWidgets('삭제 후 스낵바가 표시되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'snackbar-test');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteDiaryDialog.show(context, diary: diary),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 삭제 버튼 탭
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        // Assert - 스낵바 확인
        expect(find.text('일기가 삭제되었습니다.'), findsOneWidget);
      });
    });

    group('popAfterDelete 옵션', () {
      testWidgets('popAfterDelete 기본값은 false이다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'default-pop');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            child: Scaffold(
              body: DeleteDiaryDialog(diary: diary),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - 위젯이 정상 렌더링됨 (popAfterDelete 기본값으로)
        expect(find.text('소중한 기록을 지우시겠어요?'), findsOneWidget);
      });

      testWidgets('popAfterDelete=true로 다이얼로그 생성 시 정상 렌더링되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'pop-after');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            child: Scaffold(
              body: DeleteDiaryDialog(
                diary: diary,
                popAfterDelete: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - 위젯이 정상 렌더링됨
        expect(find.text('소중한 기록을 지우시겠어요?'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
      });
    });

    group('show() 메서드 반환값', () {
      testWidgets('삭제 버튼 탭 시 true를 반환해야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'return-true');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        bool? dialogResult;

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult =
                        await DeleteDiaryDialog.show(context, diary: diary);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 삭제 버튼 탭
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogResult, isTrue);
      });

      testWidgets('취소 버튼 탭 시 false를 반환해야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'return-false');
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        bool? dialogResult;

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult =
                        await DeleteDiaryDialog.show(context, diary: diary);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 취소 버튼 탭
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogResult, isFalse);
      });
    });

    group('에러 처리', () {
      testWidgets('삭제 실패 시 에러 스낵바가 표시되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed(id: 'error-test');
        mockDiaryRepo.diaries = [diary];
        mockDiaryRepo.shouldThrowOnDelete = true;
        mockDiaryRepo.errorMessage = 'Database error';
        await container.read(diaryListControllerProvider.future);

        await tester.pumpWidget(
          buildTestWidget(
            useRouter: true,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteDiaryDialog.show(context, diary: diary),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 삭제 버튼 탭
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        // Assert - 에러 스낵바 확인
        expect(find.textContaining('삭제 중 오류가 발생했습니다'), findsOneWidget);
      });
    });

    group('다크 모드', () {
      testWidgets('다크 모드에서 올바르게 렌더링되어야 한다', (tester) async {
        // Arrange
        final diary = DiaryFixtures.analyzed();
        mockDiaryRepo.diaries = [diary];
        await container.read(diaryListControllerProvider.future);

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData.dark(useMaterial3: true),
              home: Scaffold(
                body: DeleteDiaryDialog(diary: diary),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - 기본 요소 확인
        expect(find.text('소중한 기록을 지우시겠어요?'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
      });
    });
  });
}
