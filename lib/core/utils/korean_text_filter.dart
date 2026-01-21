import 'package:characters/characters.dart';

/// 한글 텍스트 필터링 유틸리티
///
/// AI 응답에서 한문(중국어), 일본어, 영어 등 비한글 문자를 필터링합니다.
/// Llama 3.3 70B 모델의 다국어 혼입 문제 해결을 위해 사용됩니다.
///
/// ## 주요 기능
/// - 한자어 → 한글 대체 (예: 希望 → 희망)
/// - 중복 조사 제거 (예: 에게를 → 에게)
/// - 안전한 조사 교정 (예: 책를 → 책을, 구분자 패턴 기반)
class KoreanTextFilter {
  KoreanTextFilter._();

  // ============================================================
  // 한자어 대체 사전 (감정/심리 관련 자주 등장하는 한자어)
  // ============================================================
  static const Map<String, String> _chineseToKorean = {
    // 감정 관련
    '希望': '희망',
    '感情': '감정',
    '幸福': '행복',
    '悲傷': '슬픔',
    '焦慮': '불안',
    '憂鬱': '우울',
    '滿足': '만족',
    '成就': '성취',
    '壓力': '압박',
    '疲勞': '피로',
    '緊張': '긴장',
    '平穩': '평온',
    '安心': '안심',
    '憤怒': '분노',
    '恐懼': '공포',
    '驚訝': '놀람',
    // 일상 관련
    '休息': '휴식',
    '運動': '운동',
    '睡眠': '수면',
    '飲食': '식사',
    '工作': '업무',
    '關係': '관계',
    '健康': '건강',
    '生活': '생활',
    // 기타
    '時間': '시간',
    '努力': '노력',
    '目標': '목표',
    '問題': '문제',
    '解決': '해결',
    '理解': '이해',
    '支持': '지지',
    '感謝': '감사',
  };

  // ============================================================
  // 중복 조사 패턴 (잘못된 → 올바른)
  // 주의: 단어 내부에서 오인식 되지 않도록 구분자 앞에서만 매칭
  // ============================================================
  static final List<(RegExp, String)> _duplicateParticles = [
    // 확실한 중복 조사 (오인식 가능성 낮음)
    (RegExp(r'에게를([\s.,!?~\-)":\u0027]|$)'), r'에게$1'),
    (RegExp(r'에서를([\s.,!?~\-)":\u0027]|$)'), r'에서$1'),
    (RegExp(r'에게가([\s.,!?~\-)":\u0027]|$)'), r'에게$1'),
    (RegExp(r'한테를([\s.,!?~\-)":\u0027]|$)'), r'한테$1'),
    (RegExp(r'께를([\s.,!?~\-)":\u0027]|$)'), r'께$1'),
    (RegExp(r'으로를([\s.,!?~\-)":\u0027]|$)'), r'으로$1'),
    (RegExp(r'을를([\s.,!?~\-)":\u0027]|$)'), r'을$1'),
    (RegExp(r'를를([\s.,!?~\-)":\u0027]|$)'), r'를$1'),
    // 주의: 이가/가가 패턴은 오인식 가능성이 높아 제외
    // 예: "나이가" → "나이" (X), "모기가" → "모기" (X)
  ];

  // ============================================================
  // 안전한 조사 교정 패턴 (구분자 기반)
  // 받침O + 를 + (구분자) → 받침O + 을 + (구분자)
  // 받침X + 을 + (구분자) → 받침X + 를 + (구분자)
  // ============================================================
  /// 받침 있는 글자 + 를 + 구분자 → 을로 교정
  static final RegExp _wrongReulPattern =
      RegExp(r'([\uAC00-\uD7AF])를([\s.,!?~\-)":\u0027]|$)');

  /// 받침 없는 글자 + 을 + 구분자 → 를로 교정
  static final RegExp _wrongEulPattern =
      RegExp(r'([\uAC00-\uD7AF])을([\s.,!?~\-)":\u0027]|$)');

  // 주의: 이/가 주격조사 교정은 오인식 가능성이 높아 비활성화
  // 예: "나이가" 같은 정상적인 단어를 "나가가"로 잘못 바꿀 수 있음

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

  // ============================================================
  // 받침 판별 함수
  // ============================================================

  /// 한글 음절의 종성(받침) 인덱스 반환
  /// - 0: 받침 없음
  /// - 1~27: 받침 있음 (ㄱ, ㄲ, ㄳ, ㄴ, ...)
  ///
  /// 한글 유니코드: (초성 * 21 + 중성) * 28 + 종성 + 0xAC00
  /// 따라서 종성 = (code - 0xAC00) % 28
  static int _getJongsungIndex(String char) {
    if (char.isEmpty) return 0;
    final code = char.codeUnitAt(0);
    // 한글 완성형 범위: U+AC00 ~ U+D7AF
    if (code < 0xAC00 || code > 0xD7AF) return 0;
    return (code - 0xAC00) % 28;
  }

