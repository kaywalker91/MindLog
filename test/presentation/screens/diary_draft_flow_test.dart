import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/domain/usecases/clear_diary_draft_usecase.dart';
import 'package:mindlog/domain/usecases/get_diary_draft_usecase.dart';
import 'package:mindlog/domain/usecases/save_diary_draft_usecase.dart';
import 'package:mindlog/presentation/providers/providers.dart';
import 'package:mindlog/presentation/screens/diary_screen.dart';
import 'package:mindlog/presentation/widgets/diary/diary_draft_banner.dart';
import 'package:mindlog/presentation/widgets/result_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../fixtures/statistics_fixtures.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_usecases.dart';

class MockGetDiaryDraftUseCase extends Mock implements GetDiaryDraftUseCase {}

class MockClearDiaryDraftUseCase extends Mock
    implements ClearDiaryDraftUseCase {}

class MockSaveDiaryDraftUseCase extends Mock implements SaveDiaryDraftUseCase {}

/// Firebase 없이 분석 상태를 제어하는 테스트 전용 Notifier.
class _FirebaseFreeNotifier extends DiaryAnalysisNotifier {
  final AnalyzeDiaryUseCase _useCase;

  _FirebaseFreeNotifier(this._useCase, Ref ref) : super(ref);

  @override
  Future<void> analyzeDiary(
    String content, {
    List<String>? imagePaths,
    DateTime? entryDate,
  }) async {
    state = const DiaryAnalysisLoading();
    try {
      final diary = await _useCase.execute(
        content,
        imagePaths: imagePaths,
        entryDate: entryDate,
      );
      if (diary.analysisResult == null &&
          diary.status != DiaryStatus.safetyBlocked) {
        state = const DiaryAnalysisError(
          Failure.unknown(message: '분석 결과를 가져오지 못했습니다.'),
        );
        return;
      }
      state = DiaryAnalysisSuccess(diary);
    } on SafetyBlockedFailure {
      state = const DiaryAnalysisSafetyBlocked();
    } on Failure catch (failure) {
      state = DiaryAnalysisError(failure);
    } catch (e) {
      state = DiaryAnalysisError(Failure.unknown(message: e.toString()));
    }
  }
}

const _restoredContent = '이전에 쓰다 만 일기입니다. 복원 확인용 본문.';

