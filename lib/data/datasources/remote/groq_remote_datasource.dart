import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../dto/analysis_response_dto.dart';
import '../../dtos/analysis_response_parser.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prompt_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Groq API 원격 데이터 소스
class GroqRemoteDataSource {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;

  final String _apiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final http.Client _client;

  GroqRemoteDataSource(this._apiKey, {http.Client? client}) 
      : _client = client ?? http.Client();

  /// 일기 내용 분석 (공용 인터페이스)
  Future<AnalysisResponseDto> analyzeDiary(String content) async {
    return analyzeDiaryWithRetry(content);
  }

  /// 일기 내용 분석 (재시도 로직 포함)
  Future<AnalysisResponseDto> analyzeDiaryWithRetry(String content) async {
    int attempt = 0;
    Duration currentDelay = _initialDelay;

    while (attempt < _maxRetries) {
      try {
        return await _analyzeDiaryOnce(content);
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
  Future<AnalysisResponseDto> _analyzeDiaryOnce(String content) async {
    try {
      final prompt = PromptConstants.createAnalysisPrompt(content);
      
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
              'content': PromptConstants.systemInstruction
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

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['choices'] == null || (data['choices'] as List).isEmpty) {
        throw ApiException(message: 'Groq API 응답이 비어있습니다.');
      }

      final choice = data['choices'][0];
      final messageContent = choice['message']['content'] as String;
      
      try {
        // 기존 파서의 로직을 재사용하기 위해 텍스트 파싱 메서드를 호출
        // AnalysisResponseParser에 문자열 파싱 메서드를 추가하거나, 
        // 여기서 직접 파싱 로직을 수행해야 함.
        // 현재 AnalysisResponseParser 수정이 필요함.
        // 임시로 AnalysisResponseParser._parseAsJson 등을 공개(public)으로 변경하거나
        // 파서에 `parseString` 메서드를 추가한다고 가정하고 호출.
        // 실제로는 AnalysisResponseParser를 수정해야 함.
        final jsonResult = AnalysisResponseParser.parseString(messageContent);
        return AnalysisResponseDto.fromJson(jsonResult);
      } catch (e) {
        debugPrint('Parsing error: $messageContent');
        throw ApiException(message: '응답 파싱 실패: $e');
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
    debugPrint('🔄 Groq API 요청 재시도 $attempt/$_maxRetries: $errorType, ${delay.inSeconds}초 후 재시도...');
  }
}
