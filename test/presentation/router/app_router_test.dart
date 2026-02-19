import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/presentation/router/app_router.dart';

void main() {
  group('AppRoutes', () {
    test('should have correct route paths', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.diaryNew, '/diary/new');
      expect(AppRoutes.diaryDetail, '/diary/:id');
      expect(AppRoutes.statistics, '/statistics');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.privacyPolicy, '/privacy-policy');
      expect(AppRoutes.changelog, '/changelog');
    });

    test('should have 10 route path constants defined', () {
      // 모든 라우트 경로 상수 확인 (diary는 상수로 정의되어 있지만 라우트로 미사용)
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.home,
        AppRoutes.diary,
        AppRoutes.diaryNew,
        AppRoutes.diaryDetail,
        AppRoutes.statistics,
        AppRoutes.settings,
        AppRoutes.privacyPolicy,
        AppRoutes.changelog,
      ];

      expect(routes.length, 10);
    });
  });

  group('AppRouter', () {
    test('router should be initialized', () {
      expect(AppRouter.router, isA<GoRouter>());
    });

    test('should have 13 routes defined', () {
      // 최상위 라우트 개수 확인 (비밀일기 3개 추가로 13개)
      final routes = AppRouter.router.configuration.routes;
      expect(routes.length, 13);
    });

    test('routes should contain GoRoute instances', () {
      final routes = AppRouter.router.configuration.routes;

      for (final route in routes) {
        expect(route, isA<GoRoute>());
      }
    });

    test('GoRoute paths should match AppRoutes constants', () {
      final routes = AppRouter.router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>().toList();

      // 각 GoRoute의 path 확인
      final paths = goRoutes.map((r) => r.path).toSet();

      expect(paths, contains(AppRoutes.splash));
      expect(paths, contains(AppRoutes.onboarding));
      expect(paths, contains(AppRoutes.home));
      expect(paths, contains(AppRoutes.diaryNew));
      expect(paths, contains(AppRoutes.diaryDetail));
      expect(paths, contains(AppRoutes.statistics));
      expect(paths, contains(AppRoutes.settings));
      expect(paths, contains(AppRoutes.selfEncouragement));
      expect(paths, contains(AppRoutes.privacyPolicy));
      expect(paths, contains(AppRoutes.changelog));
    });

    test('GoRoute names should be defined', () {
      final routes = AppRouter.router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>().toList();

      final names = goRoutes.map((r) => r.name).whereType<String>().toSet();

      expect(names, contains('splash'));
      expect(names, contains('onboarding'));
      expect(names, contains('home'));
      expect(names, contains('diaryNew'));
      expect(names, contains('diaryDetail'));
      expect(names, contains('statistics'));
      expect(names, contains('settings'));
      expect(names, contains('selfEncouragement'));
      expect(names, contains('privacyPolicy'));
      expect(names, contains('changelog'));
    });
  });
}
