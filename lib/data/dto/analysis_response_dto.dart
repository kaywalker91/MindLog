import '../../domain/entities/diary.dart';

/// AI 분석 응답 DTO
class AnalysisResponseDto {
  /// 감정 키워드 (3개)
  final List<String> keywords;

  /// 감정 점수 (1-10)
  final int sentimentScore;

  /// 공감 메시지
  final String empathyMessage;

  /// 추천 행동
  final String actionItem;

  /// 응급 상황 여부
  final bool isEmergency;

  const AnalysisResponseDto({
    required this.keywords,
    required this.sentimentScore,
    required this.empathyMessage,
    required this.actionItem,
    this.isEmergency = false,
  });

  factory AnalysisResponseDto.fromJson(Map<String, dynamic> json) {
    return AnalysisResponseDto(
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      sentimentScore: json['sentiment_score'] as int,
      empathyMessage: json['empathy_message'] as String,
      actionItem: json['action_item'] as String,
      isEmergency: json['is_emergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords,
      'sentiment_score': sentimentScore,
      'empathy_message': empathyMessage,
      'action_item': actionItem,
      'is_emergency': isEmergency,
    };
  }

  /// DTO → Entity 변환
  AnalysisResult toEntity() {
    return AnalysisResult(
      keywords: keywords,
      sentimentScore: sentimentScore.clamp(1, 10),
      empathyMessage: empathyMessage,
      actionItem: actionItem,
      analyzedAt: DateTime.now(),
      isEmergency: isEmergency,
    );
  }
}
