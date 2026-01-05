import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/environment_service.dart';
import 'core/errors/error_boundary.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/splash_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  // 에러 바운더리로 앱 실행
  ErrorBoundary.runAppWithErrorHandling(
    onEnsureInitialized: () async {
      // 환경 변수 초기화 (dart-define only)
      await EnvironmentService.initialize();

      // 한국어 날짜 포맷 초기화
      await initializeDateFormatting('ko_KR', null);
    },
    appBuilder: () => const ProviderScope(
      child: MindLogApp(),
    ),
    onError: (error, stack) {
      // TODO: Crashlytics 등 외부 서비스로 에러 전송
      // FirebaseCrashlytics.instance.recordError(error, stack);
    },
  );
}



class MindLogApp extends ConsumerWidget {
  const MindLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // 로컬라이제이션 설정
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      
      home: const SplashScreen(),
      builder: (context, child) {
        return child!;
      },
    );
  }
}
