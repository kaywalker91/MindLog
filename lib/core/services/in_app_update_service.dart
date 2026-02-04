import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Android Play Store In-App Update 서비스
///
/// - Android에서만 동작 (iOS는 App Store 정책상 불가)
/// - 즉시 업데이트(Immediate): 필수 업데이트 시 전체 화면 차단
/// - 유연 업데이트(Flexible): 백그라운드 다운로드 후 설치 유도
///
/// 참고: 실제 Play Store 배포 앱에서만 테스트 가능
/// 로컬/디버그 빌드에서는 항상 "업데이트 없음" 반환
class InAppUpdateService {
  /// Android Play Store 업데이트 가용성 확인
  ///
  /// iOS에서는 null 반환
  /// Android에서 Play Store 업데이트 정보 반환
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (kDebugMode) {
        debugPrint(
          '[InAppUpdateService] Update available: '
          'updateAvailability=${info.updateAvailability}, '
          'immediateAllowed=${info.immediateUpdateAllowed}, '
          'flexibleAllowed=${info.flexibleUpdateAllowed}',
        );
      }
      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Check failed: $e');
      }
      return null;
    }
  }

  /// 즉시 업데이트 수행 (전체 화면, 사용자 취소 불가)
  ///
  /// - 필수 업데이트 시 사용
  /// - 앱 사용 차단하고 업데이트 강제
  /// - iOS에서는 userDeniedUpdate 반환
  Future<AppUpdateResult> performImmediateUpdate() async {
    if (!Platform.isAndroid) {
      return AppUpdateResult.userDeniedUpdate;
    }

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Immediate update result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Immediate update failed: $e');
      }
      return AppUpdateResult.userDeniedUpdate;
    }
  }

  /// 유연 업데이트 시작 (백그라운드 다운로드)
  ///
  /// - 선택적 업데이트 시 사용
  /// - 백그라운드에서 다운로드, 앱 사용 지속 가능
  /// - 다운로드 완료 후 completeFlexibleUpdate() 호출 필요
  /// - iOS에서는 userDeniedUpdate 반환
  Future<AppUpdateResult> startFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      return AppUpdateResult.userDeniedUpdate;
    }

    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Flexible update started: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Flexible update failed: $e');
      }
      return AppUpdateResult.userDeniedUpdate;
    }
  }

  /// 유연 업데이트 완료 (다운로드 완료 후 설치)
  ///
  /// - startFlexibleUpdate()로 다운로드 완료 후 호출
  /// - 앱 재시작하여 업데이트 적용
  /// - iOS에서는 no-op
  Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await InAppUpdate.completeFlexibleUpdate();
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Flexible update completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] Complete flexible update failed: $e');
      }
    }
  }
}