  /// 한글 음절에 받침이 있는지 확인
  static bool _hasFinalConsonant(String char) {
    return _getJongsungIndex(char) > 0;
  }

  // ============================================================
  // 텍스트 처리 파이프라인
  // ============================================================

  /// 한자어를 한글로 대체
  ///
  /// 사전에 등록된 한자어만 대체하여 문맥을 보존합니다.
  static String _replaceChineseWithKorean(String text) {
    if (text.isEmpty) return text;

    String result = text;
    for (final entry in _chineseToKorean.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// 중복 조사 제거
  ///
  /// 예: "친구에게를" → "친구에게"
  static String _removeDuplicateParticles(String text) {
    if (text.isEmpty) return text;

    String result = text;
    for (final (pattern, replacement) in _duplicateParticles) {
      // replacement에 $1 같은 캡처 그룹 참조가 있으므로 replaceAllMapped 사용
      result = result.replaceAllMapped(pattern, (match) {
        // 캡처 그룹이 있는 경우 (구분자)
        final delimiter = match.groupCount >= 1 ? (match.group(1) ?? '') : '';
        // replacement에서 $1을 실제 구분자로 대체
        return replacement.replaceAll(r'$1', delimiter);
      });
    }
    return result;
  }

  /// 안전한 조사 교정 (구분자 패턴 기반)
  ///
  /// 구분자(공백, 마침표 등) 직전의 조사만 교정하여
  /// "나이" 같은 단어를 "나가"로 잘못 바꾸는 문제를 방지합니다.
  static String _correctParticlesWithDelimiter(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // 받침O + 를 → 을 교정
    result = result.replaceAllMapped(_wrongReulPattern, (match) {
      final char = match.group(1)!;
      final delimiter = match.group(2) ?? '';
      if (_hasFinalConsonant(char)) {
        return '$char을$delimiter';
      }
      return match.group(0)!;
    });

    // 받침X + 을 → 를 교정
    result = result.replaceAllMapped(_wrongEulPattern, (match) {
      final char = match.group(1)!;
      final delimiter = match.group(2) ?? '';
      if (!_hasFinalConsonant(char)) {
        return '$char를$delimiter';
      }
      return match.group(0)!;
    });

    // 받침O + 가 → 이 교정 (주격조사는 더 신중히)
    // 주의: "친구가" (받침X) → 정상, "책이" (받침O) → 정상
    // "책가" (받침O) → "책이"로 교정해야 함
    // 단, 이 패턴은 오탐 가능성이 있어 제외 (AI가 주격조사를 틀리는 경우가 적음)

    return result;
  }

  /// 한글 텍스트 종합 처리 파이프라인
  ///
  /// 처리 순서:
  /// 1. 한자어 → 한글 대체 (사전 기반)
  /// 2. 잔여 한자/일본어 제거
  /// 3. 중복 조사 제거
  /// 4. 안전한 조사 교정 (구분자 패턴 기반)
  /// 5. 연속 공백 정리
  ///
  /// [text] 처리할 텍스트
  /// [preserveEmoji] true면 이모지도 보존 (기본값: true)
  static String processKoreanText(String text, {bool preserveEmoji = true}) {
    if (text.isEmpty) return text;

    // 1. 한자어 대체 (사전 기반 - 문맥 보존)
    String processed = _replaceChineseWithKorean(text);

    // 2. 잔여 한자/일본어 제거 (영어도 제거)
    processed = filterToKorean(processed, preserveEmoji: preserveEmoji);

    // 3. 중복 조사 제거
    processed = _removeDuplicateParticles(processed);

    // 4. 안전한 조사 교정
    processed = _correctParticlesWithDelimiter(processed);

    // 5. 연속 공백 정리
    return processed.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

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
  /// 한문이 포함된 경우 한글로 대체하고 조사 오류를 교정합니다.
  /// [text] 필터링할 텍스트
  /// [fallbackText] 결과가 비어있을 때 사용할 기본값
  static String filterMessage(String text, {String? fallbackText}) {
    if (text.isEmpty) {
      return fallbackText ?? '';
    }

    // 외국어가 없어도 조사 오류가 있을 수 있으므로 항상 파이프라인 적용
    // (다만 외국어가 없고 중복 조사도 없으면 빠르게 반환)
    final hasIssue = containsForeignLanguage(text) ||
        _duplicateParticles.any((p) => p.$1.hasMatch(text));

    if (!hasIssue) {
      // 조사 교정만 적용 (경미한 오류 교정)
      final corrected = _correctParticlesWithDelimiter(text);
      return corrected;
    }

    // 전체 파이프라인 적용
    final filtered = processKoreanText(text);

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
