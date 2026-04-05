import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/environment_service.dart';
import 'core/observability/app_provider_observer.dart';
import 'core/services/app_logger.dart';
import 'core/constants/app_constants.dart';
import 'core/errors/error_boundary.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/db_recovery_service.dart';
import 'core/services/notification_settings_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/di/infra_providers.dart';
import 'presentation/providers/statistics_providers.dart';
import 'presentation/providers/diary_list_controller.dart';
import 'presentation/providers/self_encouragement_controller.dart';
import 'presentation/providers/today_emotion_provider.dart';
import 'presentation/providers/user_name_controller.dart';
import 'presentation/providers/notification_settings_controller.dart';
import 'presentation/services/notification_action_handler.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/app_info_provider.dart';
import 'presentation/providers/update_state_provider.dart';

final ProviderContainer appContainer = ProviderContainer(
  observers: [
    if (kDebugMode) AppProviderObserver(),
    TalkerRiverpodObserver(talker: appLogger),
  ],
);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 앱 시작 시 알림 재스케줄링
///
/// Android에서 기기 재부팅 시 모든 예약된 알람이 삭제됩니다.
/// 이 함수는 앱 시작 시 저장된 전체 알림 설정을 읽고,
/// Cheer Me 7일 큐가 비어 있거나 구버전 payload/서명 불일치가 있으면
/// 큐 전체를 다시 생성합니다.
Future<void> _rescheduleNotificationsIfNeeded() async {
  try {
    final settings = await appContainer.read(
      notificationSettingsProvider.future,
    );

    if (!settings.isReminderEnabled) {
      if (kDebugMode) {
        debugPrint('[Main] Reminder is disabled, skipping reschedule');
      }
      return;
    }

    final messages = await appContainer.read(selfEncouragementProvider.future);
    if (messages.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Main] No Cheer Me messages found, skipping reschedule');
      }
      return;
    }

    final userName = await appContainer.read(userNameProvider.future);
    final pendingNotifications =
        await NotificationService.getPendingNotifications();

    if (kDebugMode) {
      debugPrint(
        '[Main] App start reschedule — pending: ${pendingNotifications.length}',
      );
      for (final notification in pendingNotifications) {
        debugPrint(
          '[Main]   • ID: ${notification.id}, Title: ${notification.title}',
        );
      }
    }

    final requiresRebuild =
        NotificationSettingsService.requiresCheerMeQueueRebuild(
          settings,
          messages: messages,
          pendingNotifications: pendingNotifications,
          userName: userName,
        );

    if (!requiresRebuild) {
      if (kDebugMode) {
        debugPrint(
          '[Main] Cheer Me queue is already current, skipping rebuild',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[Main] Cheer Me queue missing or stale. Rebuilding for ${settings.reminderHour}:${settings.reminderMinute.toString().padLeft(2, '0')}',
      );
    }

    try {
      await appContainer.read(diaryListControllerProvider.future);
    } catch (_) {
      // Emotion-aware fallback is handled below with a nullable score.
    }

    final recentEmotionScore = appContainer
        .read(todayEmotionProvider)
        .sentimentScore
        ?.toDouble();

    await NotificationSettingsService.applySettings(
      settings,
      messages: messages,
      source: 'app_start',
      userName: userName,
      recentEmotionScore: recentEmotionScore,
    );

    if (kDebugMode) {
      debugPrint('[Main] Notification rescheduled successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Failed to reschedule notifications: $e');
    }
  }
}

/// DB 복원 후 핵심 Provider warm-up
///
/// UI 렌더링 전 데이터 로딩을 보장하여 통계 화면이 빈 상태로 표시되는 문제 방지.
/// IndexedStack에서 모든 탭이 동시에 빌드되므로, 데이터가 준비되지 않으면
/// 빈 화면이 표시될 수 있음.
Future<void> _warmUpCriticalProviders(ProviderContainer container) async {
  try {
    await Future.wait<void>([
      container.read(statisticsProvider.future).then((_) {}),
      container.read(diaryListControllerProvider.future).then((_) {}),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint('[Main] Provider warm-up timeout');
        }
        return <void>[];
      },
    );
    if (kDebugMode) {
      debugPrint('[Main] Critical providers warmed up successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Provider warm-up failed: $e');
    }
  }
}

Future<void> _initializeApp() async {
  // 환경 변수 초기화 (dart-define only)
  await EnvironmentService.initialize();

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // Critical services (must await)
  await FirebaseService.initialize();

  // DB 복원 감지 및 처리
  // 앱 재설치 시 OS가 복원한 DB 파일을 정확히 읽도록 함
  final dataSource = appContainer.read(sqliteLocalDataSourceProvider);
  final wasRecovered = await DbRecoveryService.checkAndRecoverIfNeeded(
    dataSource,
  );
  if (wasRecovered) {
    // 1. Core layer Provider 무효화 (DataSource, Repository, UseCase)
    invalidateDataProviders(appContainer);

    // 2. Presentation layer Provider 무효화 (복원된 DB 데이터 재로드)
    // topKeywordsProvider는 statisticsProvider의 파생이므로 자동 갱신
    appContainer.invalidate(statisticsProvider);
    appContainer.invalidate(diaryListControllerProvider);

    // 3. 핵심 Provider warm-up (데이터 로딩 보장)
    // UI 렌더링 전에 데이터가 준비되도록 함
    await _warmUpCriticalProviders(appContainer);

    if (kDebugMode) {
      debugPrint('[Main] DB recovery completed, providers warmed up');
    }
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  NotificationActionHandler.configure(
    navigatorKey: rootNavigatorKey,
    container: appContainer,
  );
  await NotificationService.initialize(
    onNotificationResponse: NotificationActionHandler.handlePayload,
  );

  // Non-critical services (unawaited to avoid blocking app startup)
  unawaited(
    FCMService.initialize(
      onMessageOpened: NotificationActionHandler.handleRemoteData,
    ),
  );

  // 앱 시작 시 알림 재스케줄링
  // 기기 재부팅, 앱 업데이트, 시스템 알람 취소 등의 경우에 알람을 복원합니다.
  unawaited(_rescheduleNotificationsIfNeeded());

  // 백그라운드 업데이트 체크 (2초 지연, non-blocking)
  // 메인 UI 렌더링 후 네트워크 호출, 실패 시 silent 처리
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      final appInfo = await appContainer.read(appInfoProvider.future);
      await appContainer
          .read(updateStateProvider.notifier)
          .check(appInfo.version);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Main] Background update check failed: $e');
      }
    }
  });
}

void main() {
  // 에러 바운더리로 앱 실행
  // MarionetteBinding.ensureInitialized()는 runZonedGuarded 내부(bindingInitializer)에서
  // 호출해야 zone mismatch를 방지할 수 있음
  ErrorBoundary.runAppWithErrorHandling(
    bindingInitializer: !kReleaseMode
        ? MarionetteBinding.ensureInitialized
        : null,
    onEnsureInitialized: () async {
      await Future.any([
        _initializeApp(),
        Future.delayed(const Duration(seconds: 15), () {
          if (kDebugMode) {
            debugPrint(
              '[Main] Initialization timeout - proceeding with partial init',
            );
          }
        }),
      ]);
    },
    appBuilder: () => UncontrolledProviderScope(
      container: appContainer,
      child: const MindLogApp(),
    ),
  );
}

class MindLogApp extends ConsumerWidget {
  const MindLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // 로컬라이제이션 설정
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // GoRouter 연결 (navigatorKey, observers는 GoRouter에서 관리)
      routerConfig: AppRouter.router,
    );
  }
}
