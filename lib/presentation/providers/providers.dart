import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_local_datasource.dart';
import '../../data/datasources/remote/gemini_remote_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/usecases/analyze_diary_usecase.dart';

/// Hive 로컬 데이터 소스 Provider
final hiveLocalDataSourceProvider = Provider<HiveLocalDataSource>((ref) {
  return HiveLocalDataSource();
});

/// Gemini 원격 데이터 소스 Provider
final geminiRemoteDataSourceProvider = Provider<GeminiRemoteDataSource>((ref) {
  return GeminiRemoteDataSource();
});

/// DiaryRepository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    localDataSource: ref.watch(hiveLocalDataSourceProvider),
    remoteDataSource: ref.watch(geminiRemoteDataSourceProvider),
  );
});

/// AnalyzeDiaryUseCase Provider
final analyzeDiaryUseCaseProvider = Provider<AnalyzeDiaryUseCase>((ref) {
  return AnalyzeDiaryUseCase(ref.watch(diaryRepositoryProvider));
});
