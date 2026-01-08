import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics 서비스
class CrashlyticsService {
  CrashlyticsService._();

  static FirebaseCrashlytics? _crashlytics;

  /// 초기화
  static Future<void> initialize() async {
    _crashlytics ??= FirebaseCrashlytics.instance;
    await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  /// 에러 기록
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[Crashlytics] Recording error: $exception');
    }

    try {
      final crashlytics = _crashlytics ?? FirebaseCrashlytics.instance;
      await crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Crashlytics] Failed to record error: $error');
      }
    }
  }
}
