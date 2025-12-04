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
}

/// 감정 분석 결과 엔티티
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

  const AnalysisResult({
    required this.keywords,
    required this.sentimentScore,
    required this.empathyMessage,
    required this.actionItem,
    required this.analyzedAt,
    this.isActionCompleted = false,
  });

  AnalysisResult copyWith({
    List<String>? keywords,
    int? sentimentScore,
    String? empathyMessage,
    String? actionItem,
    DateTime? analyzedAt,
    bool? isActionCompleted,
  }) {
    return AnalysisResult(
      keywords: keywords ?? this.keywords,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      empathyMessage: empathyMessage ?? this.empathyMessage,
      actionItem: actionItem ?? this.actionItem,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      isActionCompleted: isActionCompleted ?? this.isActionCompleted,
    );
  }
}
