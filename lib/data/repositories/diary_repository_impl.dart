import '../../domain/entities/diary.dart';
import '../../domain/repositories/diary_repository.dart';
import '../datasources/local/hive_local_datasource.dart';
import '../datasources/remote/gemini_remote_datasource.dart';
import '../dto/diary_dto.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';

/// DiaryRepository 구현체
class DiaryRepositoryImpl implements DiaryRepository {
  final HiveLocalDataSource _localDataSource;
  final GeminiRemoteDataSource _remoteDataSource;

  DiaryRepositoryImpl({
    required HiveLocalDataSource localDataSource,
    required GeminiRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Diary> saveDiary(Diary diary) async {
    try {
      final dto = diary.toDto();
      final savedDto = await _localDataSource.saveDiary(dto);
      return savedDto.toEntity();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<AnalysisResult> analyzeDiary(String content) async {
    try {
      final responseDto = await _remoteDataSource.analyzeDiary(content);
      return responseDto.toEntity();
    } on SafetyBlockException {
      throw const Failure.safetyBlocked();
    } on NetworkException catch (e) {
      throw Failure.network(message: e.message);
    } on ApiException catch (e) {
      throw Failure.api(message: e.message);
    }
  }

  @override
  Future<Diary> updateDiaryWithAnalysis(
    String diaryId,
    AnalysisResult result,
  ) async {
    try {
      final existingDto = await _localDataSource.getDiaryById(diaryId);
      if (existingDto == null) {
        throw const Failure.database(message: '일기를 찾을 수 없습니다');
      }

      // 분석 결과 업데이트
      existingDto
        ..status = DiaryStatus.analyzed
        ..keywords = result.keywords.join(',')
        ..sentimentScore = result.sentimentScore
        ..empathyMessage = result.empathyMessage
        ..actionItem = result.actionItem
        ..analyzedAt = result.analyzedAt
        ..isActionCompleted = result.isActionCompleted;

      final updatedDto = await _localDataSource.updateDiary(existingDto);
      return updatedDto.toEntity();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<Diary> updateDiaryStatus(String diaryId, DiaryStatus status) async {
    try {
      final existingDto = await _localDataSource.getDiaryById(diaryId);
      if (existingDto == null) {
        throw const Failure.database(message: '일기를 찾을 수 없습니다');
      }

      existingDto.status = status;
      final updatedDto = await _localDataSource.updateDiary(existingDto);
      return updatedDto.toEntity();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<Diary?> getDiaryById(String id) async {
    try {
      final dto = await _localDataSource.getDiaryById(id);
      return dto?.toEntity();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    try {
      final dtos = await _localDataSource.getAllDiaries();
      return dtos.map((dto) => dto.toEntity()).toList();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<List<Diary>> getTodayDiaries() async {
    try {
      final dtos = await _localDataSource.getTodayDiaries();
      return dtos.map((dto) => dto.toEntity()).toList();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<Diary> toggleActionComplete(String diaryId) async {
    try {
      final existingDto = await _localDataSource.getDiaryById(diaryId);
      if (existingDto == null) {
        throw const Failure.database(message: '일기를 찾을 수 없습니다');
      }

      existingDto.isActionCompleted = !existingDto.isActionCompleted;
      final updatedDto = await _localDataSource.updateDiary(existingDto);
      return updatedDto.toEntity();
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    try {
      await _localDataSource.deleteDiary(diaryId);
    } on DatabaseException catch (e) {
      throw Failure.database(message: e.message);
    }
  }
}
