import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/di/infra_providers.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/services/safety_followup_service.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/presentation/providers/diary_analysis_controller.dart';
import 'package:mindlog/presentation/providers/statistics_providers.dart';
import 'package:mindlog/presentation/screens/diary_screen.dart';
import 'package:mindlog/presentation/widgets/image_picker_section.dart';
import 'package:mindlog/presentation/widgets/loading_indicator.dart';
import 'package:mindlog/presentation/widgets/result_card.dart';
import 'package:mindlog/presentation/widgets/sos_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../fixtures/diary_fixtures.dart';
import '../../fixtures/statistics_fixtures.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_usecases.dart';

/// Firebase 없이 상태를 제어하는 테스트 전용 Notifier.
///
/// 실제 [DiaryAnalysisNotifier.analyzeDiary]는 Firebase Analytics,
/// NotificationService 등 정적 서비스를 호출하므로 테스트 환경에서
/// FirebaseException이 발생한다. 이를 방지하기 위해 subclass로 오버라이드.
class _FirebaseFreeNotifier extends DiaryAnalysisNotifier {
  final AnalyzeDiaryUseCase _useCase;

  _FirebaseFreeNotifier(this._useCase, Ref ref) : super(ref);

  @override
  Future<void> analyzeDiary(String content, {List<String>? imagePaths}) async {
    state = const DiaryAnalysisLoading();
    try {
      final diary = await _useCase.execute(content, imagePaths: imagePaths);
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

/// 분석 완료를 수동으로 제어할 수 있는 테스트 전용 Mock
class _ControllableMock implements AnalyzeDiaryUseCase {
  final Completer<Diary> _completer;
  _ControllableMock(this._completer);

  @override
  Future<Diary> execute(String content, {List<String>? imagePaths}) =>
      _completer.future;
}

/// 분석 호출 횟수를 추적하는 테스트 전용 Mock
class _CountingMock extends MockAnalyzeDiaryUseCase {
  int callCount = 0;

  @override
  Future<Diary> execute(String content, {List<String>? imagePaths}) {
    callCount++;
    return super.execute(content, imagePaths: imagePaths);
  }
}

Widget _buildHarness({AnalyzeDiaryUseCase? analyzeUseCase}) {
  final useCase = analyzeUseCase ?? MockAnalyzeDiaryUseCase();
  return ProviderScope(
    overrides: [
      // Firebase 호출 없는 notifier로 교체
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

/// 큰 논리 크기(800×2000)를 설정하여 폼 위젯이 모두 뷰포트 안에 들어오도록 한다.
/// physicalSize(800×2000) + devicePixelRatio(1.0) → logicalSize(800×2000)
void _setLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

const _validContent = '오늘 프로젝트 발표가 있었는데 잘 마무리해서 기분이 좋다.';
const _shortContent = '짧은텍스트'; // 6자 — diaryMinLength(10) 미만

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  group('DiaryScreen', () {
    testWidgets('초기 화면: 텍스트 입력 필드와 비활성 분석 버튼이 렌더링된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // 텍스트 입력 필드
      expect(find.byType(TextFormField), findsOneWidget);
      // 인트로 텍스트
      expect(find.text('오늘 하루는 어떠셨나요?'), findsOneWidget);
      // 분석 버튼 — 빈 입력이므로 비활성화
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull, reason: '초기 빈 상태에서 버튼은 비활성이어야 한다');
      expect(tester.takeException(), isNull);
    });

    testWidgets('텍스트 길이에 따라 분석 버튼이 활성화/비활성화된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      // 짧은 텍스트 → 버튼 비활성
      await tester.enterText(find.byType(TextFormField), _shortContent);
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
        reason: '${_shortContent.length}자: diaryMinLength 미달이므로 비활성',
      );

      // 충분한 텍스트 → 버튼 활성
      await tester.enterText(find.byType(TextFormField), _validContent);
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
        reason: '${_validContent.length}자: diaryMinLength 이상이므로 활성',
      );
    });

    testWidgets('분석 시작 → LoadingIndicator가 표시되고 입력 폼이 숨겨진다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final completer = Completer<Diary>();
      await tester.pumpWidget(
        _buildHarness(analyzeUseCase: _ControllableMock(completer)),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), _validContent);
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // 동기 부분 처리: state = DiaryAnalysisLoading

      // Completer 미완료 → 로딩 중 상태 유지
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNothing,
        reason: '로딩 중에는 입력 폼이 숨겨진다',
      );

      // 정리: pending 상태 일기로 완료 → Error 경로 (2초 오버레이 타이머 미생성)
      // _buildAccentCircle delay:600ms → Future.delayed(600ms) Timer 소진 필요
      completer.complete(DiaryFixtures.pending());
      await tester.pump(
        const Duration(milliseconds: 700),
      ); // state→Error + 600ms delay timer 소진
      await tester.pump();
    });

    testWidgets('분석 성공 → ResultCard가 표시된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final mock = MockAnalyzeDiaryUseCase()
        ..mockDiary = DiaryFixtures.analyzed(sentimentScore: 8);

      await tester.pumpWidget(_buildHarness(analyzeUseCase: mock));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), _validContent);
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // Success (mock async future resolves)
      // 성공 후 2초 오버레이 타이머 소진
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byType(ResultCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('분석 실패(NetworkFailure) → 에러 메시지와 재시도 버튼이 표시된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final mock = MockAnalyzeDiaryUseCase()
        ..shouldThrow = true
        ..failureToThrow = const Failure.network(message: '네트워크 연결을 확인해주세요.');

      await tester.pumpWidget(_buildHarness(analyzeUseCase: mock));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), _validContent);
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // Error

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('네트워크 연결을 확인해주세요.'), findsOneWidget);
      expect(find.text('다시 시도하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SafetyBlocked → SosCard가 표시된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final mock = MockAnalyzeDiaryUseCase()
        ..shouldThrow = true
        ..failureToThrow = const SafetyBlockedFailure();

      await tester.pumpWidget(_buildHarness(analyzeUseCase: mock));
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField),
        '너무 힘들어서 모든 것을 포기하고 싶다는 생각이 든다.',
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // SafetyBlocked
      // SosCard AnimationController.forward() (1200ms) + Riverpod 0ms 타이머 소진
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(find.byType(SosCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('이미지 선택 섹션이 입력 폼에 렌더링된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.byType(ImagePickerSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SafetyBlocked 발생 시 팔로업 알림이 예약된다 (static override 패턴)', (tester) async {
      // REQ-070: 위기 감지 → 24시간 후 팔로업 알림 예약
      // _FirebaseFreeNotifier는 _scheduleSafetyFollowup()을 건너뛰므로
      // 실제 DiaryAnalysisNotifier를 사용하여 전체 경로 검증
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      // SharedPreferences mock (SafetyFollowupService.scheduleFollowup 내부 사용)
      SharedPreferences.setMockInitialValues({});
      // timezone 초기화 (TZDateTime.from 변환 필요)
      tz_data.initializeTimeZones();

      // scheduleOneTimeOverride: NotificationService 미초기화 LateInitializationError 방지
      bool followupScheduled = false;
      SafetyFollowupService.scheduleOneTimeOverride = ({
        required int id,
        required String title,
        required String body,
        required dynamic scheduledDate,
        String? payload,
        String channel = '',
      }) async {
        followupScheduled = true;
        return true;
      };
      addTearDown(() => SafetyFollowupService.resetForTesting());

      final mock = MockAnalyzeDiaryUseCase()
        ..shouldThrow = true
        ..failureToThrow = const SafetyBlockedFailure();

      // 실제 DiaryAnalysisNotifier 사용 (analyzeDiaryUseCaseProvider만 오버라이드)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyzeDiaryUseCaseProvider.overrideWithValue(mock),
            diaryRepositoryProvider.overrideWithValue(MockDiaryRepository()),
            statisticsProvider.overrideWith((ref) => StatisticsFixtures.weekly()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DiaryScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField),
        '너무 힘들어서 모든 것을 포기하고 싶다는 생각이 든다.',
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Loading
      await tester.pump(); // SafetyBlocked + unawaited(_scheduleSafetyFollowup()) 시작
      await tester.pump(const Duration(milliseconds: 300)); // async 팔로업 완료 대기

      expect(
        followupScheduled,
        isTrue,
        reason: 'SafetyBlocked 감지 시 팔로업 알림이 예약되어야 한다',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('에러 상태에서 재시도 버튼 탭 시 분석을 다시 시도한다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final mock = _CountingMock()
        ..shouldThrow = true
        ..failureToThrow = const Failure.network();

      await tester.pumpWidget(_buildHarness(analyzeUseCase: mock));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), _validContent);
      await tester.pump();

      // 1차 분석 → 실패
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('다시 시도하기'), findsOneWidget);
      expect(mock.callCount, 1);

      // 재시도 탭
      await tester.tap(find.text('다시 시도하기'));
      await tester.pump(const Duration(milliseconds: 600)); // 500ms 딜레이 소진
      await tester.pump(); // 재분석 시도
      await tester.pump(); // 에러 재표시

      expect(mock.callCount, 2, reason: '재시도 버튼 탭 시 분석이 다시 호출된다');
      expect(find.text('다시 시도하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
