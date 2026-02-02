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
    ref.watch(diaryRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    validateUseCase: ref.watch(validateDiaryContentUseCaseProvider),
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
///
/// ref.watch()로 의존성 추적이 활성화되어 있어 sqliteLocalDataSourceProvider
/// 무효화 시 의존 Provider들이 자동으로 재생성됩니다.
/// 명시적 무효화는 타이밍 경합 조건에 대한 추가 안전장치로 유지합니다.
void invalidateDataProviders(ProviderContainer container) {
  // 1. 데이터 소스 Provider 무효화 (의존 Provider들 자동 갱신됨)
  container.invalidate(sqliteLocalDataSourceProvider);

  // 2. Repository Provider 무효화 (방어적 프로그래밍)
  container.invalidate(diaryRepositoryProvider);
  container.invalidate(statisticsRepositoryProvider);

  // 3. UseCase Provider 무효화 (statisticsProvider가 watch하는 대상)
  container.invalidate(getStatisticsUseCaseProvider);
  container.invalidate(analyzeDiaryUseCaseProvider);
}
