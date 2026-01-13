import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/config/environment_service.dart';
import 'package:mindlog/core/network/circuit_breaker.dart';
import 'package:mindlog/data/datasources/local/preferences_local_datasource.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';
import 'package:mindlog/data/repositories/diary_repository_impl.dart';
import 'package:mindlog/data/repositories/settings_repository_impl.dart';
import 'package:mindlog/data/repositories/statistics_repository_impl.dart';
import 'package:mindlog/domain/repositories/diary_repository.dart';
import 'package:mindlog/domain/repositories/settings_repository.dart';
import 'package:mindlog/domain/repositories/statistics_repository.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/domain/usecases/get_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/get_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/get_statistics_usecase.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/set_selected_ai_character_usecase.dart';

/// 인프라 의존성 Provider 모음
/// - 데이터 소스, 리포지토리, 유스케이스를 구성합니다.

/// SQLite 로컬 데이터 소스 Provider
final sqliteLocalDataSourceProvider = Provider<SqliteLocalDataSource>((ref) {
  return SqliteLocalDataSource();
});

/// Preferences 로컬 데이터 소스 Provider
final preferencesLocalDataSourceProvider =
    Provider<PreferencesLocalDataSource>((ref) {
  return PreferencesLocalDataSource();
});

/// 서킷 브레이커 Provider
final circuitBreakerProvider = Provider<CircuitBreaker>((ref) {
  return CircuitBreaker(
    config: const CircuitBreakerConfig(
      failureThreshold: 3,
      resetTimeout: Duration(minutes: 1),
    ),
  );
});

/// Groq 원격 데이터 소스 Provider
final groqRemoteDataSourceProvider = Provider<GroqRemoteDataSource>((ref) {
  final apiKey = EnvironmentService.groqApiKey;
  return GroqRemoteDataSource(
    apiKey,
    circuitBreaker: ref.watch(circuitBreakerProvider),
  );
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

/// StatisticsRepository Provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),
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

/// GetNotificationSettingsUseCase Provider
final getNotificationSettingsUseCaseProvider =
    Provider<GetNotificationSettingsUseCase>((ref) {
  return GetNotificationSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

/// SetNotificationSettingsUseCase Provider
final setNotificationSettingsUseCaseProvider =
    Provider<SetNotificationSettingsUseCase>((ref) {
  return SetNotificationSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

/// GetStatisticsUseCase Provider
final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  return GetStatisticsUseCase(ref.watch(statisticsRepositoryProvider));
});

/// DB 복원 후 Provider 캐시 무효화
///
/// DB 복원이 감지되면 모든 데이터 관련 Provider를 무효화하여
/// 새로운 DB 데이터를 반영합니다.
void invalidateDataProviders(ProviderContainer container) {
  // 데이터 소스 Provider 무효화 → 의존하는 모든 Provider 자동 갱신
  container.invalidate(sqliteLocalDataSourceProvider);
}
