import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/ai_character.dart';
import '../../core/errors/failures.dart';
import '../../../domain/entities/diary.dart';
import '../../../domain/repositories/diary_repository.dart';
import 'repository_failure_handler.dart';
import '../datasources/local/sqlite_local_datasource.dart';
import '../datasources/remote/groq_remote_datasource.dart';

/// 일기 Repository 구현체
class DiaryRepositoryImpl
    with RepositoryFailureHandler
    implements DiaryRepository {
  final SqliteLocalDataSource _localDataSource;
  final GroqRemoteDataSource _remoteDataSource;

  DiaryRepositoryImpl({
    required SqliteLocalDataSource localDataSource,
    required GroqRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<Diary> createDiary(String content, {List<String>? imagePaths}) async {
    return guardFailure('일기 생성 실패', () async {
      final diary = Diary(
        id: _generateId(),
        content: content,
        createdAt: DateTime.now(),
        status: DiaryStatus.pending,
        imagePaths: imagePaths,
      );
      await _localDataSource.saveDiary(diary);
      return diary;
    });
  }

  @override
  Future<Diary> analyzeDiary(
    String diaryId, {
    required AiCharacter character,
    String? userName,
    List<String>? imagePaths,
  }) async {
    var diaryLoaded = false;
    return guardFailureWithHook(
      '일기 분석 실패',
      () async {
        final diary = await _localDataSource.getDiaryById(diaryId);
        if (diary == null) {
          throw const Failure.dataNotFound(message: '일기를 찾을 수 없습니다.');
        }
        diaryLoaded = true;

        // 이미지가 있으면 Vision API 사용, 없으면 텍스트 전용 API 사용
        final effectiveImagePaths = imagePaths ?? diary.imagePaths;
        final hasImages =
            effectiveImagePaths != null && effectiveImagePaths.isNotEmpty;

        final analysisDto = hasImages
            ? await _remoteDataSource.analyzeDiaryWithImages(
                diary.content,
                imagePaths: effectiveImagePaths,
                character: character,
                userName: userName,
              )
            : await _remoteDataSource.analyzeDiary(
                diary.content,
                character: character,
                userName: userName,
              );

        final analysisResult = analysisDto.toEntity().copyWith(
          aiCharacterId: character.id,
        );

        // 분석 결과를 로컬에 저장
        await _localDataSource.updateDiaryWithAnalysis(diaryId, analysisResult);

        return diary.copyWith(
          status: DiaryStatus.analyzed,
          analysisResult: analysisResult,
        );
      },
      onFailure: (failure) async {
        if (diaryLoaded) {
          await _updateDiaryStatusOnFailure(diaryId, failure);
        }
      },
      onUnknownFailure: (error, stackTrace) {
        // 디버그 모드에서만 로깅
        assert(() {
          debugPrint('Unknown Exception in analyzeDiary: $error');
          debugPrint('Stack Trace: $stackTrace');
          return true;
        }());
      },
    );
  }

  @override
  Future<void> updateDiary(Diary diary) async {
    return guardFailure('일기 업데이트 실패', () async {
      // 상태와 분석 결과를 모두 업데이트
      await _localDataSource.updateDiaryStatus(diary.id, diary.status);
      if (diary.analysisResult != null) {
        await _localDataSource.updateDiaryWithAnalysis(
          diary.id,
          diary.analysisResult!,
        );
      }
    });
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    return guardFailure(
      '일기 조회 실패',
      () => _localDataSource.getDiaryById(diaryId),
    );
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    return guardFailure('일기 목록 조회 실패', _localDataSource.getAllDiaries);
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    return guardFailure('오늘 일기 조회 실패', _localDataSource.getTodayDiaries);
  }

  @override
  Future<void> markActionCompleted(String diaryId) async {
    return guardFailure('행동 완료 표시 실패', () async {
      final diary = await _localDataSource.getDiaryById(diaryId);
      if (diary == null) {
        throw const Failure.dataNotFound(message: '일기를 찾을 수 없습니다.');
      }

      if (diary.analysisResult != null) {
        final updatedAnalysis = diary.analysisResult!.copyWith(
          isActionCompleted: true,
        );
        await _localDataSource.updateDiaryWithAnalysis(
          diaryId,
          updatedAnalysis,
        );
      }
    });
  }

  @override
  Future<void> toggleDiaryPin(String diaryId, bool isPinned) async {
    return guardFailure(
      '일기 고정 상태 업데이트 실패',
      () => _localDataSource.updateDiaryPin(diaryId, isPinned),
    );
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    return guardFailure(
      '일기 삭제 실패',
      () => _localDataSource.deleteDiary(diaryId),
    );
  }

  @override
  Future<void> deleteAllDiaries() async {
    return guardFailure('모든 일기 삭제 실패', _localDataSource.deleteAllDiaries);
  }

  String _generateId() => const Uuid().v4();

  Future<void> _updateDiaryStatusOnFailure(
    String diaryId,
    Failure failure,
  ) async {
    try {
      if (failure is SafetyBlockedFailure) {
        await _localDataSource.updateDiaryStatus(
          diaryId,
          DiaryStatus.safetyBlocked,
        );
        return;
      }
      if (failure is NetworkFailure ||
          failure is ApiFailure ||
          failure is ServerFailure) {
        await _localDataSource.updateDiaryStatus(diaryId, DiaryStatus.failed);
      }
    } catch (_) {
      // 상태 업데이트 실패는 원본 오류를 덮지 않기 위해 무시
    }
  }
}
