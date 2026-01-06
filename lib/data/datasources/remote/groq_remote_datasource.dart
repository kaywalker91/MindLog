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
  }) async {
    if (_circuitBreaker != null) {
      return _circuitBreaker.run(() => analyzeDiaryWithRetry(content, character: character));
    }
    return analyzeDiaryWithRetry(content, character: character);
  }

  /// 일기 내용 분석 (재시도 로직 포함)
  Future<AnalysisResponseDto> analyzeDiaryWithRetry(
    String content, {
    required AiCharacter character,
  }) async {
    int attempt = 0;
    Duration currentDelay = _initialDelay;

    while (attempt < _maxRetries) {
      try {
        return await _analyzeDiaryOnce(content, character: character);
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
      } catch (e) {
        if (e.toString().contains('429')) { // Rate Limit
          attempt++;
          if (attempt >= _maxRetries) rethrow;
          _printRetryMessage(attempt, '요청 제한(Rate Limit)', currentDelay);
          await Future.delayed(currentDelay);
          currentDelay = _calculateNextDelay(currentDelay);
          continue;
        }
        rethrow;
      }
    }
    throw NetworkException('알 수 없는 네트워크 오류가 발생했습니다.');
  }

  /// 단일 분석 실행
  Future<AnalysisResponseDto> _analyzeDiaryOnce(
    String content, {
    required AiCharacter character,
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
        throw ApiException(
          message: 'Groq API 오류: ${response.statusCode} - ${response.body}',
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
      if (e is ApiException || e is NetworkException) rethrow;
      throw ApiException(message: 'Groq 분석 중 오류: $e');
    }
  }

  Duration _calculateNextDelay(Duration current) {
    return Duration(milliseconds: (current.inMilliseconds * _backoffMultiplier).round());
  }

  void _printRetryMessage(int attempt, String errorType, Duration delay) {
    // 프로덕션에서는 로깅하지 않음 (필요시 구조화된 로깅 라이브러리 사용)
    assert(() {
      debugPrint('🔄 Groq API 요청 재시도 $attempt/$_maxRetries: $errorType, ${delay.inSeconds}초 후 재시도...');
      return true;
    }());
  }
}
