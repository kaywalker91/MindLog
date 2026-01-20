import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late AnalyzeDiaryUseCase useCase;
  late MockDiaryRepository mockRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    mockSettingsRepository = MockSettingsRepository();
    useCase = AnalyzeDiaryUseCase(mockRepository, mockSettingsRepository);
  });

  tearDown(() {
    mockRepository.reset();
    mockSettingsRepository.reset();
  });

  group('AnalyzeDiaryUseCase', () {
    group('입력 유효성 검사', () {
      test('빈 내용은 ValidationFailure를 던져야 한다', () async {
        expect(
          () => useCase.execute(''),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('공백만 있는 내용은 ValidationFailure를 던져야 한다', () async {
        expect(
          () => useCase.execute('   '),
          throwsA(isA<ValidationFailure>()),
        );
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
        expect(mockRepository.updatedDiaries, isNotEmpty);
        expect(mockRepository.updatedDiaries.last.status, DiaryStatus.safetyBlocked);
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
        mockRepository.shouldThrowOnAnalyze = true;
        mockRepository.errorMessage = 'API Error';

        await expectLater(
          useCase.execute('오늘 하루는 평범하게 지나갔다.'),
          throwsA(isA<Failure>()),
        );
        expect(mockRepository.savedDiaries, isNotEmpty);
      });
    });
  });
}
