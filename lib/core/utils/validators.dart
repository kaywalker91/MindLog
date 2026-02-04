import '../constants/app_constants.dart';

/// 입력 유효성 검사 유틸리티
class Validators {
  Validators._();

  /// 일기 내용 유효성 검사 (강화버전)
  ///
  /// 반환값:
  /// - null: 유효함
  /// - String: 에러 메시지
  static String? validateDiaryContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return '내용을 입력해주세요.';
    }

    final trimmedContent = content.trim();

    // 기본 길이 검사
    if (trimmedContent.length < AppConstants.diaryMinLength) {
      return '최소 ${AppConstants.diaryMinLength}자 이상 입력해주세요.\n현재 ${trimmedContent.length}자 입니다.';
    }

    if (trimmedContent.length > AppConstants.diaryMaxLength) {
      return '최대 ${AppConstants.diaryMaxLength}자까지 입력 가능합니다.\n현재 ${trimmedContent.length}자 입니다.';
    }

    // 내용 품질 검사
    final qualityError = _validateContentQuality(trimmedContent);
    if (qualityError != null) {
      return qualityError;
    }

    return null;
  }

  /// 내용 품질 검사
  static String? _validateContentQuality(String content) {
    // 1. 연속된 공백 검사
    if (content.contains(RegExp(r'\s{3,}'))) {
      return '너무 많은 공백이 있습니다. 적절하게 수정해주세요.';
    }

    // 2. 반복 문자 검사
    if (content.contains(RegExp(r'(.)\1{5,}'))) {
      return '반복되는 문자가 너무 많습니다. 자연스럽게 수정해주세요.';
    }

    // 3. 의미없는 반복 단어 검사
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    if (words.length >= 3) {
      for (int i = 0; i < words.length - 2; i++) {
        if (words[i] == words[i + 1] && words[i + 1] == words[i + 2]) {
          return '같은 단어가 반복되고 있습니다. 다양하게 표현해주세요.';
        }
      }
    }

    // 4. 불필요한 특수문자 과도 사용 검사
    final specialCharCount = content
        .replaceAll(RegExp(r'[가-힣a-zA-Z0-9\s]'), '')
        .length;
    if (specialCharCount > content.length * 0.3) {
      return '특수문자가 너무 많습니다. 문장으로 작성해주세요.';
    }

    // 5. 의미 있는 내용인지 검사 (기본적인 단어 포함 확인)
    final meaningfulWords = [
      '감정',
      '느낌',
      '생각',
      '생각',
      '마음',
      '생각하다',
      '느낀다',
      '생각한다',
      '일상',
      '하루',
      '일',
      '하고',
      '있어요',
      '있었다',
      '오늘',
      '어제',
      '친구',
      '가족',
      '일',
      '공부',
      '스트레스',
      '기분',
      '불안',
      '행복',
      '슬픔',
      '기쁨',
      '화남',
      '실망',
      '만족',
      '피곤',
      '지침',
    ];

    final hasMeaningfulContent = meaningfulWords.any(
      (word) => content.toLowerCase().contains(word),
    );

    if (!hasMeaningfulContent && content.length < 50) {
      return '더 의미 있는 내용을 작성해주세요. 감정이나 상황을 표현해보세요.';
    }

    return null; // 유효함
  }

  /// 텍스트 품질 점수 계산 (0-100)
  static int calculateTextQualityScore(String content) {
    if (content.trim().isEmpty) return 0;

    int score = 50; // 기본 점수

    // 길이 점수 (10-30점)
    final length = content.trim().length;
    if (length >= 50) score += 10;
    if (length >= 100) score += 10;
    if (length >= 200) score += 10;

    // 문장 구조 점수 (0-20점)
    final sentences = content
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty);
    if (sentences.length >= 2) score += 10;
    if (sentences.length >= 3) score += 10;

    // 다양한 단어 점수 (0-20점)
    final uniqueWords = content.toLowerCase().split(RegExp(r'\s+')).toSet();
    if (uniqueWords.length >= 10) score += 10;
    if (uniqueWords.length >= 20) score += 20;

    // 감정 표현 점수 (0-10점)
    final emotionWords = [
      '기쁨',
      '슬픔',
      '화남',
      '불안',
      '만족',
      '실망',
      '놀람',
      '두려움',
      '기대',
      '설렘',
      '평화',
      '행복',
      '즐거움',
      '즐겁다',
      '시끄럽다',
      '조용하다',
      '불편하다',
      '편안하다',
    ];

    final emotionCount = emotionWords
        .where((word) => content.toLowerCase().contains(word))
        .length;
    if (emotionCount >= 1) score += 5;
    if (emotionCount >= 2) score += 5;

    return score.clamp(0, 100);
  }

  /// 텍스트 분석 결과
  static TextAnalysisResult analyzeText(String content) {
    final qualityScore = calculateTextQualityScore(content);
    final characterCount = getCharacterCount(content);
    final wordCount = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    // 감정色调 분석
    final emotionAnalysis = _analyzeEmotionalTone(content);

    return TextAnalysisResult(
      qualityScore: qualityScore,
      characterCount: characterCount,
      wordCount: wordCount,
      emotionTone: emotionAnalysis,
      suggestions: _generateSuggestions(content, qualityScore),
    );
  }

  /// 감정色调 분석
  static EmotionTone _analyzeEmotionalTone(String content) {
    final positiveEmotions = ['기쁨', '행복', '즐거움', '만족', '감사', '밝다', '설렘', '기대'];
    final negativeEmotions = ['불안', '슬픔', '화남', '실망', '두려움', '어둡', '힘들', '피곤'];
    final neutralEmotions = ['그냥', '보통', '일상', '평소', '약간', '간단'];

    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;

    final lowerContent = content.toLowerCase();

    positiveCount = positiveEmotions
        .where((emotion) => lowerContent.contains(emotion))
        .length;
    negativeCount = negativeEmotions
        .where((emotion) => lowerContent.contains(emotion))
        .length;
    neutralCount = neutralEmotions
        .where((emotion) => lowerContent.contains(emotion))
        .length;

    if (positiveCount > negativeCount && positiveCount > neutralCount) {
      return EmotionTone.positive;
    } else if (negativeCount > positiveCount && negativeCount > neutralCount) {
      return EmotionTone.negative;
    } else {
      return EmotionTone.neutral;
    }
  }

  /// 개선 제안 생성
  static List<String> _generateSuggestions(String content, int qualityScore) {
    final suggestions = <String>[];

    if (qualityScore < 50) {
      suggestions.add('더 구체적으로 어떤 상황인지 설명해보세요.');
      suggestions.add('감정을 더 표현해보세요. 예: "기분이 좋다", "조금 불안했다" 등');
    }

    if (content.length < 100) {
      suggestions.add('조금 더 길게 작성해보세요. 현재 상황이나 느낀 점을 더 자세히 표현해주세요.');
    }

    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length < 10) {
      suggestions.add('여러 문장을 나누어 작성하면 더 좋습니다.');
    }

    if (content.contains(RegExp(r'(.)\1{3,}'))) {
      suggestions.add('반복되는 글자를 줄여 자연스럽게 수정해주세요.');
    }

    // 감정 표현 제안
    if (content.toLowerCase().contains('오늘')) {
      suggestions.add('오늘 하루 중 특별했던 순간이나 느낀 점을 더 추가해보세요.');
    }

    return suggestions.take(3).toList();
  }

  /// 글자 수 계산
  static int getCharacterCount(String content) {
    return content.trim().length;
  }

  /// 최대 글자 수 도달 여부
  static bool isMaxLengthReached(String content) {
    return content.trim().length >= AppConstants.diaryMaxLength;
  }

  /// 글자 수 표시 텍스트 생성
  static String getCharacterCountText(String content) {
    final current = getCharacterCount(content);
    final max = AppConstants.diaryMaxLength;
    return '$current/$max';
  }
}

/// 텍스트 품질 결과
class TextAnalysisResult {
  final int qualityScore;
  final int characterCount;
  final int wordCount;
  final EmotionTone emotionTone;
  final List<String> suggestions;

  TextAnalysisResult({
    required this.qualityScore,
    required this.characterCount,
    required this.wordCount,
    required this.emotionTone,
    required this.suggestions,
  });
}

/// 감정色调
enum EmotionTone { positive, negative, neutral }
