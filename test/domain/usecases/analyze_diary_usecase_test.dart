import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/utils/clock.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late AnalyzeDiaryUseCase useCase;
  late MockDiaryRepository mockRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockDiaryRepository();
    mockSettingsRepository = MockSettingsRepository();
    useCase = AnalyzeDiaryUseCase(mockRepository, mockSettingsRepository);

    // Default stubs
    when(
      () => mockRepository.createDiary(
        any(),
        imagePaths: any(named: 'imagePaths'),
        createdAt: any(named: 'createdAt'),
      ),
    ).thenAnswer(
      (inv) async => DiaryFixtures.pending(
        content: inv.positionalArguments.first as String,
      ),
    );
    when(
      () => mockSettingsRepository.getSelectedAiCharacter(),
    ).thenAnswer((_) async => AiCharacter.warmCounselor);
    when(
      () => mockSettingsRepository.getUserName(),
    ).thenAnswer((_) async => null);
    when(
      () => mockRepository.analyzeDiary(
        any(),
        character: any(named: 'character'),
        userName: any(named: 'userName'),
        imagePaths: any(named: 'imagePaths'),
      ),
    ).thenAnswer(
      (inv) async =>
          DiaryFixtures.analyzed(id: inv.positionalArguments.first as String),
    );
    when(() => mockRepository.updateDiary(any())).thenAnswer((_) async {});
  });

  group('AnalyzeDiaryUseCase', () {
    group('입력 유효성 검사', () {
      test('빈 내용은 ValidationFailure를 던져야 한다', () async {
        expect(() => useCase.execute(''), throwsA(isA<ValidationFailure>()));
      });

      test('공백만 있는 내용은 ValidationFailure를 던져야 한다', () async {
        expect(() => useCase.execute('   '), throwsA(isA<ValidationFailure>()));
      });

      test('10자 미만은 ValidationFailure를 던져야 한다', () async {
        expect(
          () => useCase.execute('짧은내용'),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('최대 길이 초과는 ValidationFailure를 던져야 한다', () async {
        final longContent = 'a' * (AppConstants.diaryMaxLength + 1);
        expect(
          () => useCase.execute(longContent),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('최소 길이 이상이면 정상 처리되어야 한다', () async {
        final result = await useCase.execute('오늘 하루도 열심히 보냈다. 피곤하지만 뿌듯하다.');
        expect(result, isNotNull);
        expect(result.content, contains('오늘'));
      });
    });

    group('작성 날짜 (entryDate)', () {
      final fixedNow = DateTime(2026, 7, 2, 14, 30, 45, 123);

      DateTime capturedCreatedAt() {
        final captured = verify(
          () => mockRepository.createDiary(
            any(),
            imagePaths: any(named: 'imagePaths'),
            createdAt: captureAny(named: 'createdAt'),
          ),
        ).captured;
        return captured.last as DateTime;
      }

      setUp(() {
        useCase = AnalyzeDiaryUseCase(
          mockRepository,
          mockSettingsRepository,
          clock: FixedClock(fixedNow),
        );
      });

      test('entryDate 미지정 시 현재 시각으로 저장되어야 한다', () async {
        await useCase.execute('오늘 하루도 무사히 지나갔다. 감사한 하루였다.');
        expect(capturedCreatedAt(), fixedNow);
      });

      test('오늘 날짜 선택 시 현재 시각 그대로 저장되어야 한다', () async {
        await useCase.execute(
          '오늘 하루도 무사히 지나갔다. 감사한 하루였다.',
          entryDate: DateTime(2026, 7, 2),
        );
        expect(capturedCreatedAt(), fixedNow);
      });

      test('과거 날짜 선택 시 선택 날짜 + 현재 시분초로 저장되어야 한다', () async {
        await useCase.execute(
          '며칠 전 일이지만 기록해두고 싶은 하루였다.',
          entryDate: DateTime(2026, 6, 29),
        );
        expect(capturedCreatedAt(), DateTime(2026, 6, 29, 14, 30, 45, 123));
      });

      test('시각이 포함된 entryDate도 날짜 부분만 사용해야 한다', () async {
        await useCase.execute(
          '며칠 전 일이지만 기록해두고 싶은 하루였다.',
          entryDate: DateTime(2026, 6, 29, 23, 59),
        );
        expect(capturedCreatedAt(), DateTime(2026, 6, 29, 14, 30, 45, 123));
      });

      test('미래 날짜는 ValidationFailure를 던져야 한다', () async {
        expect(
          () => useCase.execute(
            '아직 오지 않은 날의 일기를 미리 써본다.',
            entryDate: DateTime(2026, 7, 3),
          ),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('자정 경계: 화면 진입 시 고정된 어제 날짜는 어제로 저장되어야 한다', () async {
        // 23:59 화면 진입(기본값 7/2) → 자정 넘겨 00:01에 저장하는 시나리오
        useCase = AnalyzeDiaryUseCase(
          mockRepository,
          mockSettingsRepository,
          clock: FixedClock(DateTime(2026, 7, 3, 0, 1)),
        );
        await useCase.execute(
          '자정 직전에 쓰기 시작한 오늘의 일기.',
          entryDate: DateTime(2026, 7, 2),
        );
        expect(capturedCreatedAt(), DateTime(2026, 7, 2, 0, 1));
      });
    });

    group('안전 필터링', () {
      test('자살 키워드가 포함되면 isEmergency가 true여야 한다', () async {
        final result = await useCase.execute('오늘 너무 힘들어서 자살하고 싶다는 생각이 들었다');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });

      test('죽고싶다 키워드가 포함되면 응급 처리되어야 한다', () async {
        final result = await useCase.execute('모든게 지쳐서 죽고싶다는 생각이 계속 든다');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
        expect(result.analysisResult?.empathyMessage, isNotEmpty);
      });

      test('자해 키워드가 포함되면 응급 처리되어야 한다', () async {
        final result = await useCase.execute('자해를 생각했다. 너무 힘들다.');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });

      test('응급 상황 시 적절한 action_item이 설정되어야 한다', () async {
        final result = await useCase.execute('세상에서 사라지고싶다는 생각이 든다');
        expect(result.analysisResult?.actionItem, contains('1393'));
      });

      test('응급 상황 시 sentimentScore가 1이어야 한다', () async {
        final result = await useCase.execute('끝내고싶다. 모든것을.');
        expect(result.analysisResult?.sentimentScore, 1);
      });

      test('응급 키워드 감지 시 DB 업데이트가 호출되어야 한다', () async {
        await useCase.execute('살기싫다. 모든게 무의미하다.');
        final captured = verify(
          () => mockRepository.updateDiary(captureAny()),
        ).captured;
        expect(captured, isNotEmpty);
        expect((captured.last as Diary).status, DiaryStatus.safetyBlocked);
      });

      test('암시적 위기 표현도 감지해야 한다', () async {
        final result = await useCase.execute('영원히 잠들면 좋겠다. 이 고통에서 벗어나고 싶다.');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });

      test('극단적 선택 표현을 감지해야 한다', () async {
        final result = await useCase.execute('극단적 선택을 생각하게 된다. 모든게 힘들다.');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });

      test('버티기 힘들다는 위기 표현을 감지해야 한다', () async {
        final result = await useCase.execute('더이상 못 버티겠다. 한계에 도달한 것 같다.');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });

      test('해방 표현을 감지해야 한다', () async {
        final result = await useCase.execute('이 고통 끝내고 해방되고싶다.');
        expect(result.status, DiaryStatus.safetyBlocked);
        expect(result.analysisResult?.isEmergency, true);
      });
    });

    group('정상 분석 플로우', () {
      test('응급 키워드가 없으면 정상 분석이 수행되어야 한다', () async {
        final result = await useCase.execute('오늘 프로젝트 마감이라 스트레스를 많이 받았다.');
        expect(result.status, DiaryStatus.analyzed);
        expect(result.analysisResult?.isEmergency, false);
      });

      test('정상 분석 시 키워드가 추출되어야 한다', () async {
        final result = await useCase.execute('회사에서 발표가 있어서 긴장했다. 잘 끝나서 다행이다.');
        expect(result.analysisResult?.keywords, isNotEmpty);
      });

      test('정상 분석 시 공감 메시지가 있어야 한다', () async {
        final result = await useCase.execute('친구와 맛있는 저녁을 먹고 기분이 좋았다.');
        expect(result.analysisResult?.empathyMessage, isNotEmpty);
      });

      test('정상 분석 시 sentimentScore가 1-10 범위여야 한다', () async {
        final result = await useCase.execute('오늘 운동을 열심히 했다. 피곤하지만 뿌듯하다.');
        expect(result.analysisResult?.sentimentScore, greaterThanOrEqualTo(1));
        expect(result.analysisResult?.sentimentScore, lessThanOrEqualTo(10));
      });
    });

    group('에러 처리', () {
      test('분석 실패 시에도 일기는 저장되어야 한다', () async {
        when(
          () => mockRepository.analyzeDiary(
            any(),
            character: any(named: 'character'),
            userName: any(named: 'userName'),
            imagePaths: any(named: 'imagePaths'),
          ),
        ).thenThrow(const Failure.api(message: 'API Error'));

        await expectLater(
          useCase.execute('오늘 하루는 평범하게 지나갔다.'),
          throwsA(isA<Failure>()),
        );
        verify(
          () => mockRepository.createDiary(
            any(),
            imagePaths: any(named: 'imagePaths'),
            createdAt: any(named: 'createdAt'),
          ),
        ).called(greaterThan(0));
      });
    });
  });
}
