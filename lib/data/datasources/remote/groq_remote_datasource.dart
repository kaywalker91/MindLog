import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/ai_character.dart';
import '../../dto/analysis_response_dto.dart';
import '../../dto/analysis_response_parser.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prompt_constants.dart';
import '../../../core/errors/exceptions.dart';

import '../../../core/network/circuit_breaker.dart';

/// Groq API 원격 데이터 소스
class GroqRemoteDataSource {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;

  final String _apiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final http.Client _client;
  final CircuitBreaker? _circuitBreaker;

  GroqRemoteDataSource(this._apiKey, {http.Client? client, CircuitBreaker? circuitBreaker}) 
      : _client = client ?? http.Client(),
        _circuitBreaker = circuitBreaker;

  /// 일기 내용 분석 (공용 인터페이스)
  Future<AnalysisResponseDto> analyzeDiary(
    String content, {
    required AiCharacter character,
    String? userName,
  }) async {
    if (_circuitBreaker != null) {
      return _circuitBreaker.run(
        () => analyzeDiaryWithRetry(content, character: character, userName: userName),
      );
    }
    return analyzeDiaryWithRetry(content, character: character, userName: userName);
  }

  /// 일기 내용 분석 (재시도 로직 포함)
  Future<AnalysisResponseDto> analyzeDiaryWithRetry(
    String content, {
    required AiCharacter character,
    String? userName,
  }) async {
    int attempt = 0;
    Duration currentDelay = _initialDelay;

    while (attempt < _maxRetries) {
      try {
        return await _analyzeDiaryOnce(content, character: character, userName: userName);
      } on SocketException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw NetworkException('네트워크 연결에 실패했습니다. ($_maxRetries번 재시도): $e');
        }
        _printRetryMessage(attempt, '네트워크 연결 오류', currentDelay);
        await Future.delayed(currentDelay);
        currentDelay = _calculateNextDelay(currentDelay);
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw NetworkException('요청 시간이 초과되었습니다. ($_maxRetries번 재시도): $e');
        }
        _printRetryMessage(attempt, '요청 시간 초과', currentDelay);
        await Future.delayed(currentDelay);
        currentDelay = _calculateNextDelay(currentDelay);
      } on RateLimitException catch (e) {
        // Rate Limit(429) 처리: Retry-After 헤더 값 우선 사용
        attempt++;
        if (attempt >= _maxRetries) {
          throw ApiException(message: e.message, statusCode: 429);
        }
        final retryDelay = e.retryAfter ?? currentDelay;
        _printRetryMessage(attempt, '요청 제한(Rate Limit)', retryDelay);
        await Future.delayed(retryDelay);
        currentDelay = _calculateNextDelay(retryDelay);
        continue;
      } on ApiException {
        // Rate Limit이 아닌 ApiException은 재시도하지 않음
        rethrow;
      } catch (e) {
        rethrow;
      }
    }
    throw NetworkException('알 수 없는 네트워크 오류가 발생했습니다.');
  }

  /// 단일 분석 실행
  Future<AnalysisResponseDto> _analyzeDiaryOnce(
    String content, {
    required AiCharacter character,
    String? userName,
  }) async {
    // API 키 유효성 검증
    if (_apiKey.isEmpty) {
      throw ApiException(
        message: 'API 키가 설정되지 않았습니다. '
            '--dart-define=GROQ_API_KEY=... 또는 ./scripts/run.sh로 주입해주세요.',
      );
    }

    try {
      final prompt = PromptConstants.createAnalysisPrompt(
        content,
        character: character,
        userName: userName,
      );
      
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.groqModel,
          'messages': [
            {
              'role': 'system',
              'content': PromptConstants.systemInstructionFor(character)
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode != 200) {
        // Rate Limit(429) 처리: Retry-After 헤더 파싱
        if (response.statusCode == 429) {
          final retryAfter = _parseRetryAfterHeader(response.headers['retry-after']);
          throw RateLimitException(
            message: _sanitizeErrorMessage(429),
            retryAfter: retryAfter,
          );
        }

        // 민감정보 노출 방지: response.body 대신 상태코드별 일반화된 메시지 사용
        final errorMessage = _sanitizeErrorMessage(response.statusCode);
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw ApiException(message: 'Groq API 응답이 비어있습니다.');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>;
      final messageContent = message['content'] as String;
      
      try {
        final jsonResult = AnalysisResponseParser.parseString(messageContent);
        
        // 디버그 로그 - action_items 확인
        assert(() {
          debugPrint('🔍 [DEBUG] Raw AI response content:');
          debugPrint(messageContent);
          debugPrint('🔍 [DEBUG] Parsed JSON action_items: ${jsonResult['action_items']}');
          debugPrint('🔍 [DEBUG] action_items type: ${jsonResult['action_items']?.runtimeType}');
          return true;
        }());
        
        final dto = AnalysisResponseDto.fromJson(jsonResult);
        
        // 디버그 로그 - DTO 확인
        assert(() {
          debugPrint('🔍 [DEBUG] DTO actionItems: ${dto.actionItems}');
          debugPrint('🔍 [DEBUG] DTO actionItem: ${dto.actionItem}');
          return true;
        }());
        
        return dto;
      } catch (e) {
        // 파싱 실패 시 민감한 응답 내용은 로깅하지 않음
        debugPrint('❌ [DEBUG] Parse error: $e');
        throw ApiException(message: '응답 파싱 실패');
      }

    } catch (e) {
      if (e is ApiException || e is NetworkException || e is RateLimitException) rethrow;
      throw ApiException(message: 'Groq 분석 중 오류: $e');
    }
  }

  Duration _calculateNextDelay(Duration current) {
    return Duration(
        milliseconds: (current.inMilliseconds * _backoffMultiplier).round());
  }

  /// HTTP 상태코드별 일반화된 에러 메시지 (민감정보 제외)
  String _sanitizeErrorMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'Groq API 오류: 잘못된 요청 형식입니다.',
      401 => 'Groq API 오류: API 키 인증에 실패했습니다.',
      403 => 'Groq API 오류: 접근 권한이 없습니다.',
      429 => 'Groq API 오류: 요청 제한을 초과했습니다. 잠시 후 다시 시도해주세요.',
      500 => 'Groq API 오류: 서버 내부 오류가 발생했습니다.',
      502 => 'Groq API 오류: 서버 게이트웨이 오류가 발생했습니다.',
      503 => 'Groq API 오류: 서비스를 일시적으로 사용할 수 없습니다.',
      _ => 'Groq API 오류: 알 수 없는 오류가 발생했습니다. (코드: $statusCode)',
    };
  }

  void _printRetryMessage(int attempt, String errorType, Duration delay) {
    // 프로덕션에서는 로깅하지 않음 (필요시 구조화된 로깅 라이브러리 사용)
    assert(() {
      debugPrint('🔄 Groq API 요청 재시도 $attempt/$_maxRetries: $errorType, ${delay.inSeconds}초 후 재시도...');
      return true;
    }());
  }

  /// Retry-After 헤더 파싱 (초 단위 또는 HTTP-date 형식)
  /// RFC 7231 Section 7.1.3 준수
  Duration? _parseRetryAfterHeader(String? headerValue) {
    if (headerValue == null || headerValue.isEmpty) return null;

    // 1. 초 단위 숫자 형식 (예: "30")
    final seconds = int.tryParse(headerValue);
    if (seconds != null) {
      // 최대 5분으로 제한 (서버 오류 방지)
      final clampedSeconds = seconds.clamp(1, 300);
      return Duration(seconds: clampedSeconds);
    }

    // 2. HTTP-date 형식 (예: "Fri, 31 Dec 2024 23:59:59 GMT")
    try {
      final retryDate = HttpDate.parse(headerValue);
      final now = DateTime.now().toUtc();
      final difference = retryDate.difference(now);
      if (difference.isNegative) return _initialDelay;
      // 최대 5분으로 제한
      if (difference.inSeconds > 300) return const Duration(minutes: 5);
      return difference;
    } catch (_) {
      // 파싱 실패 시 기본값 사용
      return null;
    }
  }
}
