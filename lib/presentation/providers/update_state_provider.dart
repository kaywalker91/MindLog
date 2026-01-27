import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/update_service.dart';
import '../../domain/repositories/settings_repository.dart';
import 'package:mindlog/core/di/infra_providers.dart';
import 'update_provider.dart';

/// 업데이트 상태 모델
class UpdateState {
  final UpdateCheckResult? result;
  final String? dismissedVersion;
  final bool isLoading;

  const UpdateState({
    this.result,
    this.dismissedVersion,
    this.isLoading = false,
  });

  /// 뱃지 표시 여부: 업데이트 가능 + dismiss된 버전이 아닐 때
  bool get shouldShowBadge {
    if (result == null) return false;
    if (result!.availability == UpdateAvailability.upToDate) return false;
    return result!.latestVersion != dismissedVersion;
  }

  bool get hasUpdate =>
      result?.availability == UpdateAvailability.updateAvailable ||
      result?.availability == UpdateAvailability.updateRequired;

  UpdateState copyWith({
    UpdateCheckResult? result,
    String? dismissedVersion,
    bool? isLoading,
    bool clearDismissed = false,
  }) {
    return UpdateState(
      result: result ?? this.result,
      dismissedVersion:
          clearDismissed ? null : (dismissedVersion ?? this.dismissedVersion),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 업데이트 상태 관리 Notifier
class UpdateStateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _service;
  final SettingsRepository _settingsRepository;

  UpdateStateNotifier(this._service, this._settingsRepository)
      : super(const UpdateState()) {
    _loadDismissedVersion();
  }

  Future<void> _loadDismissedVersion() async {
    final dismissed = await _settingsRepository.getDismissedUpdateVersion();
    if (mounted) {
      state = state.copyWith(dismissedVersion: dismissed);
    }
  }

  /// 업데이트 확인 (non-blocking)
  Future<void> check(String currentVersion) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final result =
          await _service.checkForUpdate(currentVersion: currentVersion);
      if (mounted) {
        state = state.copyWith(result: result, isLoading: false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateStateNotifier] Check failed: $e');
      }
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// 현재 버전 업데이트 dismiss
  Future<void> dismiss() async {
    final version = state.result?.latestVersion;
    if (version == null) return;

    await _settingsRepository.setDismissedUpdateVersion(version);
    state = state.copyWith(dismissedVersion: version);
  }

  /// dismiss 상태 초기화 (수동 업데이트 확인 시)
  Future<void> clearDismissal() async {
    await _settingsRepository.clearDismissedUpdateVersion();
    state = state.copyWith(clearDismissed: true);
  }
}

/// 업데이트 상태 Provider
final updateStateProvider =
    StateNotifierProvider<UpdateStateNotifier, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return UpdateStateNotifier(service, settingsRepository);
});
