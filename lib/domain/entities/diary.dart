import 'package:json_annotation/json_annotation.dart';

part 'diary.g.dart';

/// 일기 상태
enum DiaryStatus {
  /// 분석 대기 중
  pending,

  /// 분석 완료
  analyzed,

  /// 분석 실패
  failed,

  /// 안전 필터에 의해 차단됨
  safetyBlocked,
}

/// 일기 엔티티
@JsonSerializable()
class Diary {
  /// 고유 ID
  final String id;

  /// 일기 내용
  final String content;

  /// 작성 시간
  final DateTime createdAt;

  /// 분석 상태
  final DiaryStatus status;

  /// 분석 결과 (분석 완료 시)
  final AnalysisResult? analysisResult;

  const Diary({
    required this.id,
    required this.content,
    required this.createdAt,
    this.status = DiaryStatus.pending,
    this.analysisResult,
  });

  Diary copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DiaryStatus? status,
    AnalysisResult? analysisResult,
  }) {
    return Diary(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);
}

/// 감정 분석 결과 엔티티
@JsonSerializable()
class AnalysisResult {
  /// 감정 키워드 (3개)
  final List<String> keywords;

  /// 감정 점수 (1-10)
  final int sentimentScore;

  /// 공감 메시지
  final String empathyMessage;

  /// 추천 행동
  final String actionItem;

  /// 분석 시간
  final DateTime analyzedAt;

  /// 추천 행동 완료 여부
  final bool isActionCompleted;

  /// 응급 상황 여부 (자해/자살 위험 등)
  final bool isEmergency;

  AnalysisResult({
    this.keywords = const [],
    this.sentimentScore = 5,
    this.empathyMessage = '',
    this.actionItem = '',
    DateTime? analyzedAt,
    this.isActionCompleted = false,
    this.isEmergency = false,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => _$AnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  AnalysisResult copyWith({
    List<String>? keywords,
    int? sentimentScore,
    String? empathyMessage,
    String? actionItem,
    DateTime? analyzedAt,
    bool? isActionCompleted,
    bool? isEmergency,
  }) {
    return AnalysisResult(
      keywords: keywords ?? this.keywords,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      empathyMessage: empathyMessage ?? this.empathyMessage,
      actionItem: actionItem ?? this.actionItem,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      isActionCompleted: isActionCompleted ?? this.isActionCompleted,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }
}
