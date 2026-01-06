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

  Diary copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DiaryStatus? status,
    AnalysisResult? analysisResult,
    bool? isPinned,
  }) {
    return Diary(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      analysisResult: analysisResult ?? this.analysisResult,
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

  /// 1차 감정에 해당하는 이모지 반환
  String get primaryEmoji {
    switch (primary) {
      case '기쁨':
        return '😊';
      case '슬픔':
        return '😢';
      case '분노':
        return '😠';
      case '공포':
        return '😨';
      case '놀람':
        return '😲';
      case '혐오':
        return '🤢';
      case '평온':
      default:
        return '😌';
    }
  }
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

  /// 카테고리에 해당하는 아이콘 이모지 반환
  String get categoryEmoji {
    switch (category) {
      case '일/업무':
        return '💼';
      case '관계':
        return '👥';
      case '건강':
        return '🏥';
      case '재정':
        return '💰';
      case '자아':
        return '🪞';
      case '환경':
        return '🏠';
      case '기타':
      default:
        return '📌';
    }
  }
}

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

  /// 분석 시간
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

  AnalysisResult({
    this.keywords = const [],
    this.sentimentScore = 5,
    this.empathyMessage = '',
    this.actionItem = '',
    this.actionItems = const [],
    DateTime? analyzedAt,
    this.isActionCompleted = false,
    this.isEmergency = false,
    this.aiCharacterId,
    this.emotionCategory,
    this.emotionTrigger,
    this.energyLevel,
    this.cognitivePattern,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

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
    EmotionCategory? emotionCategory,
    EmotionTrigger? emotionTrigger,
    int? energyLevel,
    String? cognitivePattern,
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
      aiCharacterId: aiCharacterId ?? this.aiCharacterId,
      emotionCategory: emotionCategory ?? this.emotionCategory,
      emotionTrigger: emotionTrigger ?? this.emotionTrigger,
      energyLevel: energyLevel ?? this.energyLevel,
      cognitivePattern: cognitivePattern ?? this.cognitivePattern,
    );
  }
}
