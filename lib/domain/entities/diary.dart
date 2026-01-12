import 'dart:convert';
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

  /// 상단 고정 여부
  final bool isPinned;

  const Diary({
    required this.id,
    required this.content,
    required this.createdAt,
    this.status = DiaryStatus.pending,
    this.analysisResult,
    this.isPinned = false,
  });

  /// copyWith 메서드
  /// [clearAnalysisResult]를 true로 설정하면 analysisResult를 명시적으로 null로 설정합니다.
  /// 이는 null 파라미터가 "변경 없음"을 의미하는 copyWith 패턴의 한계를 해결합니다.
  Diary copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DiaryStatus? status,
    AnalysisResult? analysisResult,
    bool clearAnalysisResult = false,
    bool? isPinned,
  }) {
    return Diary(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      analysisResult: clearAnalysisResult ? null : (analysisResult ?? this.analysisResult),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);
}

/// 감정 범주 (1차/2차 감정)
@JsonSerializable()
class EmotionCategory {
  /// 1차 감정 (기쁨, 슬픔, 분노, 공포, 놀람, 혐오, 평온)
  final String primary;

  /// 2차 감정 (세부 감정)
  final String secondary;

  const EmotionCategory({
    required this.primary,
    required this.secondary,
  });

  factory EmotionCategory.fromJson(Map<String, dynamic> json) =>
      _$EmotionCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionCategoryToJson(this);

  // primaryEmoji getter는 Presentation Layer로 이동됨
  // → lib/presentation/extensions/emotion_emoji_extension.dart
}

/// 감정 유발 요인
@JsonSerializable()
class EmotionTrigger {
  /// 카테고리
  final String category;

  /// 설명
  final String description;

  const EmotionTrigger({
    required this.category,
    required this.description,
  });

  factory EmotionTrigger.fromJson(Map<String, dynamic> json) =>
      _$EmotionTriggerFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionTriggerToJson(this);

  // categoryEmoji getter는 Presentation Layer로 이동됨
  // → lib/presentation/extensions/emotion_emoji_extension.dart
}

/// JSON에서 analyzedAt이 null일 경우 현재 시간 반환 (기존 데이터 호환용)
DateTime _dateTimeFromJsonOrNow(String? json) =>
    json != null ? DateTime.parse(json) : DateTime.now();

/// 감정 분석 결과 엔티티
@JsonSerializable()
class AnalysisResult {
  /// 감정 키워드 (최대 5개)
  final List<String> keywords;

  /// 감정 점수 (1-10)
  final int sentimentScore;

  /// 공감 메시지
  final String empathyMessage;

  /// 추천 행동 (레거시 호환용)
  final String actionItem;

  /// 단계별 추천 행동 (즉시/오늘/이번주)
  final List<String> actionItems;

  /// 분석 시간 (JSON에서 null일 경우 현재 시간으로 대체)
  @JsonKey(fromJson: _dateTimeFromJsonOrNow)
  final DateTime analyzedAt;

  /// 추천 행동 완료 여부
  final bool isActionCompleted;

  /// 응급 상황 여부 (자해/자살 위험 등)
  final bool isEmergency;

  /// AI 캐릭터 ID (설정 시점 기준)
  final String? aiCharacterId;

  /// 감정 범주 (1차/2차 감정)
  final EmotionCategory? emotionCategory;

  /// 감정 유발 요인
  final EmotionTrigger? emotionTrigger;

  /// 에너지 레벨 (1-10)
  final int? energyLevel;

  /// 인지 패턴 (선택적 - 부정적 사고 패턴 감지 시)
  final String? cognitivePattern;

  /// [analyzedAt]은 필수 파라미터로, 호출자가 명시적으로 제공해야 합니다.
  /// 테스트에서는 고정된 시간을 주입하여 결정론적 테스트가 가능합니다.
  /// 프로덕션 코드에서는 `DateTime.now()`를 전달합니다.
  const AnalysisResult({
    this.keywords = const [],
    this.sentimentScore = 5,
    this.empathyMessage = '',
    this.actionItem = '',
    this.actionItems = const [],
    required this.analyzedAt,
    this.isActionCompleted = false,
    this.isEmergency = false,
    this.aiCharacterId,
    this.emotionCategory,
    this.emotionTrigger,
    this.energyLevel,
    this.cognitivePattern,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => _$AnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  /// 표시할 추천 행동 목록 (actionItems가 비어있으면 actionItem 사용)
  List<String> get displayActionItems {
    // actionItems가 있는 경우
    if (actionItems.isNotEmpty) {
      // 첫 항목이 JSON 배열 문자열인 경우 파싱
      if (actionItems.length == 1 && actionItems.first.startsWith('[')) {
        try {
          final parsed = jsonDecode(actionItems.first);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // 파싱 실패 시 그대로 반환
        }
      }
      return actionItems;
    }
    
    // actionItem이 있는 경우
    if (actionItem.isNotEmpty) {
      // JSON 배열 문자열인 경우 파싱
      if (actionItem.startsWith('[')) {
        try {
          final parsed = jsonDecode(actionItem);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // 파싱 실패 시 그대로 반환
        }
      }
      return [actionItem];
    }
    
    return [];
  }

  /// copyWith 메서드
  /// clear* 파라미터를 사용하여 nullable 필드를 명시적으로 null로 설정할 수 있습니다.
  AnalysisResult copyWith({
    List<String>? keywords,
    int? sentimentScore,
    String? empathyMessage,
    String? actionItem,
    List<String>? actionItems,
    DateTime? analyzedAt,
    bool? isActionCompleted,
    bool? isEmergency,
    String? aiCharacterId,
    bool clearAiCharacterId = false,
    EmotionCategory? emotionCategory,
    bool clearEmotionCategory = false,
    EmotionTrigger? emotionTrigger,
    bool clearEmotionTrigger = false,
    int? energyLevel,
    bool clearEnergyLevel = false,
    String? cognitivePattern,
    bool clearCognitivePattern = false,
  }) {
    return AnalysisResult(
      keywords: keywords ?? this.keywords,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      empathyMessage: empathyMessage ?? this.empathyMessage,
      actionItem: actionItem ?? this.actionItem,
      actionItems: actionItems ?? this.actionItems,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      isActionCompleted: isActionCompleted ?? this.isActionCompleted,
      isEmergency: isEmergency ?? this.isEmergency,
      aiCharacterId: clearAiCharacterId ? null : (aiCharacterId ?? this.aiCharacterId),
      emotionCategory: clearEmotionCategory ? null : (emotionCategory ?? this.emotionCategory),
      emotionTrigger: clearEmotionTrigger ? null : (emotionTrigger ?? this.emotionTrigger),
      energyLevel: clearEnergyLevel ? null : (energyLevel ?? this.energyLevel),
      cognitivePattern: clearCognitivePattern ? null : (cognitivePattern ?? this.cognitivePattern),
    );
  }
}
