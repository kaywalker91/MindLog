import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../core/services/in_app_update_service.dart';

/// In-App Update 상태
enum InAppUpdateStatus {
  /// 초기 상태 또는 체크 전
  idle,

  /// 업데이트 가용 (Play Store에 새 버전 존재)
  available,

  /// 다운로드 중 (Flexible update)
  downloading,

  /// 다운로드 완료, 설치 대기 중
  downloaded,

  /// 체크/업데이트 실패
  failed,

  /// 업데이트 없음 (최신 버전)
  upToDate,
}

/// In-App Update 상태 모델
class InAppUpdateState {
  final InAppUpdateStatus status;
  final bool immediateAllowed;
  final bool flexibleAllowed;
  final String? errorMessage;

  const InAppUpdateState({
    this.status = InAppUpdateStatus.idle,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.errorMessage,
  });

  /// 업데이트 가용 여부
  bool get isUpdateAvailable => status == InAppUpdateStatus.available;

  /// 다운로드 완료 여부 (설치 가능)
  bool get isReadyToInstall => status == InAppUpdateStatus.downloaded;

  InAppUpdateState copyWith({
    InAppUpdateStatus? status,
    bool? immediateAllowed,
    bool? flexibleAllowed,
    String? errorMessage,
  }) {
    return InAppUpdateState(
      status: status ?? this.status,
      immediateAllowed: immediateAllowed ?? this.immediateAllowed,
      flexibleAllowed: flexibleAllowed ?? this.flexibleAllowed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// In-App Update 서비스 Provider
final inAppUpdateServiceProvider = Provider<InAppUpdateService>((ref) {
  return InAppUpdateService();
});

/// In-App Update 상태 Notifier
class InAppUpdateNotifier extends StateNotifier<InAppUpdateState> {
  final InAppUpdateService _service;

  InAppUpdateNotifier(this._service) : super(const InAppUpdateState());

  /// Play Store 업데이트 확인
  ///
  /// Android에서만 동작, iOS는 항상 upToDate 반환
  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) {
      state = state.copyWith(status: InAppUpdateStatus.upToDate);
      return;
    }

    try {
      final info = await _service.checkForUpdate();
      if (info == null) {
        state = state.copyWith(status: InAppUpdateStatus.failed);
        return;
      }

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        state = state.copyWith(
          status: InAppUpdateStatus.available,
          immediateAllowed: info.immediateUpdateAllowed,
          flexibleAllowed: info.flexibleUpdateAllowed,
        );
      } else {
        state = state.copyWith(status: InAppUpdateStatus.upToDate);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateNotifier] Check failed: $e');
      }
      state = state.copyWith(
        status: InAppUpdateStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// 즉시 업데이트 실행
  Future<bool> performImmediateUpdate() async {
    if (!state.immediateAllowed) return false;

    try {
      final result = await _service.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateNotifier] Immediate update failed: $e');
      }
      return false;
    }
  }

  /// 유연 업데이트 시작
  Future<bool> startFlexibleUpdate() async {
    if (!state.flexibleAllowed) return false;

    try {
      state = state.copyWith(status: InAppUpdateStatus.downloading);
      final result = await _service.startFlexibleUpdate();

      if (result == AppUpdateResult.success) {
        state = state.copyWith(status: InAppUpdateStatus.downloaded);
        return true;
      } else {
        state = state.copyWith(status: InAppUpdateStatus.available);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateNotifier] Flexible update failed: $e');
      }
      state = state.copyWith(status: InAppUpdateStatus.available);
      return false;
    }
  }

  /// 유연 업데이트 완료 (설치)
  Future<void> completeFlexibleUpdate() async {
    if (!state.isReadyToInstall) return;
    await _service.completeFlexibleUpdate();
  }

  /// 상태 초기화
  void reset() {
    state = const InAppUpdateState();
  }
}

/// In-App Update Provider
final inAppUpdateProvider =
    StateNotifierProvider<InAppUpdateNotifier, InAppUpdateState>((ref) {
      final service = ref.watch(inAppUpdateServiceProvider);
      return InAppUpdateNotifier(service);
    });
