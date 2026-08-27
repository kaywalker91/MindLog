import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_draft.freezed.dart';
part 'diary_draft.g.dart';

/// 일기 임시저장(초안) 엔티티
@freezed
class DiaryDraft with _$DiaryDraft {
  const DiaryDraft._();

  const factory DiaryDraft({
    /// 작성 중인 일기 내용
    required String content,

    /// 대상 날짜
    required DateTime entryDate,

    /// 마지막 수정 시각
    required DateTime updatedAt,

    /// 첨부 이미지 경로 목록 (선택)
    List<String>? imagePaths,
  }) = _DiaryDraft;

  factory DiaryDraft.fromJson(Map<String, dynamic> json) =>
      _$DiaryDraftFromJson(json);

  /// 이미지가 첨부되어 있는지 여부
  bool get hasImages => imagePaths != null && imagePaths!.isNotEmpty;

  /// [now] 기준 [ttl] 이 경과했는지
  bool isExpired(DateTime now, Duration ttl) =>
      now.difference(updatedAt) >= ttl;
}
