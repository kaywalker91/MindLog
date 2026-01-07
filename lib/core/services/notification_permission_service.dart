import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationPermissionService {
  NotificationPermissionService._();

  static const String _promptedKey = 'notification_permission_prompted';
  static const String _exactAlarmPromptedKey = 'exact_alarm_permission_prompted';

  /// MethodChannel for native Android battery optimization check
  static const MethodChannel _channel =
      MethodChannel('com.mindlog.mindlog/battery_optimization');

  static Future<bool> shouldPromptAndroidPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) {
      return false;
    }

    final enabled = await NotificationService.areNotificationsEnabled();
    return enabled == false;
  }

  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }

  static Future<bool?> requestAndroidPermission() {
    return NotificationService.requestAndroidPermission();
  }

  /// Android 12+ 정확한 알람 권한 확인
  ///
  /// Android 12(API 31) 이상에서 SCHEDULE_EXACT_ALARM 권한이 필요합니다.
  /// 이 권한이 없으면 알람이 지연되거나 무시될 수 있습니다.
  ///
  /// **중요:** null 반환 시 false로 처리하여 권한 요청을 유도합니다.
  /// 이전에는 null ?? true로 처리하여 권한 체크가 우회되는 버그가 있었습니다.
  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final result = await NotificationService.canScheduleExactAlarms();
      // null이면 false로 처리하여 권한 요청 유도 (이전: ?? true → 버그)
      final canSchedule = result ?? false;

      if (kDebugMode) {
        debugPrint('[Permission] canScheduleExactAlarms: $canSchedule (raw: $result)');
      }

      return canSchedule;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Permission] Error checking exact alarm permission: $e');
      }
      // 에러 시 false 반환하여 권한 요청 유도
      return false;
    }
  }

  /// 정확한 알람 권한 프롬프트가 필요한지 확인
  ///
  /// Android 12+ 기기에서 정확한 알람 권한이 없을 때 true 반환
  static Future<bool> shouldPromptExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    // 이미 권한이 있으면 프롬프트 불필요
    final canSchedule = await canScheduleExactAlarms();
    if (canSchedule) {
      return false;
    }

    // 이미 프롬프트한 적이 있는지 확인 (선택적 - 매번 안내해도 됨)
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_exactAlarmPromptedKey) ?? false);
  }

  /// 정확한 알람 권한 프롬프트 표시 완료 마킹
  static Future<void> markExactAlarmPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_exactAlarmPromptedKey, true);
  }

  /// 정확한 알람 권한 요청 (시스템 설정 화면으로 이동)
  ///
  /// Android 12+ 기기에서 설정 앱의 "알람 및 리마인더" 화면으로 이동합니다.
  static Future<void> requestExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await NotificationService.requestExactAlarmPermission();
  }

  // ============ 배터리 최적화 관련 ============

  /// 배터리 최적화 무시 상태 확인
  ///
  /// 앱이 배터리 최적화에서 제외되어 있으면 true 반환.
  /// 배터리 최적화 대상이면 false 반환 (알람이 억제될 수 있음).
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');

      if (kDebugMode) {
        debugPrint('[Permission] Battery optimization ignored: $result');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Permission] Error checking battery optimization: $e');
      }
      // 에러 시 true 반환하여 다이얼로그를 불필요하게 표시하지 않음
      // (네이티브 채널 미구현 시에도 앱이 정상 작동하도록)
      return true;
    }
  }

  /// 배터리 최적화 비활성화 요청 (시스템 다이얼로그)
  ///
  /// Android 시스템 다이얼로그를 통해 배터리 최적화 제외를 요청합니다.
  /// 사용자가 "허용"을 선택하면 앱이 배터리 최적화에서 제외됩니다.
  static Future<bool> requestDisableBatteryOptimization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final result = await _channel
          .invokeMethod<bool>('requestDisableBatteryOptimization');

      if (kDebugMode) {
        debugPrint('[Permission] Battery optimization disable request: $result');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Permission] Error requesting battery optimization disable: $e');
      }
      return false;
    }
  }
}
