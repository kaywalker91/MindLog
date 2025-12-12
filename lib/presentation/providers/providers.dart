import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/sqlite_local_datasource.dart';
import '../../data/datasources/remote/groq_remote_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/usecases/analyze_diary_usecase.dart';
import '../../domain/usecases/get_statistics_usecase.dart';

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

// ============ Statistics Providers ============

/// StatisticsRepository Provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),
  );
});

/// GetStatisticsUseCase Provider
final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  return GetStatisticsUseCase(ref.watch(statisticsRepositoryProvider));
});

/// 현재 선택된 통계 기간 Provider
final selectedStatisticsPeriodProvider =
    StateProvider<StatisticsPeriod>((ref) => StatisticsPeriod.week);

/// 통계 데이터 Provider
final statisticsProvider =
    FutureProvider.autoDispose<EmotionStatistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  final period = ref.watch(selectedStatisticsPeriodProvider);
  return await useCase.execute(period);
});

/// 상위 키워드 Provider (상위 10개)
final topKeywordsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return await useCase.getKeywordFrequency(limit: 10);
});
