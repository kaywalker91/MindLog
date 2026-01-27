import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/update_service.dart';
import '../../domain/repositories/settings_repository.dart';
import 'package:mindlog/core/di/infra_providers.dart';
import 'update_provider.dart';

/// 앱 업그레이드 상태 모델
///
/// 앱 버전이 변경되었는지 추적하고, What's New 다이얼로그 표시 여부를 관리합니다.
class AppUpgradeState {
  /// 업그레이드가 감지되었는지 여부
  final bool isUpgradeDetected;

  /// 이전에 설치되어 있던 버전 (신규 설치 시 null)
  final String? previousVersion;

  /// 현재 앱 버전
  final String currentVersion;

  /// 현재 버전의 변경사항 목록
  final List<String> changelogNotes;

  /// What's New 다이얼로그가 이미 표시되었는지 여부
  final bool hasShownWhatsNew;

  const AppUpgradeState({
    this.isUpgradeDetected = false,
    this.previousVersion,
    required this.currentVersion,
    this.changelogNotes = const [],
    this.hasShownWhatsNew = false,
  });

  AppUpgradeState copyWith({
    bool? isUpgradeDetected,
    String? previousVersion,
    String? currentVersion,
    List<String>? changelogNotes,
    bool? hasShownWhatsNew,
  }) {
    return AppUpgradeState(
      isUpgradeDetected: isUpgradeDetected ?? this.isUpgradeDetected,
      previousVersion: previousVersion ?? this.previousVersion,
      currentVersion: currentVersion ?? this.currentVersion,
      changelogNotes: changelogNotes ?? this.changelogNotes,
      hasShownWhatsNew: hasShownWhatsNew ?? this.hasShownWhatsNew,
    );
  }
}

/// 앱 업그레이드 감지 및 What's New 다이얼로그 상태 관리
///
/// 앱 시작 시 이전 버전과 현재 버전을 비교하여 업그레이드 여부를 판단합니다.
/// - 신규 설치: 다이얼로그 표시 안 함 (previousVersion == null)
/// - 동일 버전: 다이얼로그 표시 안 함
/// - 업그레이드: changelog 가져와서 다이얼로그 표시, 버전 저장
class AppUpgradeCheckNotifier extends StateNotifier<AsyncValue<AppUpgradeState>> {
  final SettingsRepository _settingsRepository;
  final UpdateService _updateService;

  AppUpgradeCheckNotifier(this._settingsRepository, this._updateService)
      : super(const AsyncValue.loading());

  /// 앱 업그레이드 여부 확인
  ///
  /// [currentVersion]: 현재 앱 버전 (예: "1.4.16")
  Future<void> checkForUpgrade(String currentVersion) async {
    state = const AsyncValue.loading();

    try {
      final previousVersion = await _settingsRepository.getLastSeenAppVersion();

      // 신규 설치: previousVersion이 null
      if (previousVersion == null) {
        await _settingsRepository.setLastSeenAppVersion(currentVersion);
        state = AsyncValue.data(AppUpgradeState(
          isUpgradeDetected: false,
          currentVersion: currentVersion,
        ));
        if (kDebugMode) {
          debugPrint('[AppUpgradeCheck] Fresh install detected, version saved: $currentVersion');
        }
        return;
      }

      // 동일 버전: 업그레이드 아님
      if (previousVersion == currentVersion) {
        state = AsyncValue.data(AppUpgradeState(
          isUpgradeDetected: false,
          previousVersion: previousVersion,
          currentVersion: currentVersion,
        ));
        if (kDebugMode) {
          debugPrint('[AppUpgradeCheck] Same version: $currentVersion');
        }
        return;
      }

      // 업그레이드 감지: changelog 가져오기
      if (kDebugMode) {
        debugPrint('[AppUpgradeCheck] Upgrade detected: $previousVersion -> $currentVersion');
      }

      List<String> notes = [];
      try {
        final config = await _updateService.fetchConfig();
        notes = config.changelog[currentVersion] ?? [];
        if (kDebugMode) {
          debugPrint('[AppUpgradeCheck] Changelog loaded: ${notes.length} items');
        }
      } catch (e) {
        // changelog 가져오기 실패해도 다이얼로그는 표시
        if (kDebugMode) {
          debugPrint('[AppUpgradeCheck] Failed to fetch changelog: $e');
        }
      }

      state = AsyncValue.data(AppUpgradeState(
        isUpgradeDetected: true,
        previousVersion: previousVersion,
        currentVersion: currentVersion,
        changelogNotes: notes,
      ));
    } catch (e, st) {
      // 에러 발생 시 버전 저장하고 다이얼로그 스킵
      if (kDebugMode) {
        debugPrint('[AppUpgradeCheck] Error during upgrade check: $e');
      }
      await _settingsRepository.setLastSeenAppVersion(currentVersion);
      state = AsyncValue.error(e, st);
    }
  }

  /// What's New 다이얼로그 표시 완료 처리
  ///
  /// 다이얼로그를 닫은 후 호출하여 현재 버전을 저장하고 상태를 업데이트합니다.
  Future<void> markWhatsNewShown() async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _settingsRepository.setLastSeenAppVersion(current.currentVersion);
    state = AsyncValue.data(current.copyWith(hasShownWhatsNew: true));

    if (kDebugMode) {
      debugPrint('[AppUpgradeCheck] What\'s New shown, version saved: ${current.currentVersion}');
    }
  }
}

/// 앱 업그레이드 확인 Provider
final appUpgradeCheckProvider =
    StateNotifierProvider<AppUpgradeCheckNotifier, AsyncValue<AppUpgradeState>>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  final service = ref.watch(updateServiceProvider);
  return AppUpgradeCheckNotifier(settingsRepository, service);
});
