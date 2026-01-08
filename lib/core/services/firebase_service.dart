import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';

/// Firebase 서비스 초기화 및 관리
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Firebase 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await CrashlyticsService.initialize();
    await AnalyticsService.initialize();

    if (const bool.fromEnvironment('CRASHLYTICS_SMOKE_TEST')) {
      await CrashlyticsService.recordError(
        StateError('Crashlytics smoke test'),
        StackTrace.current,
        reason: 'crashlytics_smoke_test',
      );
    }

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[FirebaseService] Firebase initialized successfully');
    }
  }

  static bool get isInitialized => _initialized;
}
