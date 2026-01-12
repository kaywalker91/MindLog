import 'dart:convert';
import '../../domain/entities/diary.dart';

/// 감정 범주 DTO
class EmotionCategoryDto {
  /// 1차 감정 (기쁨, 슬픔, 분노, 공포, 놀람, 혐오)
  final String primary;

  /// 2차 감정 (세부 감정)
  final String secondary;

  const EmotionCategoryDto({
    required this.primary,
    required this.secondary,
  });

  factory EmotionCategoryDto.fromJson(Map<String, dynamic> json) {
    return EmotionCategoryDto(
      primary: json['primary'] as String? ?? '평온',
      secondary: json['secondary'] as String? ?? '보통',
    );
  }

  Map<String, dynamic> toJson() => {
        'primary': primary,
        'secondary': secondary,
      };

  EmotionCategory toEntity() => EmotionCategory(
        primary: primary,
        secondary: secondary,
      );
}

/// 감정 유발 요인 DTO
class EmotionTriggerDto {
  /// 카테고리 (일/업무, 관계, 건강, 재정, 자아, 환경, 기타)
  final String category;

  /// 간단한 설명
  final String description;

  const EmotionTriggerDto({
    required this.category,
    required this.description,
  });

  factory EmotionTriggerDto.fromJson(Map<String, dynamic> json) {
    return EmotionTriggerDto(
      category: json['category'] as String? ?? '기타',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
      };

  EmotionTrigger toEntity() => EmotionTrigger(
        category: category,
        description: description,
      );
}

/// AI 분석 응답 DTO
class AnalysisResponseDto {
  /// 감정 키워드 (5개)
  final List<String> keywords;

  /// 감정 점수 (1-10)
  final int sentimentScore;

  /// 공감 메시지
  final String empathyMessage;

  /// 추천 행동 (레거시 지원용)
  final String actionItem;

  /// 단계별 추천 행동 (즉시/오늘/이번주)
  final List<String> actionItems;

  /// 응급 상황 여부
  final bool isEmergency;

  /// 감정 범주 (1차/2차 감정)
  final EmotionCategoryDto? emotionCategory;

  /// 감정 유발 요인
  final EmotionTriggerDto? emotionTrigger;

  /// 에너지 레벨 (1-10)
  final int? energyLevel;

  /// 인지 패턴 (선택적)
  final String? cognitivePattern;

  const AnalysisResponseDto({
    required this.keywords,
    required this.sentimentScore,
    required this.empathyMessage,
    required this.actionItem,
    this.actionItems = const [],
    this.isEmergency = false,
    this.emotionCategory,
    this.emotionTrigger,
    this.energyLevel,
    this.cognitivePattern,
  });

  factory AnalysisResponseDto.fromJson(Map<String, dynamic> json) {
    // actionItems 파싱 (새 필드)
    List<String> parsedActionItems = [];
    final rawActionItems = json['action_items'];
    
    if (rawActionItems != null) {
      if (rawActionItems is List) {
        // 정상적인 배열인 경우
        parsedActionItems = rawActionItems.map((e) => e.toString()).toList();
      } else if (rawActionItems is String && rawActionItems.isNotEmpty) {
        // AI가 문자열로 반환한 경우 (예: "[\"행동1\", \"행동2\"]")
        try {
          if (rawActionItems.startsWith('[')) {
            final decoded = jsonDecode(rawActionItems);
            if (decoded is List) {
              parsedActionItems = decoded.map((e) => e.toString()).toList();
            }
          } else {
            // 단일 문자열인 경우
            parsedActionItems = [rawActionItems];
          }
        } catch (_) {
          // JSON 파싱 실패 시 단일 문자열로 처리
          parsedActionItems = [rawActionItems];
        }
      }
    }

    // 레거시 호환: action_item만 있는 경우
    final legacyActionItem = json['action_item'] as String? ?? '';

    return AnalysisResponseDto(
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      sentimentScore: json['sentiment_score'] as int,
      empathyMessage: json['empathy_message'] as String,
      actionItem: legacyActionItem,
      actionItems: parsedActionItems.isNotEmpty
          ? parsedActionItems
          : (legacyActionItem.isNotEmpty ? [legacyActionItem] : []),
      isEmergency: json['is_emergency'] as bool? ?? false,
      emotionCategory: json['emotion_category'] != null
          ? EmotionCategoryDto.fromJson(
              json['emotion_category'] as Map<String, dynamic>)
          : null,
      emotionTrigger: json['emotion_trigger'] != null
          ? EmotionTriggerDto.fromJson(
              json['emotion_trigger'] as Map<String, dynamic>)
          : null,
      energyLevel: json['energy_level'] as int?,
      cognitivePattern: json['cognitive_pattern'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords,
      'sentiment_score': sentimentScore,
      'empathy_message': empathyMessage,
      'action_item': actionItem,
      'action_items': actionItems,
      'is_emergency': isEmergency,
      if (emotionCategory != null) 'emotion_category': emotionCategory!.toJson(),
      if (emotionTrigger != null) 'emotion_trigger': emotionTrigger!.toJson(),
      if (energyLevel != null) 'energy_level': energyLevel,
      if (cognitivePattern != null) 'cognitive_pattern': cognitivePattern,
    };
  }

  /// DTO → Entity 변환
  /// [analyzedAt]을 선택적 파라미터로 받아 테스트 용이성 확보
  AnalysisResult toEntity({DateTime? analyzedAt}) {
    return AnalysisResult(
      keywords: keywords,
      sentimentScore: sentimentScore.clamp(1, 10),
      empathyMessage: empathyMessage,
      actionItem: actionItem,
      actionItems: actionItems,
      analyzedAt: analyzedAt ?? DateTime.now(),
      isEmergency: isEmergency,
      emotionCategory: emotionCategory?.toEntity(),
      emotionTrigger: emotionTrigger?.toEntity(),
      energyLevel: energyLevel?.clamp(1, 10),
      cognitivePattern: cognitivePattern,
    );
  }
}
