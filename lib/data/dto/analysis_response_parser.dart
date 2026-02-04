import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/korean_text_filter.dart';

/// API 응답 파서 - 다양한 포맷 대응
class AnalysisResponseParser {
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
          throw ApiException(message: 'AI 응답 파싱에 실패했습니다: $text');
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

    try {
      final decoded = jsonDecode(trimmedText) as Map<String, dynamic>;

      // 디버그: 파싱 직후 action_items 확인
      assert(() {
        debugPrint(
          '🔍 [PARSER] After jsonDecode, action_items: ${decoded['action_items']}',
        );
        debugPrint(
          '🔍 [PARSER] action_items type: ${decoded['action_items']?.runtimeType}',
        );
        return true;
      }());

      _validateJsonStructure(decoded);

      // 디버그: 검증 후 action_items 확인
      assert(() {
        debugPrint(
          '🔍 [PARSER] After validation, action_items: ${decoded['action_items']}',
        );
        return true;
      }());

      return decoded;
    } catch (e) {
      debugPrint('⚠️ [PARSER] First parse failed: $e, trying sanitize...');
      final json = _sanitizeJsonString(trimmedText);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _validateJsonStructure(decoded);
      return decoded;
    }
  }

  /// 마크다운드 JSON 파싱
  static Map<String, dynamic> _parseAsMarkdownJson(String text) {
    // 다양한 마크다운드 형식 제거
    final String cleanedText = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*$'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .replaceAll(RegExp(r'^\s*\-\s*'), '')
        .trim();

    // JSON 객체 추출
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleanedText);
    if (jsonMatch != null) {
      final jsonStr = jsonMatch.group(0)!;
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        _validateJsonStructure(decoded);
        return decoded;
      } catch (_) {
        final sanitizedJson = _sanitizeJsonString(jsonStr);
        final decoded = jsonDecode(sanitizedJson) as Map<String, dynamic>;
        _validateJsonStructure(decoded);
        return decoded;
      }
    }

    throw const FormatException('No JSON object found in markdown');
  }

  /// 자연어 응답에서 키워드 추출
  static Map<String, dynamic> _parseAsNaturalLanguage(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);

    List<String> keywords = [];
    int sentimentScore = 5;
    String empathyMessage = '';
    List<String> actionItems = [];

    try {
      for (final line in lines) {
        final lowerLine = line.toLowerCase().trim();

        // 키워드 추출
        if (lowerLine.contains('키워드') || lowerLine.contains('감정')) {
          keywords = _extractKeywords(line);
        }

        // 감정 점수 추출
        if (lowerLine.contains('점수') ||
            lowerLine.contains('점수는') ||
            lowerLine.contains('sentiment') ||
            lowerLine.contains('평가')) {
          sentimentScore = _extractSentimentScore(line);
        }

        // 공감 메시지 추출
        if (lowerLine.contains('공감') ||
            lowerLine.contains('위로') ||
            lowerLine.contains('empathy') ||
            lowerLine.contains('위로')) {
          empathyMessage = _extractMessage(line);
        }

        // 추천 행동 추출
        if (lowerLine.contains('추천') ||
            lowerLine.contains('행동') ||
            lowerLine.contains('action') ||
            lowerLine.contains('제안')) {
          final action = _extractMessage(line);
          if (action.isNotEmpty) actionItems.add(action);
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
    if (actionItems.isEmpty) {
      actionItems = ['잠시 휴식을 취해보세요.'];
    }

    return {
      'keywords': keywords.take(5).toList(),
      'sentiment_score': sentimentScore.clamp(1, 10),
      'empathy_message': empathyMessage.trim(),
      'action_items': actionItems.take(3).toList(),
      'action_item': actionItems.isNotEmpty
          ? actionItems.first
          : '잠시 휴식을 취해보세요.',
      'emotion_category': {'primary': '평온', 'secondary': '일상'},
      'emotion_trigger': {'category': '기타', 'description': '일기 내용에서 파악'},
      'energy_level': 5,
      'is_emergency': false,
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

  /// JSON 구조 검증 및 한글 필터링
  static void _validateJsonStructure(Map<String, dynamic> json) {
    // action_item은 더 이상 필수가 아님 (action_items 배열을 대신 사용)
    final requiredKeys = ['keywords', 'sentiment_score', 'empathy_message'];

    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw FormatException('Missing required key: $key');
      }
    }

    // action_items가 있고 action_item이 없는 경우, 첫 번째 항목으로 action_item 생성
    if (json['action_items'] != null && json['action_item'] == null) {
      final actionItems = json['action_items'];
      if (actionItems is List && actionItems.isNotEmpty) {
        json['action_item'] = actionItems.first.toString();
      } else if (actionItems is String && actionItems.isNotEmpty) {
        // action_items가 문자열인 경우 (JSON 문자열 또는 단일 값)
        if (actionItems.startsWith('[')) {
          try {
            final decoded = jsonDecode(actionItems);
            if (decoded is List && decoded.isNotEmpty) {
              json['action_item'] = decoded.first.toString();
            } else {
              json['action_item'] = actionItems;
            }
          } catch (_) {
            json['action_item'] = actionItems;
          }
        } else {
          json['action_item'] = actionItems;
        }
      }
    }

    // 키워드 검증 및 한글 필터링
    final keywordsRaw = json['keywords'];
    if (keywordsRaw is! List ||
        keywordsRaw.isEmpty ||
        !keywordsRaw.every((k) => k is String)) {
      json['keywords'] = ['감정', '일상'];
    } else {
      // 한문/일본어 필터링 적용
      final keywords = (json['keywords'] as List).cast<String>();
      json['keywords'] = KoreanTextFilter.filterKeywords(keywords);
    }

    // 감정 점수 검증
    if (json['sentiment_score'] is! int ||
        (json['sentiment_score'] as int) < 1 ||
        (json['sentiment_score'] as int) > 10) {
      json['sentiment_score'] = 5;
    }

    // 메시지 검증 및 한글 필터링
    if (json['empathy_message'] is! String ||
        (json['empathy_message'] as String).trim().isEmpty) {
      json['empathy_message'] = '마음의 이야기에 감사드립니다.';
    } else {
      // 한문/일본어 필터링 적용
      json['empathy_message'] = KoreanTextFilter.filterMessage(
        json['empathy_message'] as String,
        fallbackText: '마음의 이야기에 감사드립니다.',
      );
    }

    // 행동 아이템 검증 및 한글 필터링
    if (json['action_item'] is! String ||
        (json['action_item'] as String).trim().isEmpty) {
      json['action_item'] = '잠시 쉬어가세요.';
    } else {
      // 한문/일본어 필터링 적용
      json['action_item'] = KoreanTextFilter.filterMessage(
        json['action_item'] as String,
        fallbackText: '잠시 쉬어가세요.',
      );
    }

    // action_items 배열 검증 및 정규화
    final rawActionItems = json['action_items'];
    if (rawActionItems != null) {
      List<String> actionItemsList = [];

      if (rawActionItems is List) {
        // 정상적인 배열
        actionItemsList = rawActionItems.map((e) => e.toString()).toList();
      } else if (rawActionItems is String && rawActionItems.isNotEmpty) {
        // 문자열인 경우 JSON 파싱 시도
        try {
          if (rawActionItems.startsWith('[')) {
            final decoded = jsonDecode(rawActionItems);
            if (decoded is List) {
              actionItemsList = decoded.map((e) => e.toString()).toList();
            } else {
              actionItemsList = [rawActionItems];
            }
          } else {
            actionItemsList = [rawActionItems];
          }
        } catch (_) {
          actionItemsList = [rawActionItems];
        }
      }

      // 각 항목에 한글 필터링 적용
      json['action_items'] = actionItemsList.map((item) {
        return KoreanTextFilter.filterMessage(
          item,
          fallbackText: '작은 휴식을 취해보세요.',
        );
      }).toList();
    }
  }

  /// 텍스트에서 키워드 추출
  /// 한글, 영문, 숫자만 허용 (한문/일본어 제외)
  static List<String> _extractKeywords(String line) {
    // 정규식 수정: \w 대신 명시적으로 한글/영문/숫자만 허용
    final keywordRegex = RegExp(r'[:：]?\s*([가-힣a-zA-Z0-9\s,]+)');
    final match = keywordRegex.firstMatch(line);
    if (match != null) {
      final keywordsStr = match.group(1) ?? '';
      final rawKeywords = keywordsStr
          .split(RegExp(r'[,،\s]+'))
          .where((k) => k.trim().isNotEmpty)
          .map((k) => k.trim())
          .take(5) // 여유있게 추출 후 필터링
          .toList();

      // 한글 필터링 적용
      return KoreanTextFilter.filterKeywords(rawKeywords);
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
    final cleanLine = line.replaceAll(RegExp(r'^[^:：]*[:：]?\s*'), '').trim();

    // 따옴표 제거
    return cleanLine.replaceAll(RegExp(r'''^['"]+|['"]+$'''), '');
  }

  static List<String> _extractLikelyKeywords(String text) {
    // 감정 관련 단어 필터링
    final emotionWords = [
      '불안',
      '스트레스',
      '기억',
      '감사',
      '힘듦',
      '즐거움',
      '걱정',
      '설렘',
      '후회',
      '기대',
      '만족',
      '피곤',
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
      'keywords': ['일상', '감정', '하루', '생각', '마음'],
      'sentiment_score': 5,
      'empathy_message': '마음의 이야기에 감사드립니다.',
      'action_items': [
        '🚀 잠시 눈을 감고 심호흡 해보세요',
        '☀️ 따뜻한 차 한 잔의 여유를 가져보세요',
        '📅 이번 주에 좋아하는 일 하나 해보세요',
      ],
      'action_item': '따뜻한 차 한 잔의 여유를 가져보세요.',
      'emotion_category': {'primary': '평온', 'secondary': '일상'},
      'emotion_trigger': {'category': '기타', 'description': '일상적인 하루'},
      'energy_level': 5,
      'is_emergency': false,
    };
  }
}
