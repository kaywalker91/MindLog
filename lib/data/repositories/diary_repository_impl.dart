import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/ai_character.dart';
import '../../../domain/entities/diary.dart';
import '../../../domain/repositories/diary_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/sqlite_local_datasource.dart';
import '../datasources/remote/groq_remote_datasource.dart';
import '../../core/errors/exceptions.dart';

/// 일기 Repository 구현체
class DiaryRepositoryImpl implements DiaryRepository {
  final SqliteLocalDataSource _localDataSource;
  final GroqRemoteDataSource _remoteDataSource;

  DiaryRepositoryImpl({
    required SqliteLocalDataSource localDataSource,
    required GroqRemoteDataSource remoteDataSource,
  }) : 
        _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Diary> createDiary(String content) async {
    try {
      final diary = Diary(
        id: _generateId(),
        content: content,
        createdAt: DateTime.now(),
        status: DiaryStatus.pending,
      );
      await _localDataSource.saveDiary(diary);
      return diary;
    } catch (e) {
      throw CacheFailure(message: '일기 생성 실패: $e');
    }
  }

  @override
  Future<Diary> analyzeDiary(
    String diaryId, {
    required AiCharacter character,
  }) async {
    try {
      final diary = await _localDataSource.getDiaryById(diaryId);
      if (diary == null) {
        throw CacheFailure(message: '일기를 찾을 수 없습니다: $diaryId');
      }

      // 원격 API 호출
      final analysisDto =
          await _remoteDataSource.analyzeDiary(diary.content, character: character);
      final analysisResult = analysisDto.toEntity().copyWith(
        aiCharacterId: character.id,
      );

      // 분석 결과를 로컬에 저장
      await _localDataSource.updateDiaryWithAnalysis(diaryId, analysisResult);

      return diary.copyWith(
        status: DiaryStatus.analyzed,
        analysisResult: analysisResult,
      );
    } on NetworkException catch (e) {
      await _localDataSource.updateDiaryStatus(diaryId, DiaryStatus.failed);
      throw NetworkFailure(message: e.message ?? '네트워크 오류');
    } on ApiException catch (e) {
      await _localDataSource.updateDiaryStatus(diaryId, DiaryStatus.failed);
      throw ServerFailure(message: e.message ?? 'API 오류');
    } on SafetyBlockException catch (e) {
      await _localDataSource.updateDiaryStatus(diaryId, DiaryStatus.safetyBlocked);
      throw ServerFailure(message: e.message ?? '안전 필터에 의해 차단됨');
    } catch (e, stackTrace) {
      // 디버그 모드에서만 로깅
      assert(() {
        debugPrint('Unknown Exception in analyzeDiary: $e');
        debugPrint('Stack Trace: $stackTrace');
        return true;
      }());
      throw const CacheFailure(message: '일기 분석 실패');
    }
  }

  @override
  Future<void> updateDiary(Diary diary) async {
    try {
      // 상태와 분석 결과를 모두 업데이트
      await _localDataSource.updateDiaryStatus(diary.id, diary.status);
      if (diary.analysisResult != null) {
        await _localDataSource.updateDiaryWithAnalysis(
          diary.id,
          diary.analysisResult!,
        );
      }
    } catch (e) {
      throw CacheFailure(message: '일기 업데이트 실패: $e');
    }
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    try {
      return await _localDataSource.getDiaryById(diaryId);
    } catch (e) {
      throw CacheFailure(message: '일기 조회 실패: $e');
    }
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    try {
      return await _localDataSource.getAllDiaries();
    } catch (e) {
      throw CacheFailure(message: '일기 목록 조회 실패: $e');
    }
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    try {
      return await _localDataSource.getTodayDiaries();
    } catch (e) {
      throw CacheFailure(message: '오늘 일기 조회 실패: $e');
    }
  }

  @override
  Future<void> markActionCompleted(String diaryId) async {
    try {
      final diary = await _localDataSource.getDiaryById(diaryId);
      if (diary == null) {
        throw CacheFailure(message: '일기를 찾을 수 없습니다: $diaryId');
      }

      if (diary.analysisResult != null) {
        final updatedAnalysis = diary.analysisResult!.copyWith(
          isActionCompleted: true,
        );
        await _localDataSource.updateDiaryWithAnalysis(diaryId, updatedAnalysis);
      }
    } catch (e) {
      throw CacheFailure(message: '행동 완료 표시 실패: $e');
    }
  }

  @override
  Future<void> toggleDiaryPin(String diaryId, bool isPinned) async {
    try {
      await _localDataSource.updateDiaryPin(diaryId, isPinned);
    } catch (e) {
      throw CacheFailure(message: '일기 고정 상태 업데이트 실패: $e');
    }
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    try {
      await _localDataSource.deleteDiary(diaryId);
    } catch (e) {
      throw CacheFailure(message: '일기 삭제 실패: $e');
    }
  }

  @override
  Future<void> deleteAllDiaries() async {
    try {
      await _localDataSource.deleteAllDiaries();
    } catch (e) {
      throw CacheFailure(message: '모든 일기 삭제 실패: $e');
    }
  }

  String _generateId() => const Uuid().v4();
}
