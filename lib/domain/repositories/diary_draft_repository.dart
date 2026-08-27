import '../entities/diary_draft.dart';

/// 일기 임시저장(초안) 저장소 인터페이스
abstract class DiaryDraftRepository {
  /// 저장된 초안 조회. 없으면 null.
  Future<DiaryDraft?> getDraft();

  /// 초안 저장 (upsert, 단일 슬롯)
  Future<void> saveDraft(DiaryDraft draft);

  /// 초안 삭제 (없어도 성공)
  Future<void> clearDraft();
}
