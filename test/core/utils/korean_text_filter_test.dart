import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/utils/korean_text_filter.dart';

void main() {
  group('KoreanTextFilter', () {
    // ============================================================
    // 기존 기능 테스트
    // ============================================================
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

    // ============================================================
    // 신규 기능 테스트: 한자어 대체
    // ============================================================
    group('processKoreanText - 한자어 대체', () {
      test('감정 관련 한자어를 한글로 대체한다', () {
        final result = KoreanTextFilter.processKoreanText('希望을 가지세요');
        expect(result, equals('희망을 가지세요'));
      });

      test('여러 한자어가 포함된 텍스트를 모두 대체한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '感情을 이해하고 幸福을 찾으세요',
        );
        expect(result, equals('감정을 이해하고 행복을 찾으세요'));
      });

      test('사전에 없는 한자어는 제거한다', () {
        final result = KoreanTextFilter.processKoreanText('未知의 감정');
        expect(result, isNot(contains('未知')));
        expect(result, contains('감정'));
      });

      test('한자어와 일본어가 혼합된 경우 모두 처리한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '希望と감정을 가지세요',
        );
        expect(result, contains('희망'));
        expect(result, isNot(contains('と')));
      });
    });

    // ============================================================
    // 신규 기능 테스트: 중복 조사 제거
    // ============================================================
    group('processKoreanText - 중복 조사 제거', () {
      test('에게를 → 에게로 교정한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '친구에게를 감정을 전해주세요',
        );
        expect(result, equals('친구에게 감정을 전해주세요'));
      });

      test('한테를 → 한테로 교정한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '동생한테를 말해주세요',
        );
        expect(result, equals('동생한테 말해주세요'));
      });

      test('에서를 → 에서로 교정한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '학교에서를 공부하세요',
        );
        expect(result, equals('학교에서 공부하세요'));
      });

      test('여러 중복 조사가 있는 경우 모두 교정한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '친구에게를 말하고 학교에서를 공부하세요',
        );
        expect(result, equals('친구에게 말하고 학교에서 공부하세요'));
      });
    });

    // ============================================================
    // 신규 기능 테스트: 조사 교정 (구분자 패턴 기반)
    // ============================================================
    group('processKoreanText - 조사 교정', () {
      test('받침O + 를 → 을로 교정한다 (구분자 앞)', () {
        // "책"은 받침 있음 → "책를" → "책을"
        final result = KoreanTextFilter.processKoreanText('책를 읽어보세요.');
        expect(result, equals('책을 읽어보세요.'));
      });

      test('받침X + 을 → 를로 교정한다 (구분자 앞)', () {
        // "나"는 받침 없음 → "나을" → "나를"
        final result = KoreanTextFilter.processKoreanText('나을 봐주세요.');
        expect(result, equals('나를 봐주세요.'));
      });

      test('정상적인 조사는 변경하지 않는다', () {
        final result = KoreanTextFilter.processKoreanText('책을 읽어보세요.');
        expect(result, equals('책을 읽어보세요.'));
      });

      test('나이 같은 단어는 변경하지 않는다 (구분자 없음)', () {
        // "나이"는 구분자 앞이 아니므로 변경하지 않음
        final result = KoreanTextFilter.processKoreanText('나이가 많아요');
        expect(result, equals('나이가 많아요'));
      });

      test('문장 끝의 조사도 교정한다', () {
        final result = KoreanTextFilter.processKoreanText('책를');
        expect(result, equals('책을'));
      });

      test('마침표 앞의 조사를 교정한다', () {
        final result = KoreanTextFilter.processKoreanText('그 책를.');
        expect(result, equals('그 책을.'));
      });
    });

    // ============================================================
    // 통합 테스트: 복합 케이스
    // ============================================================
    group('processKoreanText - 복합 케이스', () {
      test('한자어 + 중복 조사 + 조사 오류 복합 케이스', () {
        const input = '希望를 가지세요. 친구에게를 感情을 전해주세요.';
        final result = KoreanTextFilter.processKoreanText(input);
        expect(result, equals('희망을 가지세요. 친구에게 감정을 전해주세요.'));
      });

      test('빈 문자열은 그대로 반환한다', () {
        expect(KoreanTextFilter.processKoreanText(''), isEmpty);
      });

      test('한글만 있는 정상 문장은 변경하지 않는다', () {
        const input = '오늘 하루도 수고 많으셨어요.';
        expect(KoreanTextFilter.processKoreanText(input), equals(input));
      });

      test('이모지는 보존한다', () {
        final result = KoreanTextFilter.processKoreanText(
          '希望을 가지세요 😊',
          preserveEmoji: true,
        );
        expect(result, contains('😊'));
        expect(result, contains('희망'));
      });
    });

    // ============================================================
    // filterMessage 업데이트 테스트
    // ============================================================
    group('filterMessage - 신규 파이프라인', () {
      test('한자어를 한글로 대체하고 조사를 교정한다', () {
        final result = KoreanTextFilter.filterMessage(
          '希望를 가지세요. 親구에게를 感情을 전해주세요.',
        );
        expect(result, contains('희망을'));
        expect(result, isNot(contains('에게를')));
      });

      test('외국어 없이 조사 오류만 있는 경우도 교정한다', () {
        final result = KoreanTextFilter.filterMessage('책를 읽어보세요.');
        expect(result, equals('책을 읽어보세요.'));
      });

      test('외국어 없고 오류 없는 문장은 그대로 반환한다', () {
        const input = '오늘 하루도 수고 많으셨어요.';
        expect(KoreanTextFilter.filterMessage(input), equals(input));
      });

      test('중복 조사가 있는 경우 전체 파이프라인을 적용한다', () {
        final result = KoreanTextFilter.filterMessage('친구에게를 말해주세요.');
        expect(result, equals('친구에게 말해주세요.'));
      });
    });
  });
}
