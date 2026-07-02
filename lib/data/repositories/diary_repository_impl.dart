import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/ai_character.dart';
import '../../core/errors/failures.dart';
import '../../../domain/entities/diary.dart';
import '../../../domain/repositories/diary_repository.dart';
import 'repository_failure_handler.dart';
import '../datasources/local/groq_cache_key.dart';
import '../datasources/local/sqlite_local_datasource.dart';
import '../datasources/remote/groq_remote_datasource.dart';
import '../dto/analysis_response_dto.dart';

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
  Future<Diary> createDiary(
    String content, {
    List<String>? imagePaths,
    DateTime? createdAt,
  }) async {
    return guardFailure('일기 생성 실패', () async {
      final diary = Diary(
        id: _generateId(),
        content: content,
        createdAt: createdAt ?? DateTime.now(),
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

        // 캐시 키: content hash 기반 (일기 ID 무관)
        // → 임시저장/복원/재시도/동일 내용 작성 시 cache hit
        final cacheKey = hasImages
            ? GroqCacheKey.forVision(
                content: diary.content,
                character: character,
                imageSignatures: effectiveImagePaths,
                userName: userName,
              )
            : GroqCacheKey.forText(
                content: diary.content,
                character: character,
                userName: userName,
              );

        AnalysisResponseDto? analysisDto = await _readGroqCache(cacheKey);

        if (analysisDto == null) {
          analysisDto = hasImages
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

          // 안전: is_emergency=true 응답은 캐시하지 않음 (위기 감지는 매번 재평가)
          if (!analysisDto.isEmergency) {
            await _writeGroqCache(cacheKey, analysisDto);
          }
        }

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

  @override
  Future<void> setDiarySecret(String diaryId, bool isSecret) async {
    return guardFailure(
      '일기 비밀 상태 업데이트 실패',
      () => _localDataSource.updateDiarySecret(diaryId, isSecret),
    );
  }

  @override
  Future<List<Diary>> getSecretDiaries() async {
    return guardFailure('비밀일기 목록 조회 실패', _localDataSource.getSecretDiaries);
  }

  String _generateId() => const Uuid().v4();

  /// 캐시에서 응답 DTO 복원. miss 또는 손상 시 null.
  Future<AnalysisResponseDto?> _readGroqCache(String cacheKey) async {
    try {
      final cached = await _localDataSource.getGroqCachedResponse(cacheKey);
      if (cached == null) return null;
      return AnalysisResponseDto.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (e) {
      assert(() {
        debugPrint('[DiaryRepository] Cache read failed: $e');
        return true;
      }());
      return null;
    }
  }

  /// 응답 DTO를 캐시에 저장. 실패 시 무시 (분석 결과를 막지 않음).
  Future<void> _writeGroqCache(String cacheKey, AnalysisResponseDto dto) async {
    try {
      await _localDataSource.putGroqCachedResponse(
        cacheKey,
        jsonEncode(dto.toJson()),
      );
    } catch (e) {
      assert(() {
        debugPrint('[DiaryRepository] Cache write failed: $e');
        return true;
      }());
    }
  }

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
