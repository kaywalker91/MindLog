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
import 'package:mindlog/domain/usecases/validate_diary_content_usecase.dart';

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
    circuitBreaker: ref.read(circuitBreakerProvider),
  );
});

/// DiaryRepository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    localDataSource: ref.read(sqliteLocalDataSourceProvider),
    remoteDataSource: ref.read(groqRemoteDataSourceProvider),
  );
});

/// SettingsRepository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.read(preferencesLocalDataSourceProvider),
  );
});

/// StatisticsRepository Provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.read(sqliteLocalDataSourceProvider),
  );
});

/// ValidateDiaryContentUseCase Provider
///
/// 일기 내용 유효성 검사 전용 UseCase
/// - UI에서 실시간 유효성 피드백에 활용
/// - AnalyzeDiaryUseCase 내부에서도 사용
final validateDiaryContentUseCaseProvider =
    Provider<ValidateDiaryContentUseCase>((ref) {
  return ValidateDiaryContentUseCase();
});

/// AnalyzeDiaryUseCase Provider
final analyzeDiaryUseCaseProvider = Provider<AnalyzeDiaryUseCase>((ref) {
  return AnalyzeDiaryUseCase(
    ref.read(diaryRepositoryProvider),
    ref.read(settingsRepositoryProvider),
    validateUseCase: ref.read(validateDiaryContentUseCaseProvider),
  );
});

/// GetSelectedAiCharacterUseCase Provider
final getSelectedAiCharacterUseCaseProvider =
    Provider<GetSelectedAiCharacterUseCase>((ref) {
  return GetSelectedAiCharacterUseCase(ref.read(settingsRepositoryProvider));
});

/// SetSelectedAiCharacterUseCase Provider
final setSelectedAiCharacterUseCaseProvider =
    Provider<SetSelectedAiCharacterUseCase>((ref) {
  return SetSelectedAiCharacterUseCase(ref.read(settingsRepositoryProvider));
});

/// GetNotificationSettingsUseCase Provider
final getNotificationSettingsUseCaseProvider =
    Provider<GetNotificationSettingsUseCase>((ref) {
  return GetNotificationSettingsUseCase(ref.read(settingsRepositoryProvider));
});

/// SetNotificationSettingsUseCase Provider
final setNotificationSettingsUseCaseProvider =
    Provider<SetNotificationSettingsUseCase>((ref) {
  return SetNotificationSettingsUseCase(ref.read(settingsRepositoryProvider));
});

/// GetStatisticsUseCase Provider
final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  return GetStatisticsUseCase(ref.read(statisticsRepositoryProvider));
});

/// DB 복원 후 Provider 캐시 무효화
///
/// DB 복원이 감지되면 모든 데이터 관련 Provider를 무효화하여
/// 새로운 DB 데이터를 반영합니다.
///
/// 주의: Repository Provider들이 ref.read()를 사용하여 SqliteLocalDataSource를
/// 의존하고 있어 의존성 추적이 되지 않습니다. 따라서 데이터 소스뿐만 아니라
/// 모든 관련 Provider를 명시적으로 무효화해야 합니다.
void invalidateDataProviders(ProviderContainer container) {
  // 1. 데이터 소스 Provider 무효화
  container.invalidate(sqliteLocalDataSourceProvider);

  // 2. Repository Provider 무효화 (ref.read()로 인한 의존성 미추적 보완)
  container.invalidate(diaryRepositoryProvider);
  container.invalidate(statisticsRepositoryProvider);

  // 3. UseCase Provider 무효화 (statisticsProvider가 watch하는 대상)
  container.invalidate(getStatisticsUseCaseProvider);
  container.invalidate(analyzeDiaryUseCaseProvider);
}
