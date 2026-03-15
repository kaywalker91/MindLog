import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

/// 앱 전역 구조화 로거
///
/// 디버그 모드: 콘솔에 색상 로그 출력
/// 프로덕션: error/critical → Crashlytics non-fatal 기록
///
/// 사용법:
/// ```dart
/// appLogger.debug('메시지');
/// appLogger.info('메시지');
/// appLogger.warning('메시지');
/// appLogger.error('메시지', exception, stackTrace);
/// ```
final Talker appLogger = Talker(
  settings: TalkerSettings(useConsoleLogs: kDebugMode),
  observer: kDebugMode ? null : _CrashlyticsObserver(),
);

/// Crashlytics 연동 옵저버
///
/// error/critical 레벨을 Crashlytics에 non-fatal로 기록
class _CrashlyticsObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    FirebaseCrashlytics.instance.recordError(
      err.error,
      err.stackTrace,
      reason: err.message,
      fatal: false,
    );
  }

  @override
  void onException(TalkerException err) {
    FirebaseCrashlytics.instance.recordError(
      err.exception,
      err.stackTrace,
      reason: err.message,
      fatal: false,
    );
  }
}