DiaryDraft _draft({
  String content = _restoredContent,
  DateTime? entryDate,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return DiaryDraft(
    content: content,
    entryDate: entryDate ?? DateTime(now.year, now.month, now.day),
    updatedAt: updatedAt ?? now.subtract(const Duration(minutes: 3)),
  );
}

/// flutter_animate 무한 루프를 피하기 위해 pumpAndSettle 대신 고정 프레임을 돌린다.
Future<void> _pumpSafely(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void _setLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

String _textOf(WidgetTester tester) {
  return tester
          .widget<TextFormField>(find.byType(TextFormField))
          .controller
          ?.text ??
      '';
}

void main() {
  late MockGetDiaryDraftUseCase mockGetDraft;
  late MockClearDiaryDraftUseCase mockClearDraft;
  late MockSaveDiaryDraftUseCase mockSaveDraft;

  setUpAll(() {
    Animate.restartOnHotReload = false;
    registerMockFallbackValues();
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockGetDraft = MockGetDiaryDraftUseCase();
    mockClearDraft = MockClearDiaryDraftUseCase();
    mockSaveDraft = MockSaveDiaryDraftUseCase();
    when(() => mockGetDraft.execute()).thenAnswer((_) async => null);
    when(() => mockClearDraft.execute()).thenAnswer((_) async {});
    when(
      () => mockSaveDraft.execute(
        any(),
        entryDate: any(named: 'entryDate'),
        imagePaths: any(named: 'imagePaths'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildHarness({AnalyzeDiaryUseCase? analyzeUseCase}) {
    final useCase = analyzeUseCase ?? MockAnalyzeDiaryUseCase();
    return ProviderScope(
      overrides: [
        diaryDraftControllerProvider.overrideWith(
          (ref) => DiaryDraftController(ref),
        ),
        getDiaryDraftUseCaseProvider.overrideWithValue(mockGetDraft),
        clearDiaryDraftUseCaseProvider.overrideWithValue(mockClearDraft),
        saveDiaryDraftUseCaseProvider.overrideWithValue(mockSaveDraft),
        diaryAnalysisControllerProvider.overrideWith(
          (ref) => _FirebaseFreeNotifier(useCase, ref),
        ),
        diaryRepositoryProvider.overrideWithValue(MockDiaryRepository()),
        statisticsProvider.overrideWith((ref) => StatisticsFixtures.weekly()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const DiaryScreen(),
      ),
    );
  }

  Future<void> pumpDiaryScreen(
    WidgetTester tester, {
    AnalyzeDiaryUseCase? analyzeUseCase,
  }) async {
    await tester.pumpWidget(buildHarness(analyzeUseCase: analyzeUseCase));
    await tester.pump();
    await _pumpSafely(tester);
  }

  group('DiaryScreen 초안 플로우', () {
    testWidgets('a: 초안이 있는 상태로 진입하면 텍스트가 복원되고 배너가 보여야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      when(() => mockGetDraft.execute()).thenAnswer((_) async => _draft());

      await pumpDiaryScreen(tester);

      expect(_textOf(tester), _restoredContent);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);
      expect(find.text('이전에 작성하던 내용을 불러왔어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('b: 초안이 없으면 배너가 보이지 않고 폼이 빈 상태여야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await pumpDiaryScreen(tester);

      expect(find.byType(DiaryDraftBanner), findsNothing);
      expect(find.text('이전에 작성하던 내용을 불러왔어요'), findsNothing);
      expect(_textOf(tester), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('c: 배너 삭제 시 폼이 비워지고 clear UseCase가 호출되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      when(() => mockGetDraft.execute()).thenAnswer((_) async => _draft());

      await pumpDiaryScreen(tester);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pump();
      await _pumpSafely(tester);

      expect(find.byType(DiaryDraftBanner), findsNothing);
      expect(_textOf(tester), isEmpty);
      verify(() => mockClearDraft.execute()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('d: 분석 성공에 도달하면 초안 폐기가 호출되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      when(() => mockGetDraft.execute()).thenAnswer((_) async => _draft());

      final mockUseCase = MockAnalyzeDiaryUseCase();
      when(
        () => mockUseCase.execute(
          any(),
          imagePaths: any(named: 'imagePaths'),
          entryDate: any(named: 'entryDate'),
        ),
      ).thenAnswer((_) async => DiaryFixtures.analyzed());

      await pumpDiaryScreen(tester, analyzeUseCase: mockUseCase);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // Success
      // 성공 오버레이 2초 자동 숨김 Timer 소진 + discard Future
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byType(ResultCard), findsOneWidget);
      verify(() => mockClearDraft.execute()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('e: 분석 실패에 도달하면 초안 폐기가 호출되지 않아야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      when(() => mockGetDraft.execute()).thenAnswer((_) async => _draft());

      final mockUseCase = MockAnalyzeDiaryUseCase();
      when(
        () => mockUseCase.execute(
          any(),
          imagePaths: any(named: 'imagePaths'),
          entryDate: any(named: 'entryDate'),
        ),
      ).thenThrow(const Failure.network(message: '네트워크 연결을 확인해주세요.'));

      await pumpDiaryScreen(tester, analyzeUseCase: mockUseCase);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // Error
      await _pumpSafely(tester);

      expect(find.text('네트워크 연결을 확인해주세요.'), findsOneWidget);
      verifyNever(() => mockClearDraft.execute());
      expect(tester.takeException(), isNull);
    });

    testWidgets('f: 복원된 entryDate가 미래이면 오늘로 클램프되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      when(() => mockGetDraft.execute()).thenAnswer(
        (_) async => _draft(
          entryDate: tomorrow,
          updatedAt: DateTime.now(),
        ),
      );

      await pumpDiaryScreen(tester);

      expect(_textOf(tester), _restoredContent);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
