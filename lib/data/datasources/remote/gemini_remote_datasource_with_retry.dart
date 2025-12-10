import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../dto/analysis_response_dto.dart';
import '../../dtos/analysis_response_parser.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prompt_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Gemini API 원격 데이터 소스 (재시도 로직 포함)
class GeminiRemoteDataSourceWithRetry {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;

  GenerativeModel? _model;

  /// Gemini 모델 인스턴스 초기화
  GenerativeModel get model {
    if (_model != null) return _model!;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw ApiException(
        message: 'Gemini API 키가 설정되지 않았습니다. .env 파일을 확인하세요.',
      );
    }

    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.text(PromptConstants.systemInstruction),
    );

    return _model!;
  }

  // 연결 상태 확인
  Future<bool>? _connectionChecker;



  /// 일기 내용 분석 (재시도 로직 포함)
  Future<AnalysisResponseDto> analyzeDiaryWithRetry(String content) async {
    _connectionChecker ??= _checkConnectivity();
    
    // 네트워크 연결 사전 확인
    
    // 네트워크 연결 사전 확인
    if (!(await _connectionChecker!)) {
      throw NetworkException('인터넷 연결을 확인해주세요.');
    }
    
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

        // 사용자 피드백을 위한 로그
        _printRetryMessage(attempt, '네트워크 연결 오류', currentDelay);
        
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * _backoffMultiplier).round(),
        );
      } on HttpException catch (e) {
        attempt++;
        
        // 401, 403 등 인증 오류는 재시도하지 않음
        if (e.message.contains('401') || e.message.contains('403')) {
          throw ApiException(
            message: 'API 인증 오류입니다. API 키를 확인해주세요.',
            statusCode: _extractStatusCode(e.message),
          );
        }
        
        if (attempt >= _maxRetries) {
          throw NetworkException('서버 응답 오류입니다. ($_maxRetries번 재시도): $e');
        }

        _printRetryMessage(attempt, '서버 응답 오류', currentDelay);
        
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * _backoffMultiplier).round(),
        );
      } on TimeoutException catch (e) {
        attempt++;
        
        if (attempt >= _maxRetries) {
          throw NetworkException('요청 시간이 초과되었습니다. ($_maxRetries번 재시도): $e');
        }

        _printRetryMessage(attempt, '요청 시간 초과', currentDelay);
        
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * _backoffMultiplier).round(),
        );
      } catch (e) {
        // 파싱 오류는 재시도
        if (e is ApiException && (e.message?.contains('파싱') ?? false)) {
          attempt++;
          if (attempt >= _maxRetries) {
            rethrow;
          }
          _printRetryMessage(attempt, '응답 파싱 오류', currentDelay);
          await Future.delayed(currentDelay);
          continue;
        }
        
        // 예측하지 못한 오류는 재시도하지 않고 즉시 전파
        rethrow;
      }
    }

    throw NetworkException('알 수 없는 네트워크 오류가 발생했습니다.');
  }

  /// 단일 분석 실행
  Future<AnalysisResponseDto> _analyzeDiaryOnce(String content) async {
    try {
      final prompt = PromptConstants.createAnalysisPrompt(content);
      final response = await model.generateContent([Content.text(prompt)]);

      // Safety 필터 체크
      if (response.candidates.isEmpty) {
        throw SafetyBlockException('응답이 없습니다');
      }

      final candidate = response.candidates.first;

      // FinishReason 체크
      if (candidate.finishReason == FinishReason.safety) {
        throw SafetyBlockException('안전상의 이유로 분석이 차단되었습니다');
      }

      if (candidate.finishReason != FinishReason.stop) {
        throw ApiException(
          message: '분석이 완료되지 않았습니다: ${candidate.finishReason}',
        );
      }

      // 응답 텍스트 추출
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw ApiException(message: '빈 응답을 받았습니다');
      }

      // JSON 파싱
      try {
        final json = AnalysisResponseParser.parseResponse(response);
        return AnalysisResponseDto.fromJson(json);
      } catch (e) {
        throw ApiException(message: 'API 응답 파싱 실패: $e');
      }
    } on SafetyBlockException catch (e) {
      debugPrint('SafetyBlockException caught: ${e.message}');
      rethrow;
    } on ApiException catch (e) {
      debugPrint('ApiException caught: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in GeminiRemoteDataSourceWithRetry: $e');
      debugPrint('Stack trace: $stackTrace');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('ClientException')) {
        throw NetworkException('네트워크 연결을 확인해주세요');
      }
      throw ApiException(message: '분석 중 오류 발생: $e');
    }
  }

  /// 재시도 메시지 출력
  void _printRetryMessage(int attempt, String errorType, Duration delay) {
    // ignore: avoid_print
    print('🔄 API 요청 재시도 $attempt/$_maxRetries: $errorType, ${delay.inSeconds}초 후 재시도...');
  }

  /// HTTP 상태 코드 추출
  int? _extractStatusCode(String errorMessage) {
    final statusCodeRegex = RegExp(r'Status code: (\d+)');
    final match = statusCodeRegex.firstMatch(errorMessage);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }

  /// 연결 상태 확인
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 분석 결과 유효성 검증
  bool _isValidResponse(AnalysisResponseDto response) {
    return response.keywords.isNotEmpty &&
           response.sentimentScore >= 1 &&
           response.sentimentScore <= 10 &&
           response.empathyMessage.isNotEmpty &&
           response.actionItem.isNotEmpty;
  }

  /// 일기 내용 분석 (공용 인터페이스)
  Future<AnalysisResponseDto> analyzeDiary(String content) async {
    // 연결 상태 사전 확인
    if (!await _checkConnectivity()) {
      throw NetworkException('인터넷 연결을 확인해주세요.');
    }

    try {
      final response = await analyzeDiaryWithRetry(content);
      
      // 응답 유효성 검증
      if (!_isValidResponse(response)) {
        throw ApiException(message: 'API 응답이 유효하지 않습니다.');
      }
      
      return response;
    } catch (e) {
      if (e is NetworkException || e is ApiException) {
        rethrow;
      }
      throw NetworkException('분석 중 알 수 없는 오류가 발생했습니다: $e');
    }
  }
}
