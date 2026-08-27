import 'dart:io';

import '../../domain/entities/diary_draft.dart';
import '../../domain/repositories/diary_draft_repository.dart';
import '../datasources/local/preferences_local_datasource.dart';
import 'repository_failure_handler.dart';

/// 일기 초안 Repository 구현체
class DiaryDraftRepositoryImpl
    with RepositoryFailureHandler
    implements DiaryDraftRepository {
  DiaryDraftRepositoryImpl(this._localDataSource);

  final PreferencesLocalDataSource _localDataSource;

  @override
  Future<DiaryDraft?> getDraft() async {
    return guardFailure('일기 초안 조회 실패', () async {
      final draft = await _localDataSource.getDiaryDraft();
      if (draft == null || draft.imagePaths == null) {
        return draft;
      }

      final existingImagePaths = draft.imagePaths!
          .where((path) => File(path).existsSync())
          .toList();

      return draft.copyWith(
        imagePaths: existingImagePaths.isEmpty ? null : existingImagePaths,
      );
    });
  }

  @override
  Future<void> saveDraft(DiaryDraft draft) async {
    return guardFailure(
      '일기 초안 저장 실패',
      () => _localDataSource.setDiaryDraft(draft),
    );
  }

  @override
  Future<void> clearDraft() async {
    return guardFailure(
      '일기 초안 삭제 실패',
      _localDataSource.clearDiaryDraft,
    );
  }
}
