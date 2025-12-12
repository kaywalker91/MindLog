import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/data/dtos/analysis_response_parser.dart';

void main() {
  group('AnalysisResponseParser', () {
    test('정상적인 JSON 문자열을 파싱한다', () {
      const jsonStr = '''
      {
        "keywords": ["기쁨", "성취", "만족"],
        "sentiment_score": 8,
        "empathy_message": "정말 훌륭한 하루였네요!",
        "action_item": "스스로에게 칭찬 한 마디 해주기",
        "is_emergency": false
      }
      ''';

      final result = AnalysisResponseParser.parseString(jsonStr);

      expect(result['keywords'], hasLength(3));
      expect(result['sentiment_score'], 8);
      expect(result['is_emergency'], false);
    });

    test('마크다운 코드가 포함된 JSON을 파싱한다', () {
      const jsonStr = '''
      ```json
      {
        "keywords": ["불안", "걱정", "내일"],
        "sentiment_score": 3,
        "empathy_message": "많이 불안하시군요.",
        "action_item": "따뜻한 물 마시기",
        "is_emergency": false
      }
      ```
      ''';

      final result = AnalysisResponseParser.parseString(jsonStr);

      expect(result['keywords'], contains('불안'));
      expect(result['sentiment_score'], 3);
    });

    test('응급 상황(is_emergency: true)을 정확히 파싱한다', () {
      const jsonStr = '''
      {
        "keywords": ["죽음", "포기", "절망"],
        "sentiment_score": 1,
        "empathy_message": "...",
        "action_item": "전문가 상담",
        "is_emergency": true
      }
      ''';

      final result = AnalysisResponseParser.parseString(jsonStr);

      expect(result['is_emergency'], true);
    });

    test('자연어 응답에서 키워드와 내용을 추출한다', () {
      const rawText = '''
      분석 결과입니다.
      키워드: 행복, 즐거움, 휴식
      감정 점수: 7점
      공감 메시지: "참 좋은 하루를 보내셨네요."
      추천 행동: 좋아하는 음악 듣기
      ''';

      final result = AnalysisResponseParser.parseString(rawText);

      expect(result['keywords'], isNotEmpty);
      expect(result['sentiment_score'], 7);
      expect(result['is_emergency'], false); // 자연어 파싱 기본값
    });

    test('불완전한 JSON 입력 시 자연어 파싱 등으로 복구하거나 에러를 처리한다', () {
      const brokenJson = '{ "keywords": ["실수"], ... }'; // Invalid JSON
      
      // parseString 내부는 try-catch로 fallback 처리됨
      final result = AnalysisResponseParser.parseString(brokenJson);
      
      // Fallback 로직 확인
      expect(result['keywords'], isNotEmpty);
      expect(result['is_emergency'], false);
    });
  });
}
