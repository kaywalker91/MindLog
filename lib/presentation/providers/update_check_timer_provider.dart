import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_info_provider.dart';
import 'update_state_provider.dart';

/// 주기적 업데이트 체크 간격 (6시간)
const Duration _updateCheckInterval = Duration(hours: 6);

/// 주기적 업데이트 체크 타이머 관리
///
/// - 앱 foreground 상태에서 6시간마다 자동 체크
/// - MainScreen에서 초기화하여 앱 사용 중에만 동작
/// - autoDispose로 앱 종료 시 자동 정리
final updateCheckTimerProvider = Provider.autoDispose<UpdateCheckTimer>((ref) {
  final timer = UpdateCheckTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});

class UpdateCheckTimer {
  final Ref _ref;
  Timer? _timer;
  bool _isDisposed = false;

  UpdateCheckTimer(this._ref);

  /// 주기적 체크 타이머 시작
  void start() {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer.periodic(_updateCheckInterval, (_) => _performCheck());

    if (kDebugMode) {
      debugPrint(
        '[UpdateCheckTimer] Started with interval: $_updateCheckInterval',
      );
    }
  }

  /// 타이머 중지
  void stop() {
    _timer?.cancel();
    _timer = null;

    if (kDebugMode) {
      debugPrint('[UpdateCheckTimer] Stopped');
    }
  }

  /// 리소스 정리
  void dispose() {
    _isDisposed = true;
    stop();
  }

  Future<void> _performCheck() async {
    if (_isDisposed) return;

    try {
      final appInfo = await _ref.read(appInfoProvider.future);
      await _ref.read(updateStateProvider.notifier).check(appInfo.version);

      if (kDebugMode) {
        debugPrint(
          '[UpdateCheckTimer] Periodic check completed for v${appInfo.version}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateCheckTimer] Periodic check failed: $e');
      }
    }
  }
}
