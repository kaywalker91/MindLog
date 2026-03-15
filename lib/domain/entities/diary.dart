import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary.freezed.dart';
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
@freezed
class Diary with _$Diary {
  const Diary._();

  const factory Diary({
    /// 고유 ID
    required String id,

    /// 일기 내용
    required String content,

    /// 작성 시간
    required DateTime createdAt,

    /// 분석 상태
    @Default(DiaryStatus.pending) DiaryStatus status,

    /// 분석 결과 (분석 완료 시)
    AnalysisResult? analysisResult,

    /// 상단 고정 여부
    @Default(false) bool isPinned,

    /// 첨부 이미지 경로 목록 (nullable - 하위 호환성 유지)
    List<String>? imagePaths,

    /// 비밀일기 여부 (기본값 false - 하위 호환성 유지)
    @Default(false) bool isSecret,
  }) = _Diary;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);

  /// 이미지가 첨부되어 있는지 여부
  bool get hasImages => imagePaths != null && imagePaths!.isNotEmpty;

  /// 첨부된 이미지 수
  int get imageCount => imagePaths?.length ?? 0;
}

/// 감정 범주 (1차/2차 감정)
@freezed
class EmotionCategory with _$EmotionCategory {
  const factory EmotionCategory({
    /// 1차 감정 (기쁨, 슬픔, 분노, 공포, 놀람, 혐오, 평온)
    required String primary,

    /// 2차 감정 (세부 감정)
    required String secondary,
  }) = _EmotionCategory;

  factory EmotionCategory.fromJson(Map<String, dynamic> json) =>
      _$EmotionCategoryFromJson(json);

  // primaryEmoji getter는 Presentation Layer로 이동됨
  // → lib/presentation/extensions/emotion_emoji_extension.dart
}

/// 감정 유발 요인
@freezed
class EmotionTrigger with _$EmotionTrigger {
  const factory EmotionTrigger({
    /// 카테고리
    required String category,

    /// 설명
    required String description,
  }) = _EmotionTrigger;

  factory EmotionTrigger.fromJson(Map<String, dynamic> json) =>
      _$EmotionTriggerFromJson(json);

  // categoryEmoji getter는 Presentation Layer로 이동됨
  // → lib/presentation/extensions/emotion_emoji_extension.dart
}

/// JSON에서 analyzedAt이 null일 경우 현재 시간 반환 (기존 데이터 호환용)
DateTime _dateTimeFromJsonOrNow(String? json) =>
    json != null ? DateTime.parse(json) : DateTime.now();

/// 감정 분석 결과 엔티티
@freezed
class AnalysisResult with _$AnalysisResult {
  const AnalysisResult._();

  /// [analyzedAt]은 필수 파라미터로, 호출자가 명시적으로 제공해야 합니다.
  /// 테스트에서는 고정된 시간을 주입하여 결정론적 테스트가 가능합니다.
  /// 프로덕션 코드에서는 `DateTime.now()`를 전달합니다.
  const factory AnalysisResult({
    /// 감정 키워드 (최대 5개)
    @Default([]) List<String> keywords,

    /// 감정 점수 (1-10)
    @Default(5) int sentimentScore,

    /// 공감 메시지
    @Default('') String empathyMessage,

    /// 추천 행동 (레거시 호환용)
    @Default('') String actionItem,

    /// 단계별 추천 행동 (즉시/오늘/이번주)
    @Default([]) List<String> actionItems,

    /// 분석 시간 (JSON에서 null일 경우 현재 시간으로 대체)
    @JsonKey(fromJson: _dateTimeFromJsonOrNow) required DateTime analyzedAt,

    /// 추천 행동 완료 여부
    @Default(false) bool isActionCompleted,

    /// 응급 상황 여부 (자해/자살 위험 등)
    @Default(false) bool isEmergency,

    /// AI 캐릭터 ID (설정 시점 기준)
    String? aiCharacterId,

    /// 감정 범주 (1차/2차 감정)
    EmotionCategory? emotionCategory,

    /// 감정 유발 요인
    EmotionTrigger? emotionTrigger,

    /// 에너지 레벨 (1-10)
    int? energyLevel,

    /// 인지 패턴 (선택적 - 부정적 사고 패턴 감지 시)
    String? cognitivePattern,
  }) = _AnalysisResult;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

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
}
