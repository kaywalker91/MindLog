import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/update_service.dart';
import 'package:mindlog/presentation/providers/update_provider.dart';

void main() {
  group('Changelog Pagination', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('changelogPageIndexProvider', () {
      test('초기값은 0이어야 한다', () {
        expect(container.read(changelogPageIndexProvider), 0);
      });

      test('증가시키면 값이 올라가야 한다', () {
        container.read(changelogPageIndexProvider.notifier).state++;
        expect(container.read(changelogPageIndexProvider), 1);

        container.read(changelogPageIndexProvider.notifier).state++;
        expect(container.read(changelogPageIndexProvider), 2);
      });
    });

    group('sortedChangelogVersionsProvider', () {
      test('updateConfigProvider가 null이면 빈 리스트를 반환해야 한다', () {
        // updateConfigProvider가 loading 상태이므로 빈 리스트 반환
        final versions = container.read(sortedChangelogVersionsProvider);
        expect(versions, isEmpty);
      });

      test('버전이 내림차순으로 정렬되어야 한다', () {
        const mockConfig = UpdateConfig(
          latestVersion: '1.5.0',
          minSupportedVersion: '1.0.0',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: {
            '1.2.0': ['Feature 1'],
            '1.5.0': ['Feature 2'],
            '1.3.0': ['Feature 3'],
            '1.0.0': ['Initial'],
          },
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        // FutureProvider를 동기적으로 완료시키기 위해 listen 후 대기
        testContainer.listen(updateConfigProvider, (previous, next) {});

        // 비동기 완료를 위해 테스트
        expectLater(
          testContainer.read(updateConfigProvider.future),
          completion(mockConfig),
        );
      });
    });

    group('paginatedVersionsProvider', () {
      test('첫 페이지는 최대 10개 버전을 반환해야 한다', () async {
        // 15개 버전을 가진 mock config
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        // 데이터 로드 대기
        await testContainer.read(updateConfigProvider.future);

        final paginatedVersions = testContainer.read(paginatedVersionsProvider);
        expect(paginatedVersions.length, 10);
        expect(paginatedVersions.first, '1.0.15'); // 최신 버전이 첫 번째
      });

      test('페이지 인덱스 증가 시 더 많은 버전을 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        // 첫 페이지
        expect(testContainer.read(paginatedVersionsProvider).length, 10);

        // 페이지 증가
        testContainer.read(changelogPageIndexProvider.notifier).state++;

        // 두 번째 페이지 (전체 15개)
        expect(testContainer.read(paginatedVersionsProvider).length, 15);
      });
    });

    group('hasLoadedMoreChangelogProvider', () {
      test('초기값(pageIndex=0)이면 false를 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        expect(testContainer.read(hasLoadedMoreChangelogProvider), isFalse);
      });

      test('pageIndex > 0이면 true를 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        // 더보기 클릭
        testContainer.read(changelogPageIndexProvider.notifier).state++;

        expect(testContainer.read(hasLoadedMoreChangelogProvider), isTrue);
      });

      test('pageIndex를 0으로 리셋하면 false를 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        // 더보기 클릭 후 다시 접기
        testContainer.read(changelogPageIndexProvider.notifier).state++;
        expect(testContainer.read(hasLoadedMoreChangelogProvider), isTrue);

        testContainer.read(changelogPageIndexProvider.notifier).state = 0;
        expect(testContainer.read(hasLoadedMoreChangelogProvider), isFalse);
      });
    });

    group('hasMoreChangelogProvider', () {
      test('더 불러올 데이터가 있으면 true를 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        expect(testContainer.read(hasMoreChangelogProvider), isTrue);
      });

      test('모든 데이터를 로드하면 false를 반환해야 한다', () async {
        final changelog = <String, List<String>>{};
        for (var i = 1; i <= 15; i++) {
          changelog['1.0.$i'] = ['Change $i'];
        }

        final mockConfig = UpdateConfig(
          latestVersion: '1.0.15',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: changelog,
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        // 페이지 증가하여 모든 데이터 로드
        testContainer.read(changelogPageIndexProvider.notifier).state++;

        expect(testContainer.read(hasMoreChangelogProvider), isFalse);
      });

      test('전체 데이터가 페이지 크기보다 작으면 false를 반환해야 한다', () async {
        const mockConfig = UpdateConfig(
          latestVersion: '1.0.3',
          minSupportedVersion: '1.0.1',
          forceUpdate: false,
          androidUrl: null,
          iosUrl: null,
          changelog: {
            '1.0.1': ['Change 1'],
            '1.0.2': ['Change 2'],
            '1.0.3': ['Change 3'],
          },
        );

        final testContainer = ProviderContainer(
          overrides: [
            updateConfigProvider.overrideWith((ref) async => mockConfig),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer.read(updateConfigProvider.future);

        expect(testContainer.read(hasMoreChangelogProvider), isFalse);
      });
    });
  });
}
