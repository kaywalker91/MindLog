import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/sqlite_local_datasource.dart';
import '../../data/datasources/remote/groq_remote_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/usecases/analyze_diary_usecase.dart';

/// SQLite 로컬 데이터 소스 Provider
final sqliteLocalDataSourceProvider = Provider<SqliteLocalDataSource>((ref) {
  return SqliteLocalDataSource();
});

/// Groq 원격 데이터 소스 Provider
final groqRemoteDataSourceProvider = Provider<GroqRemoteDataSource>((ref) {
  final apiKey = dotenv.env['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('GROQ_API_KEY is not set in .env file');
  }
  return GroqRemoteDataSource(apiKey);
});

/// DiaryRepository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),
    remoteDataSource: ref.watch(groqRemoteDataSourceProvider),
  );
});

/// AnalyzeDiaryUseCase Provider
final analyzeDiaryUseCaseProvider = Provider<AnalyzeDiaryUseCase>((ref) {
  return AnalyzeDiaryUseCase(ref.watch(diaryRepositoryProvider));
});
