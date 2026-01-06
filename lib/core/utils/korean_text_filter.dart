import 'package:characters/characters.dart';

/// 한글 텍스트 필터링 유틸리티
///
/// AI 응답에서 한문(중국어), 일본어, 영어 등 비한글 문자를 필터링합니다.
/// Llama 3.3 70B 모델의 다국어 혼입 문제 해결을 위해 사용됩니다.
class KoreanTextFilter {
  KoreanTextFilter._();

  /// 한문(CJK Unified Ideographs) 범위: U+4E00 ~ U+9FFF
  static final RegExp _chinesePattern = RegExp(r'[\u4E00-\u9FFF]');

  /// 일본어 히라가나: U+3040 ~ U+309F
  static final RegExp _hiraganaPattern = RegExp(r'[\u3040-\u309F]');

  /// 일본어 가타카나: U+30A0 ~ U+30FF
  static final RegExp _katakanaPattern = RegExp(r'[\u30A0-\u30FF]');

  /// 한글 범위: U+AC00 ~ U+D7AF (완성형), U+1100 ~ U+11FF (자모)
  static final RegExp _koreanPattern = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF]');

  /// 영어 단어 패턴 (2글자 이상의 순수 영문 단어)
  /// 한글 문장 사이에 섞인 영어 단어를 감지
  static final RegExp _englishWordPattern = RegExp(r'\b[a-zA-Z]{2,}\b');

  /// 허용되는 문자: 한글, 숫자, 공백, 기본 구두점 (영문 제외)
  static final RegExp _koreanOnlyAllowedPattern =
      RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF0-9\s.,!?()~\-"\u0027\u00B7:;]');

  /// 허용되는 문자: 한글, 영문, 숫자, 공백, 기본 구두점 (레거시 호환용)
  static final RegExp _allowedPattern =
      RegExp(r'[\uAC00-\uD7AF\u1100-\u11FFa-zA-Z0-9\s.,!?()~\-"\u0027\u00B7:;]');

  /// 텍스트에 한문(중국어)이 포함되어 있는지 확인
  static bool containsChinese(String text) {
    return _chinesePattern.hasMatch(text);
  }

  /// 텍스트에 일본어가 포함되어 있는지 확인
  static bool containsJapanese(String text) {
    return _hiraganaPattern.hasMatch(text) || _katakanaPattern.hasMatch(text);
  }

  /// 텍스트에 영어 단어가 포함되어 있는지 확인
  static bool containsEnglishWord(String text) {
    return _englishWordPattern.hasMatch(text);
  }

  /// 텍스트에 비한글 외국어(한문, 일본어, 영어)가 포함되어 있는지 확인
  static bool containsForeignLanguage(String text) {
    return containsChinese(text) || containsJapanese(text) || containsEnglishWord(text);
  }

  /// 텍스트에 한글이 포함되어 있는지 확인
  static bool containsKorean(String text) {
    return _koreanPattern.hasMatch(text);
  }

  /// 텍스트에서 영어 단어를 제거
  static String removeEnglishWords(String text) {
    return text.replaceAll(_englishWordPattern, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 이모지 패턴 (기본 이모지 범위)
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F600}-\u{1F64F}]',
    unicode: true,
  );

  /// 텍스트에서 한문/일본어/영어 문자를 제거하고 한글만 남김
  ///
  /// [text] 필터링할 텍스트
  /// [preserveEnglish] true면 영문/숫자도 보존 (기본값: false로 변경)
  /// [preserveEmoji] true면 이모지도 보존 (기본값: true)
  static String filterToKorean(String text, {bool preserveEnglish = false, bool preserveEmoji = true}) {
    if (text.isEmpty) return text;

    // 먼저 영어 단어 제거
    String processed = text;
    if (!preserveEnglish) {
      processed = removeEnglishWords(processed);
    }

    final buffer = StringBuffer();
    final pattern = preserveEnglish ? _allowedPattern : _koreanOnlyAllowedPattern;
    
    // 문자열을 grapheme cluster 단위로 처리 (이모지 안전)
    final characters = processed.characters;
    for (final char in characters) {
      // 이모지인 경우 보존
      if (preserveEmoji && _emojiPattern.hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      
      // 한문/일본어 제거
      if (_chinesePattern.hasMatch(char) || 
          _hiraganaPattern.hasMatch(char) || 
          _katakanaPattern.hasMatch(char)) {
        continue;
      }
      
      // 허용된 문자인지 확인
      if (pattern.hasMatch(char)) {
        buffer.write(char);
      }
    }

    // 연속된 공백 정리
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 키워드 배열을 필터링하여 한글만 남김
  ///
  /// [keywords] 필터링할 키워드 리스트
  /// [fallbackKeywords] 유효한 키워드가 없을 때 사용할 기본값
  static List<String> filterKeywords(
    List<String> keywords, {
    List<String>? fallbackKeywords,
  }) {
    final filtered = <String>[];

    for (final keyword in keywords) {
      // 한문/일본어가 포함된 키워드는 제외
      if (containsForeignLanguage(keyword)) {
        continue;
      }

      // 한글이 포함된 키워드만 추가
      final cleanKeyword = filterToKorean(keyword).trim();
      if (cleanKeyword.isNotEmpty && containsKorean(cleanKeyword)) {
        filtered.add(cleanKeyword);
      }
    }

    // 유효한 키워드가 없으면 기본값 반환
    if (filtered.isEmpty) {
      return fallbackKeywords ?? ['감정', '일상', '생각'];
    }

    return filtered;
  }

  /// empathy_message 또는 action_item 텍스트 필터링
  ///
  /// 한문이 포함된 경우 해당 부분만 제거하고 나머지 텍스트 유지
  /// [text] 필터링할 텍스트
  /// [fallbackText] 결과가 비어있을 때 사용할 기본값
  static String filterMessage(String text, {String? fallbackText}) {
    if (text.isEmpty) {
      return fallbackText ?? '';
    }

    // 한문/일본어가 없으면 그대로 반환
    if (!containsForeignLanguage(text)) {
      return text;
    }

    // 한문/일본어 제거
    final filtered = filterToKorean(text);

    // 결과가 너무 짧거나 비어있으면 기본값 반환
    if (filtered.length < 10 || !containsKorean(filtered)) {
      return fallbackText ?? text;
    }

    return filtered;
  }

  /// AI 분석 응답 전체를 검증하고 필터링
  ///
  /// [json] 파싱된 AI 응답 JSON
  /// 반환값: 필터링된 JSON (원본 수정 없음)
  static Map<String, dynamic> filterAnalysisResponse(
      Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);

    // keywords 필터링
    if (result['keywords'] is List) {
      final keywords = (result['keywords'] as List).cast<String>();
      result['keywords'] = filterKeywords(keywords);
    }

    // empathy_message 필터링
    if (result['empathy_message'] is String) {
      result['empathy_message'] = filterMessage(
        result['empathy_message'] as String,
        fallbackText: '오늘 하루도 수고 많으셨어요. 당신의 감정은 소중합니다.',
      );
    }

    // action_item 필터링
    if (result['action_item'] is String) {
      result['action_item'] = filterMessage(
        result['action_item'] as String,
        fallbackText: '따뜻한 차 한 잔의 여유를 가져보세요.',
      );
    }

    return result;
  }
}
