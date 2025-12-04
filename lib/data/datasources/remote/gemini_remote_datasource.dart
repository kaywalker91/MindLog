import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../dto/analysis_response_dto.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prompt_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Gemini API 원격 데이터 소스
class GeminiRemoteDataSource {
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

  /// 일기 내용 분석
  ///
  /// [content] 분석할 일기 내용
  ///
  /// 반환값: 분석 결과 DTO
  Future<AnalysisResponseDto> analyzeDiary(String content) async {
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
        final json = jsonDecode(text) as Map<String, dynamic>;
        return AnalysisResponseDto.fromJson(json);
      } catch (e) {
        throw ApiException(message: 'JSON 파싱 실패: $e');
      }
    } on SafetyBlockException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('ClientException')) {
        throw NetworkException('네트워크 연결을 확인해주세요');
      }
      throw ApiException(message: '분석 중 오류 발생: $e');
    }
  }
}
