import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/repositories/diary_repository.dart';
import 'package:mindlog/domain/repositories/settings_repository.dart';
import 'package:mindlog/domain/repositories/statistics_repository.dart';
import 'package:mindlog/presentation/providers/providers.dart';

import '../mocks/mock_repositories.dart';

/// 테스트용 ProviderContainer 생성 헬퍼
///
/// [diaryRepository], [settingsRepository], [statisticsRepository]를 주입하여
/// 격리된 테스트 환경을 구성합니다.
ProviderContainer createTestContainer({
  DiaryRepository? diaryRepository,
  SettingsRepository? settingsRepository,
  StatisticsRepository? statisticsRepository,
  List<Override>? additionalOverrides,
}) {
  return ProviderContainer(
    overrides: [
      if (diaryRepository != null)
        diaryRepositoryProvider.overrideWithValue(diaryRepository),
      if (settingsRepository != null)
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      if (statisticsRepository != null)
        statisticsRepositoryProvider.overrideWithValue(statisticsRepository),
      ...?additionalOverrides,
    ],
  );
}

/// 기본 Mock Repository들이 주입된 테스트 컨테이너 생성
///
/// 테스트에서 빠르게 설정하고 싶을 때 사용합니다.
/// 반환된 record에서 container와 mock들에 접근할 수 있습니다.
({
  ProviderContainer container,
  MockDiaryRepository diaryRepository,
  MockSettingsRepository settingsRepository,
  MockStatisticsRepository statisticsRepository,
})
createTestContainerWithMocks({List<Override>? additionalOverrides}) {
  final diaryRepository = MockDiaryRepository();
  final settingsRepository = MockSettingsRepository();
  final statisticsRepository = MockStatisticsRepository();

  final container = ProviderContainer(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(diaryRepository),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      statisticsRepositoryProvider.overrideWithValue(statisticsRepository),
      ...?additionalOverrides,
    ],
  );

  return (
    container: container,
    diaryRepository: diaryRepository,
    settingsRepository: settingsRepository,
    statisticsRepository: statisticsRepository,
  );
}

/// ProviderContainer 확장 메서드
extension ProviderContainerTestExtensions on ProviderContainer {
  /// 비동기 작업이 완료될 때까지 대기
  ///
  /// Riverpod의 FutureProvider나 AsyncNotifier가 완료될 때까지
  /// 이벤트 루프를 실행합니다.
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }

  /// 여러 번의 pump를 수행
  ///
  /// 복잡한 비동기 체인에서 사용합니다.
  Future<void> pumpMany(int count) async {
    for (int i = 0; i < count; i++) {
      await pump();
    }
  }

  /// AsyncValue가 데이터를 가질 때까지 대기
  ///
  /// [timeout] 내에 완료되지 않으면 TimeoutException을 던집니다.
  Future<T> waitForData<T>(
    ProviderListenable<AsyncValue<T>> provider, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final value = read(provider);
      if (value.hasValue) {
        return value.value as T;
      }
      if (value.hasError) {
        throw value.error!;
      }
      await pump();
    }
    throw TimeoutException('Provider did not complete within $timeout');
  }
}

/// TimeoutException
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// 테스트 그룹 내에서 반복 사용되는 설정을 위한 Mixin
///
/// 사용 예:
/// ```dart
/// void main() {
///   late ProviderContainer container;
///   late MockDiaryRepository mockDiaryRepository;
///
///   setUp(() {
///     final setup = createTestContainerWithMocks();
///     container = setup.container;
///     mockDiaryRepository = setup.diaryRepository;
///   });
///
///   tearDown(() {
///     container.dispose();
///   });
///
///   // 테스트 작성...
/// }
/// ```
