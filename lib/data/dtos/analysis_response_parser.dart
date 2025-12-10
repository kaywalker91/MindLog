import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/errors/exceptions.dart';

/// API 응답 파서 - 다양한 포맷 대응
class AnalysisResponseParser {
  /// AI 응답을 안전하게 파싱하고 유효한 분석 결과로 변환
  static Map<String, dynamic> parseResponse(GenerateContentResponse response) {
    // GenerateContentResponse에서 텍스트 추출
    String? text;
    
    if (response.candidates.isNotEmpty) {
      final content = response.candidates.first.content;
      if (content.parts.isNotEmpty) {
        final part = content.parts.first;
        // TextPart는 .text 속성을 가짐
        if (part is TextPart) {
          text = part.text;
        }
      }
    }
    
    return parseString(text);
  }

  /// 문자열 기반 파싱 (Groq 등 타 API용)
  static Map<String, dynamic> parseString(String? text) {
    if (text == null || text.trim().isEmpty) {
      throw ApiException(message: '빈 응답을 받았습니다');
    }

    try {
      // 1. 순수 JSON 파싱 시도
      return _parseAsJson(text);
    } catch (e) {
      try {
        // 2. 마크다운드 JSON 백틱 제거 후 파싱 시도
        return _parseAsMarkdownJson(text);
      } catch (e) {
        try {
          // 3. 자연어 응답에서 키워드 추출
          return _parseAsNaturalLanguage(text);
        } catch (e) {
          throw ApiException(
            message: 'AI 응답 파싱에 실패했습니다: $text',
          );
        }
      }
    }
  }

  /// 순수 JSON 파싱
  static Map<String, dynamic> _parseAsJson(String text) {
    final trimmedText = text.trim();
    if (!trimmedText.startsWith('{') || !trimmedText.endsWith('}')) {
      throw const FormatException('Not valid JSON format');
    }

    final json = _sanitizeJsonString(trimmedText);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    _validateJsonStructure(decoded);
    return decoded;
  }

  /// 마크다운드 JSON 파싱
  static Map<String, dynamic> _parseAsMarkdownJson(String text) {
    // 다양한 마크다운드 형식 제거
    String cleanedText = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*$'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .replaceAll(RegExp(r'^\s*\-\s*'), '')
        .trim();

    // JSON 객체 추출
    final jsonMatch = RegExp(r'\{.*\}').firstMatch(cleanedText);
    if (jsonMatch != null) {
      final jsonStr = jsonMatch.group(0)!;
      final sanitizedJson = _sanitizeJsonString(jsonStr);
      final decoded = jsonDecode(sanitizedJson) as Map<String, dynamic>;
      _validateJsonStructure(decoded);
      return decoded;
    }

    throw const FormatException('No JSON object found in markdown');
  }

  /// 자연어 응답에서 키워드 추출
  static Map<String, dynamic> _parseAsNaturalLanguage(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
    
    List<String> keywords = [];
    int sentimentScore = 5;
    String empathyMessage = '';
    String actionItem = '';

    try {
      for (final line in lines) {
        final lowerLine = line.toLowerCase().trim();
        
        // 키워드 추출
        if (lowerLine.contains('키워드') || lowerLine.contains('감정')) {
          keywords = _extractKeywords(line);
        }
        
        // 감정 점수 추출
        if (lowerLine.contains('점수') || lowerLine.contains('점수는') || 
            lowerLine.contains('sentiment') || lowerLine.contains('평가')) {
          sentimentScore = _extractSentimentScore(line);
        }
        
        // 공감 메시지 추출
        if (lowerLine.contains('공감') || lowerLine.contains('위로') ||
            lowerLine.contains('empathy') || lowerLine.contains('위로')) {
          empathyMessage = _extractMessage(line);
        }
        
        // 추천 행동 추출
        if (lowerLine.contains('추천') || lowerLine.contains('행동') ||
            lowerLine.contains('action') || lowerLine.contains('제안')) {
          actionItem = _extractMessage(line);
        }
      }
    } catch (e) {
      // 분석 실패 시 기본값 반환
      return _createFallbackResponse(text);
    }

    // 추출된 값 검증 및 수정
    if (keywords.isEmpty) {
      keywords = _extractLikelyKeywords(text);
    }
    if (empathyMessage.isEmpty) {
      empathyMessage = '마음의 이야기를 들어주셔서 감사합니다.';
    }
    if (actionItem.isEmpty) {
      actionItem = '잠시 휴식을 취해보세요.';
    }

    return {
      'keywords': keywords.take(3).toList(),
      'sentiment_score': sentimentScore.clamp(1, 10),
      'empathy_message': empathyMessage.trim(),
      'action_item': actionItem.trim(),
    };
  }

