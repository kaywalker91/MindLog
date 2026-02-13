import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/utils/validators.dart';

void main() {
  group('Validators', () {
    // ============================================================
    // validateDiaryContent
    // ============================================================
    group('validateDiaryContent', () {
      group('null/empty 입력', () {
        test('null 입력 시 에러 메시지를 반환한다', () {
          expect(Validators.validateDiaryContent(null), isNotNull);
          expect(Validators.validateDiaryContent(null), contains('입력'));
        });

        test('빈 문자열 시 에러 메시지를 반환한다', () {
          expect(Validators.validateDiaryContent(''), isNotNull);
        });

        test('공백만 있는 문자열 시 에러 메시지를 반환한다', () {
          expect(Validators.validateDiaryContent('   '), isNotNull);
        });
      });

      group('길이 검사', () {
        test('최소 길이 미만 시 에러 메시지를 반환한다', () {
          // AppConstants.diaryMinLength = 10
          final result = Validators.validateDiaryContent('짧은글');
          expect(result, isNotNull);
          expect(result, contains('최소'));
        });

        test('최소 길이 경계값(10자) 시 null을 반환한다', () {
          // 10자 한글 + 감정 키워드 포함
          final result = Validators.validateDiaryContent('오늘 하루 기분이 좋았어요');
          expect(result, isNull);
        });

        test('최대 길이 초과 시 에러 메시지를 반환한다', () {
          // AppConstants.diaryMaxLength = 5000
          final longContent = '오늘 하루 기분이 좋았다. ' * 500; // ~11500자
          final result = Validators.validateDiaryContent(longContent);
          expect(result, isNotNull);
          expect(result, contains('최대'));
        });

        test('최대 길이 이내 시 통과한다', () {
          // 적당한 길이 + 의미 있는 내용
          final result = Validators.validateDiaryContent(
            '오늘 하루는 정말 행복했다. 친구와 만나서 맛있는 것을 먹고 기분이 좋아졌다.',
          );
          expect(result, isNull);
        });
      });

      group('품질 검사 - 연속 공백', () {
        test('연속 3개 이상 공백이 있으면 에러를 반환한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정이   좋았다 행복한 하루였다',
          );
          expect(result, isNotNull);
          expect(result, contains('공백'));
        });

        test('정상 공백은 통과한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정이 좋았다. 행복한 하루였다.',
          );
          expect(result, isNull);
        });
      });

      group('품질 검사 - 반복 문자', () {
        test('6개 이상 연속 반복 문자가 있으면 에러를 반환한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정이 좋아아아아아아 행복한 하루',
          );
          expect(result, isNotNull);
          expect(result, contains('반복'));
        });

        test('5개 이하 반복은 통과한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정이 좋아아아 행복한 하루였다.',
          );
          expect(result, isNull);
        });
      });

      group('품질 검사 - 반복 단어', () {
        test('같은 단어 3연속 반복 시 에러를 반환한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정 감정 감정 이 좋았다 행복한 하루',
          );
          expect(result, isNotNull);
          expect(result, contains('반복'));
        });

        test('2번 반복은 통과한다', () {
          final result = Validators.validateDiaryContent(
            '오늘 감정 감정 이런저런 생각이 들었다',
          );
          expect(result, isNull);
        });
      });

      group('품질 검사 - 특수문자 비율', () {
        test('특수문자가 30% 초과 시 에러를 반환한다', () {
          final result = Validators.validateDiaryContent(
            '!!!???###\$\$\$%%%^^^&&&***오늘감정',
          );
          expect(result, isNotNull);
          expect(result, contains('특수문자'));
        });
      });

      group('품질 검사 - 의미 있는 내용', () {
        test('의미 있는 단어 없이 50자 미만이면 에러를 반환한다', () {
          final result = Validators.validateDiaryContent('아무말이나 적어봅니다 뭐라고 할까');
          expect(result, isNotNull);
          expect(result, contains('의미'));
        });

        test('감정 키워드가 포함되면 통과한다', () {
          final result = Validators.validateDiaryContent('오늘 기분이 좋았다 행복함');
          expect(result, isNull);
        });

        test('50자 이상이면 의미 키워드 없어도 통과한다', () {
          // 50자 이상의 일반 텍스트
          const longText =
              '아무말이나 적어봅니다 뭐라고 할까요 이것저것 해보고 있는데 잘 모르겠네요 이렇게 저렇게 써봅니다';
          expect(longText.length >= 50, isTrue);
          final result = Validators.validateDiaryContent(longText);
          expect(result, isNull);
        });
      });

      group('유효한 입력', () {
        test('정상적인 일기 내용은 null을 반환한다', () {
          expect(
            Validators.validateDiaryContent(
              '오늘은 정말 행복한 하루였다. 친구와 만나서 즐거운 시간을 보냈다.',
            ),
            isNull,
          );
        });

        test('감정 표현이 포함된 긴 글은 null을 반환한다', () {
          expect(
            Validators.validateDiaryContent(
              '오늘 하루는 불안하면서도 기대되는 날이었다. '
              '새로운 프로젝트를 시작했는데 잘할 수 있을지 걱정이 되면서도 '
              '설레는 마음이 있었다. 가족들의 응원이 큰 힘이 되었다.',
            ),
            isNull,
          );
        });
      });
    });

    // ============================================================
    // calculateTextQualityScore
    // ============================================================
    group('calculateTextQualityScore', () {
      test('빈 문자열은 0점을 반환한다', () {
        expect(Validators.calculateTextQualityScore(''), equals(0));
      });

      test('공백만 있는 문자열은 0점을 반환한다', () {
        expect(Validators.calculateTextQualityScore('   '), equals(0));
      });

      test('기본 점수는 50점이다', () {
        // 짧은 텍스트 (50자 미만, 문장 1개, 단어 10개 미만, 감정 0)
        final score = Validators.calculateTextQualityScore('짧은 글');
        expect(score, equals(50));
      });

      test('50자 이상이면 +10점', () {
        // 50자 이상, 문장 1개
        const text = '오늘은 기분이 좋은 하루였다 맛있는 밥을 먹고 산책을 했는데 기분이 좋아졌다 하루를 마무리 하며';
        expect(text.trim().length >= 50, isTrue);
        final score = Validators.calculateTextQualityScore(text);
        expect(score, greaterThanOrEqualTo(60)); // 50 + 10(길이)
      });

      test('100자 이상이면 추가 +10점', () {
        final text = '오늘은 기분이 좋은 하루였다. ' * 7; // ~133자
        expect(text.trim().length >= 100, isTrue);
        final score = Validators.calculateTextQualityScore(text);
        expect(score, greaterThanOrEqualTo(70)); // 50 + 20(길이)
      });

      test('200자 이상이면 추가 +10점', () {
        final text = '오늘은 기분이 좋은 하루였다. ' * 15; // ~285자
        expect(text.trim().length >= 200, isTrue);
        final score = Validators.calculateTextQualityScore(text);
        expect(score, greaterThanOrEqualTo(80)); // 50 + 30(길이)
      });

      test('문장이 2개 이상이면 +10점', () {
        // 2 sentences, short
        final score = Validators.calculateTextQualityScore(
          '오늘 하루가 좋았다. 기분이 좋다.',
        );
        // 50(기본) + 0(길이<50) + 10(문장>=2) = 60
        expect(score, greaterThanOrEqualTo(60));
      });

      test('문장이 3개 이상이면 +20점', () {
        final score = Validators.calculateTextQualityScore(
          '오늘 하루가 좋았다. 기분이 좋다. 행복하다.',
        );
        expect(score, greaterThanOrEqualTo(70)); // 50 + 20(문장)
      });

      test('고유 단어가 10개 이상이면 +10점', () {
        final score = Validators.calculateTextQualityScore(
          '오늘 하루 기분 좋은 날 친구 만남 행복 즐거운 시간 보냈다',
        );
        expect(score, greaterThanOrEqualTo(60));
      });

      test('고유 단어가 20개 이상이면 +20점 (10개 대신)', () {
        const text =
            '오늘 아침 일찍 일어나서 산책하고 커피 마시고 공부하고 점심 먹고 '
            '친구 만나서 영화 보고 저녁 식사 후 집에서 독서하며 하루를 마무리했다';
        final uniqueWords = text
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .toSet()
            .length;
        expect(uniqueWords >= 20, isTrue);
        final score = Validators.calculateTextQualityScore(text);
        // 단어 20개 이상이면 +20점 (10개 보너스 대체)
        expect(score, greaterThanOrEqualTo(70));
      });

      test('감정 단어가 1개 이상이면 +5점', () {
        final score = Validators.calculateTextQualityScore('오늘은 기쁨을 느꼈다');
        final baseScore = Validators.calculateTextQualityScore('오늘은 무언가를 느꼈다');
        expect(score, greaterThanOrEqualTo(baseScore));
      });

      test('감정 단어가 2개 이상이면 +10점', () {
        final score = Validators.calculateTextQualityScore('기쁨과 행복을 느낀 하루였다');
        expect(score, greaterThanOrEqualTo(55)); // 50 + 5(감정1) + 5(감정2)
      });

      test('점수는 0-100 범위로 제한된다', () {
        // 매우 긴 고품질 텍스트
        final highQuality =
            '오늘은 정말 행복한 하루였다. 기쁨과 만족감이 넘쳤다. 즐거움 속에서 평화를 느꼈다. '
                '설렘과 기대로 가득한 순간이었다. 불안함도 있었지만 괜찮았다. ' *
            10;
        final score = Validators.calculateTextQualityScore(highQuality);
        expect(score, lessThanOrEqualTo(100));
        expect(score, greaterThanOrEqualTo(0));
      });
    });

    // ============================================================
    // analyzeText
    // ============================================================
    group('analyzeText', () {
      test('TextAnalysisResult 필드가 올바르게 채워진다', () {
        final result = Validators.analyzeText('오늘은 행복한 하루였다. 기분이 좋았다.');

        expect(result.qualityScore, greaterThan(0));
        expect(result.characterCount, greaterThan(0));
        expect(result.wordCount, greaterThan(0));
        expect(result.emotionTone, isNotNull);
        expect(result.suggestions, isA<List<String>>());
      });

      test('빈 문자열은 0점 결과를 반환한다', () {
        final result = Validators.analyzeText('');

        expect(result.qualityScore, equals(0));
        expect(result.characterCount, equals(0));
      });

      group('감정 톤 분석', () {
        test('긍정 감정 단어가 많으면 positive를 반환한다', () {
          final result = Validators.analyzeText(
            '오늘은 정말 기쁨과 행복과 만족감이 넘치는 하루였다. 즐거움과 감사의 연속',
          );
          expect(result.emotionTone, equals(EmotionTone.positive));
        });

        test('부정 감정 단어가 많으면 negative를 반환한다', () {
          final result = Validators.analyzeText(
            '오늘은 불안하고 슬픔과 실망감이 가득한 하루였다. 화남과 두려움 속에서',
          );
          expect(result.emotionTone, equals(EmotionTone.negative));
        });

        test('감정 단어가 없거나 동일하면 neutral을 반환한다', () {
          final result = Validators.analyzeText('그냥 보통의 일상이었다. 평소처럼 지냈다.');
          expect(result.emotionTone, equals(EmotionTone.neutral));
        });
      });

      group('개선 제안 생성', () {
        test('낮은 품질 점수 시 제안을 생성한다', () {
          final result = Validators.analyzeText('짧은 글');
          expect(result.suggestions, isNotEmpty);
        });

        test('100자 미만 시 길게 작성 제안을 포함한다', () {
          final result = Validators.analyzeText('오늘 기분이 좋았다.');
          expect(result.suggestions.any((s) => s.contains('길게')), isTrue);
        });

        test('단어 10개 미만 시 문장 분리 제안을 포함한다', () {
          final result = Validators.analyzeText('짧은 글입니다');
          expect(result.suggestions.any((s) => s.contains('문장')), isTrue);
        });

        test('반복 글자가 있으면 반복 관련 제안을 포함한다', () {
          final result = Validators.analyzeText('좋아아아아 행복하다');
          expect(result.suggestions.any((s) => s.contains('반복')), isTrue);
        });

        test('오늘이 포함되면 특별했던 순간 제안을 포함한다', () {
          final result = Validators.analyzeText('오늘 뭐했다');
          expect(result.suggestions.any((s) => s.contains('오늘')), isTrue);
        });

        test('제안은 최대 3개까지만 반환한다', () {
          final result = Validators.analyzeText('짧은 오늘');
          expect(result.suggestions.length, lessThanOrEqualTo(3));
        });
      });
    });

    // ============================================================
    // getCharacterCount
    // ============================================================
    group('getCharacterCount', () {
      test('빈 문자열은 0을 반환한다', () {
        expect(Validators.getCharacterCount(''), equals(0));
      });

      test('앞뒤 공백을 제외하고 계산한다', () {
        expect(Validators.getCharacterCount('  안녕  '), equals(2));
      });

      test('정상 문자열의 길이를 반환한다', () {
        expect(Validators.getCharacterCount('안녕하세요'), equals(5));
      });
    });

    // ============================================================
    // isMaxLengthReached
    // ============================================================
    group('isMaxLengthReached', () {
      test('5000자 미만이면 false를 반환한다', () {
        expect(Validators.isMaxLengthReached('짧은 글'), isFalse);
      });

      test('5000자 이상이면 true를 반환한다', () {
        final longText = 'ㅁ' * 5000; // ignore: prefer_const_declarations
        expect(Validators.isMaxLengthReached(longText), isTrue);
      });

      test('경계값 4999자는 false를 반환한다', () {
        final text = 'ㅁ' * 4999; // ignore: prefer_const_declarations
        expect(Validators.isMaxLengthReached(text), isFalse);
      });

      test('경계값 5000자는 true를 반환한다', () {
        final text = 'ㅁ' * 5000; // ignore: prefer_const_declarations
        expect(Validators.isMaxLengthReached(text), isTrue);
      });
    });

    // ============================================================
    // getCharacterCountText
    // ============================================================
    group('getCharacterCountText', () {
      test('올바른 형식의 문자열을 반환한다', () {
        expect(Validators.getCharacterCountText('안녕'), equals('2/5000'));
      });

      test('빈 문자열은 0/5000을 반환한다', () {
        expect(Validators.getCharacterCountText(''), equals('0/5000'));
      });

      test('공백 포함 문자열은 trim된 길이를 사용한다', () {
        expect(Validators.getCharacterCountText('  안녕  '), equals('2/5000'));
      });
    });

    // ============================================================
    // TextAnalysisResult
    // ============================================================
    group('TextAnalysisResult', () {
      test('모든 필드가 올바르게 설정된다', () {
        final result = TextAnalysisResult(
          qualityScore: 75,
          characterCount: 100,
          wordCount: 20,
          emotionTone: EmotionTone.positive,
          suggestions: ['제안1', '제안2'],
        );

        expect(result.qualityScore, equals(75));
        expect(result.characterCount, equals(100));
        expect(result.wordCount, equals(20));
        expect(result.emotionTone, equals(EmotionTone.positive));
        expect(result.suggestions, hasLength(2));
      });
    });

    // ============================================================
    // EmotionTone
    // ============================================================
    group('EmotionTone', () {
      test('3가지 값이 존재한다', () {
        expect(EmotionTone.values, hasLength(3));
        expect(EmotionTone.values, contains(EmotionTone.positive));
        expect(EmotionTone.values, contains(EmotionTone.negative));
        expect(EmotionTone.values, contains(EmotionTone.neutral));
      });
    });
  });
}
