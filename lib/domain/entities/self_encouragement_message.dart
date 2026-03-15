import 'package:freezed_annotation/freezed_annotation.dart';

part 'self_encouragement_message.freezed.dart';
part 'self_encouragement_message.g.dart';

/// 사용자가 직접 작성한 응원 메시지 엔티티
@freezed
class SelfEncouragementMessage with _$SelfEncouragementMessage {
  const factory SelfEncouragementMessage({
    required String id,
    required String content,
    required DateTime createdAt,
    required int displayOrder,
    @JsonKey(includeIfNull: false) String? category,
    @JsonKey(includeIfNull: false) double? writtenEmotionScore,
  }) = _SelfEncouragementMessage;

  factory SelfEncouragementMessage.fromJson(Map<String, dynamic> json) =>
      _$SelfEncouragementMessageFromJson(json);

  /// 최대 메시지 길이
  static const int maxContentLength = 100;

  /// 최대 등록 가능 메시지 수
  static const int maxMessageCount = 10;
}

/// 메시지 로테이션 모드
enum MessageRotationMode {
  /// 랜덤 선택
  random,

  /// 순차 선택 (displayOrder 순)
  sequential,

  /// 감정 기반 선택 (현재 감정에 맞는 메시지 우선)
  emotionAware,
}
