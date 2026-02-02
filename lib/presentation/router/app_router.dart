import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/core/services/analytics_service.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/main.dart' show rootNavigatorKey;
import 'package:mindlog/presentation/screens/changelog_screen.dart';
import 'package:mindlog/presentation/screens/diary_detail_screen.dart';
import 'package:mindlog/presentation/screens/diary_screen.dart';
import 'package:mindlog/presentation/screens/main_screen.dart';
import 'package:mindlog/presentation/screens/privacy_policy_screen.dart';
import 'package:mindlog/presentation/screens/settings_screen.dart';
import 'package:mindlog/presentation/screens/splash_screen.dart';
import 'package:mindlog/presentation/screens/statistics_screen.dart';

/// 앱 라우트 정의
class AppRoutes {
  AppRoutes._();

  // 라우트 경로 상수
  static const String splash = '/';
  static const String home = '/home';
  static const String diary = '/diary';
  static const String diaryNew = '/diary/new';
  static const String diaryDetail = '/diary/:id';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String changelog = '/changelog';
}

/// AppRouter 설정
/// 
/// go_router를 사용한 선언적 라우팅 시스템
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    observers: [
      if (AnalyticsService.observer != null) AnalyticsService.observer!,
    ],

    // 에러 페이지
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
    
    routes: [
      // 스플래시 화면
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // 홈 (메인 화면 - 일기 목록 + 통계 + 설정)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      
      // 새 일기 작성
      GoRoute(
        path: AppRoutes.diaryNew,
        name: 'diaryNew',
        builder: (context, state) => const DiaryScreen(),
      ),
      
      // 일기 상세 보기
      GoRoute(
        path: AppRoutes.diaryDetail,
        name: 'diaryDetail',
        builder: (context, state) {
          // extra로 전달된 Diary 객체 사용
          final diary = state.extra as Diary?;
          if (diary == null) {
            // ID로 찾아야 하는 경우 (딥링크 등)
            return _ErrorPage(
              error: GoException('일기를 찾을 수 없습니다.'),
            );
          }
          return DiaryDetailScreen(diary: diary);
        },
      ),
      
      // 통계 화면
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      
      // 설정 화면
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // 개인정보 처리방침
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      
      // 변경사항
      GoRoute(
        path: AppRoutes.changelog,
        name: 'changelog',
        builder: (context, state) {
          final version = state.uri.queryParameters['version'] ?? '';
          final buildNumber = state.uri.queryParameters['build'];
          return ChangelogScreen(
            version: version,
            buildNumber: buildNumber,
          );
        },
      ),
    ],
  );
}

/// 라우팅 에러 페이지
class _ErrorPage extends StatelessWidget {
  final GoException? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('페이지를 찾을 수 없습니다'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '요청하신 페이지를 찾을 수 없습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error?.message ?? '알 수 없는 오류가 발생했습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 라우팅 헬퍼 확장 메서드
extension AppRouterExtension on BuildContext {
  /// 홈 화면으로 이동
  void goHome() => go(AppRoutes.home);

  /// 새 일기 작성 화면으로 이동
  void goNewDiary() => push(AppRoutes.diaryNew);

  /// 일기 상세 화면으로 이동
  void goDiaryDetail(Diary diary) => push(
        AppRoutes.diaryDetail.replaceFirst(':id', diary.id.toString()),
        extra: diary,
      );

  /// 통계 화면으로 이동 (push - 뒤로가기 지원)
  void pushStatistics() => push(AppRoutes.statistics);

  /// 설정 화면으로 이동 (push - 뒤로가기 지원)
  void pushSettings() => push(AppRoutes.settings);

  /// 개인정보 처리방침으로 이동 (push - 뒤로가기 지원)
  void pushPrivacyPolicy() => push(AppRoutes.privacyPolicy);

  /// 변경사항 화면으로 이동 (push - 뒤로가기 지원)
  void pushChangelog({required String version, String? buildNumber}) {
    final query = buildNumber != null
        ? '?version=$version&build=$buildNumber'
        : '?version=$version';
    push('${AppRoutes.changelog}$query');
  }
}
