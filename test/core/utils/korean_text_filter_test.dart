import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/utils/korean_text_filter.dart';

void main() {
  group('KoreanTextFilter', () {
    group('containsChinese', () {
      test('한문이 포함된 텍스트를 감지한다', () {
        expect(KoreanTextFilter.containsChinese('안녕하세요 你好'), isTrue);
        expect(KoreanTextFilter.containsChinese('오늘 기분이 좋다'), isFalse);
      });
    });

    group('containsJapanese', () {
      test('일본어 히라가나를 감지한다', () {
        expect(KoreanTextFilter.containsJapanese('こんにちは'), isTrue);
      });

      test('일본어 가타카나를 감지한다', () {
        expect(KoreanTextFilter.containsJapanese('カタカナ'), isTrue);
      });

      test('한글만 있는 텍스트는 감지하지 않는다', () {
        expect(KoreanTextFilter.containsJapanese('안녕하세요'), isFalse);
      });
    });

    group('containsEnglishWord', () {
      test('영어 단어가 포함된 텍스트를 감지한다', () {
        expect(KoreanTextFilter.containsEnglishWord('오늘 happy한 날'), isTrue);
      });

      test('한글만 있는 텍스트는 감지하지 않는다', () {
        expect(KoreanTextFilter.containsEnglishWord('오늘 기분이 좋다'), isFalse);
      });
    });

    group('containsKorean', () {
      test('한글이 포함된 텍스트를 감지한다', () {
        expect(KoreanTextFilter.containsKorean('안녕하세요'), isTrue);
        expect(KoreanTextFilter.containsKorean('Hello'), isFalse);
      });
    });

    group('filterToKorean', () {
      test('한문을 제거하고 한글만 남긴다', () {
        final result = KoreanTextFilter.filterToKorean('안녕 你好 반가워');
        expect(result, contains('안녕'));
        expect(result, contains('반가워'));
        expect(result, isNot(contains('你好')));
      });

      test('빈 문자열은 그대로 반환한다', () {
        expect(KoreanTextFilter.filterToKorean(''), isEmpty);
      });

      test('preserveEnglish=true면 영어를 보존한다', () {
        final result = KoreanTextFilter.filterToKorean(
          '오늘은 happy한 날',
          preserveEnglish: true,
        );
        expect(result, contains('happy'));
      });
    });

    group('filterKeywords', () {
      test('한글 키워드만 필터링한다', () {
        final keywords = ['기쁨', 'happy', '悲伤', '슬픔'];
        final result = KoreanTextFilter.filterKeywords(keywords);

        expect(result, contains('기쁨'));
        expect(result, contains('슬픔'));
        expect(result, isNot(contains('happy')));
        expect(result, isNot(contains('悲伤')));
      });

      test('유효한 키워드가 없으면 기본값을 반환한다', () {
        final keywords = ['happy', '悲伤'];
        final result = KoreanTextFilter.filterKeywords(keywords);

        // 기본값: ['감정', '일상', '생각']
        expect(result, isNotEmpty);
      });

      test('fallbackKeywords를 지정할 수 있다', () {
        final keywords = <String>[];
        final result = KoreanTextFilter.filterKeywords(
          keywords,
          fallbackKeywords: ['대체', '키워드'],
        );

        expect(result, equals(['대체', '키워드']));
      });
    });

    group('filterMessage', () {
      test('외국어가 없는 메시지는 그대로 반환한다', () {
        const message = '오늘 하루도 수고 많으셨어요.';
        expect(KoreanTextFilter.filterMessage(message), equals(message));
      });

      test('외국어가 포함된 메시지는 필터링한다', () {
        const message = '오늘 你好 하루도 수고하셨어요';
        final result = KoreanTextFilter.filterMessage(message);
        expect(result, isNot(contains('你好')));
      });

      test('빈 메시지는 fallbackText를 반환한다', () {
        final result = KoreanTextFilter.filterMessage(
          '',
          fallbackText: '기본 메시지',
        );
        expect(result, equals('기본 메시지'));
      });
    });

    group('filterAnalysisResponse', () {
      test('AI 응답의 모든 필드를 필터링한다', () {
        final response = {
          'keywords': ['기쁨', 'happy', '悲伤'],
          'empathy_message': '오늘 你好 하루도 수고하셨어요',
          'action_item': '따뜻한 茶 한 잔 마시세요',
        };

        final result = KoreanTextFilter.filterAnalysisResponse(response);

        // keywords가 필터링됨
        expect(result['keywords'], contains('기쁨'));
        expect(result['keywords'], isNot(contains('happy')));

        // empathy_message가 필터링됨
        expect(result['empathy_message'], isNot(contains('你好')));

        // action_item이 필터링됨
        expect(result['action_item'], isNot(contains('茶')));
      });
    });
  });
}
