import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/sqlite_local_datasource.dart';
import '../../data/datasources/local/preferences_local_datasource.dart';
import '../../data/datasources/remote/groq_remote_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/usecases/analyze_diary_usecase.dart';
import '../../domain/usecases/get_selected_ai_character_usecase.dart';
import '../../domain/usecases/get_statistics_usecase.dart';
import '../../domain/usecases/set_selected_ai_character_usecase.dart';

/// SQLite 로컬 데이터 소스 Provider
final sqliteLocalDataSourceProvider = Provider<SqliteLocalDataSource>((ref) {
  return SqliteLocalDataSource();
});

/// Preferences 로컬 데이터 소스 Provider
final preferencesLocalDataSourceProvider =
    Provider<PreferencesLocalDataSource>((ref) {
  return PreferencesLocalDataSource();
});

/// Groq 원격 데이터 소스 Provider
/// API 키가 없으면 빈 문자열로 인스턴스 생성 (실제 API 호출 시점에 에러 발생)
final groqRemoteDataSourceProvider = Provider<GroqRemoteDataSource>((ref) {
  final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  return GroqRemoteDataSource(apiKey);
});

/// DiaryRepository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),
    remoteDataSource: ref.watch(groqRemoteDataSourceProvider),
  );
});

/// SettingsRepository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(preferencesLocalDataSourceProvider),
  );
});

/// AnalyzeDiaryUseCase Provider
final analyzeDiaryUseCaseProvider = Provider<AnalyzeDiaryUseCase>((ref) {
  return AnalyzeDiaryUseCase(
    ref.watch(diaryRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
});

/// GetSelectedAiCharacterUseCase Provider
final getSelectedAiCharacterUseCaseProvider =
    Provider<GetSelectedAiCharacterUseCase>((ref) {
  return GetSelectedAiCharacterUseCase(ref.watch(settingsRepositoryProvider));
});

/// SetSelectedAiCharacterUseCase Provider
final setSelectedAiCharacterUseCaseProvider =
    Provider<SetSelectedAiCharacterUseCase>((ref) {
  return SetSelectedAiCharacterUseCase(ref.watch(settingsRepositoryProvider));
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
