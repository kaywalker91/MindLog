import 'dart:convert';
import 'dart:io';

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
  List<String>? imagePaths,
}) {
  final now = DateTime.now();
  return DiaryDraft(
    content: content,
    entryDate: entryDate ?? DateTime(now.year, now.month, now.day),
    updatedAt: updatedAt ?? now.subtract(const Duration(minutes: 3)),
    imagePaths: imagePaths,
  );
}

/// 1x1 투명 PNG — Image.file 이 디코드에 실패해 예외를 흘리지 않도록 실제 파일을 쓴다.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// 복원 대상 이미지를 실제 파일로 만들어 경로를 돌려준다.
List<String> _writeTempImages(WidgetTester tester, int count) {
  final dir = Directory.systemTemp.createTempSync('draft_restore_images');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return List<String>.generate(count, (i) {
    final file = File('${dir.path}/image_$i.png')
      ..writeAsBytesSync(_onePixelPng);
    return file.path;
  });
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
        (_) async => _draft(entryDate: tomorrow, updatedAt: DateTime.now()),
      );

      await pumpDiaryScreen(tester);

      expect(_textOf(tester), _restoredContent);
      expect(find.byType(DiaryDraftBanner), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('g: 과거 날짜 초안을 복원하면 날짜 칩에 그 과거 날짜가 반영되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final now = DateTime.now();
      final threeDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 3));
      when(() => mockGetDraft.execute()).thenAnswer(
        (_) async => _draft(entryDate: threeDaysAgo, updatedAt: DateTime.now()),
      );

      await pumpDiaryScreen(tester);

      // 케이스 f(미래→오늘 클램프)는 _selectedDate 기본값이 이미 '오늘'이라
      // 날짜 복원 로직을 통째로 지워도 통과한다. 이 케이스가 그 공백을 막는다.
      expect(find.text('오늘'), findsNothing);
      expect(find.textContaining('3일 전'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('h: 이미지가 포함된 초안을 복원하면 폼에 이미지가 복원되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final paths = _writeTempImages(tester, 2);
      when(() => mockGetDraft.execute()).thenAnswer(
        (_) async => _draft(imagePaths: paths, updatedAt: DateTime.now()),
      );

      await pumpDiaryScreen(tester);

      expect(_textOf(tester), _restoredContent);
      expect(find.textContaining('첨부 2장'), findsOneWidget);
    });

    testWidgets('i: 디바운스 만료 전 백그라운드 전환에도 초안이 즉시 저장되어야 한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await pumpDiaryScreen(tester);

      const typed = '백그라운드 전환 저장 확인용 본문';
      await tester.enterText(find.byType(TextFormField), typed);
      await tester.pump(const Duration(milliseconds: 100));

      // 여기까지의 저장 호출은 관심 밖 — 이후 호출만 flush 로 귀속시킨다.
      clearInteractions(mockSaveDraft);

      // 라이프사이클 전이는 inactive -> hidden -> paused 순서만 허용된다.
      // 화면은 onHide/onPause 둘 다 flush 에 연결해 두었으므로 호출은 1회 이상이다.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 100));

      // enterText 이후 총 200ms 만 흘렀으므로 800ms 디바운스는 만료될 수 없다.
      // 즉 이 호출은 AppLifecycleListener 의 flush 말고는 나올 곳이 없다.
      verify(
        () => mockSaveDraft.execute(
          typed,
          entryDate: any(named: 'entryDate'),
          imagePaths: any(named: 'imagePaths'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