  /// JSON 문자열 정화
  static String _sanitizeJsonString(String jsonString) {
    // 불완전한 따옴표 수정
    String sanitized = jsonString;
    sanitized = sanitized.replaceAll(RegExp(r'(\w+) :'), r'\1:');
    sanitized = sanitized.replaceAll(RegExp(r': (\w+)'), r': "\1"');
    sanitized = sanitized.replaceAll(RegExp(r'(\w+),'), r'\1",');
    
    // 이스케이프된 문자 처리
    sanitized = sanitized.replaceAll('\\n', '\n');
    sanitized = sanitized.replaceAll('\\"', '"');
    sanitized = sanitized.replaceAll('\\/', '/');
    
    return sanitized;
  }

  /// JSON 구조 검증
  static void _validateJsonStructure(Map<String, dynamic> json) {
    final requiredKeys = ['keywords', 'sentiment_score', 'empathy_message', 'action_item'];
    
    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw FormatException('Missing required key: $key');
      }
    }

    // 키워드 검증
    if (json['keywords'] is! List || 
        (json['keywords'] as List).isEmpty || 
        !(json['keywords'].every((k) => k is String))) {
      json['keywords'] = ['감정', '일상'];
    }

    // 감정 점수 검증
    if (json['sentiment_score'] is! int || 
        (json['sentiment_score'] as int) < 1 || 
        (json['sentiment_score'] as int) > 10) {
      json['sentiment_score'] = 5;
    }

    // 메시지 검증
    if (json['empathy_message'] is! String || 
        (json['empathy_message'] as String).trim().isEmpty) {
      json['empathy_message'] = '마음의 이야기에 감사드립니다.';
    }

    // 행동 아이템 검증
    if (json['action_item'] is! String || 
        (json['action_item'] as String).trim().isEmpty) {
      json['action_item'] = '잠시 쉬어가세요.';
    }
  }

  /// 텍스트에서 키워드 추출
  static List<String> _extractKeywords(String line) {
    final keywordRegex = RegExp(r'[:：]?\s*([가-힣\w\s,]+)');
    final match = keywordRegex.firstMatch(line);
    if (match != null) {
      final keywordsStr = match.group(1) ?? '';
      return keywordsStr
          .split(RegExp(r'[,،\s]+'))
          .where((k) => k.trim().isNotEmpty)
          .map((k) => k.trim())
          .take(3)
          .toList();
    }
    return [];
  }

  /// 감정 점수 추출
  static int _extractSentimentScore(String line) {
    final scoreRegex = RegExp(r'(\d+)');
    final match = scoreRegex.firstMatch(line);
    if (match != null) {
      final score = int.tryParse(match.group(1)!);
      if (score != null && score >= 1 && score <= 10) {
        return score;
      }
    }

    // 특정 키워드 기반 점수 추정
    final lowerLine = line.toLowerCase();
    if (lowerLine.contains('매우 긍정') || lowerLine.contains('아주 좋')) return 9;
    if (lowerLine.contains('긍정') || lowerLine.contains('좋')) return 7;
    if (lowerLine.contains('부정') || lowerLine.contains('안')) return 3;
    if (lowerLine.contains('매우 부정') || lowerLine.contains('매우 괴')) return 2;
    
    return 5; // 기본값
  }

  /// 메시지 추출
  static String _extractMessage(String line) {
    // 콜론 뒤의 메시지 부분 추출
    final cleanLine = line
        .replaceAll(RegExp(r'^[^:：]*[:：]?\s*'), '')
        .trim();
    
    // 따옴표 제거
    return cleanLine.replaceAll(RegExp(r'''^['"]+|['"]+$'''), '');
  }

  static List<String> _extractLikelyKeywords(String text) {

    // 감정 관련 단어 필터링
    final emotionWords = [
      '불안', '스트레스', '기억', '감사', '힘듦', '즐거움',
      '걱정', '설렘', '후회', '기대', '만족', '피곤'
    ];

    final foundKeywords = <String>[];
    for (final word in emotionWords) {
      if (text.contains(word)) {
        foundKeywords.add(word);
        if (foundKeywords.length >= 3) break;
      }
    }

    return foundKeywords.isEmpty ? ['감정'] : foundKeywords;
  }

  /// 대체 응답 생성
  static Map<String, dynamic> _createFallbackResponse(String originalText) {
    return {
      'keywords': ['일상', '감정'],
      'sentiment_score': 5,
      'empathy_message': '마음의 이야기에 감사드립니다.',
      'action_item': '따뜻한 차 한 잔의 여유를 가져보세요.',
    };
  }
}
