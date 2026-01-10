import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

enum UpdateAvailability { upToDate, updateAvailable, updateRequired }

class UpdateConfig {
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String? androidUrl;
  final String? iosUrl;
  final Map<String, List<String>> changelog;

  const UpdateConfig({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.androidUrl,
    required this.iosUrl,
    required this.changelog,
  });

  factory UpdateConfig.fromJson(Map<String, dynamic> json) {
    final latestRaw = json['latestVersion'];
    if (latestRaw is! String || latestRaw.trim().isEmpty) {
      throw const FormatException('latestVersion is missing');
    }
    final latestVersion = latestRaw.trim();

    final minRaw = json['minSupportedVersion'];
    final minSupportedVersion =
        (minRaw is String && minRaw.trim().isNotEmpty) ? minRaw.trim() : latestVersion;

    final androidRaw = json['androidUrl'];
    final androidUrl =
        (androidRaw is String && androidRaw.trim().isNotEmpty) ? androidRaw.trim() : null;

    final iosRaw = json['iosUrl'];
    final iosUrl = (iosRaw is String && iosRaw.trim().isNotEmpty) ? iosRaw.trim() : null;

    final changelog = <String, List<String>>{};
    final changelogRaw = json['changelog'];
    if (changelogRaw is Map) {
      for (final entry in changelogRaw.entries) {
        final version = entry.key.toString().trim();
        final itemsRaw = entry.value;
        if (version.isEmpty || itemsRaw is! List) continue;
        final items = itemsRaw
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          changelog[version] = items;
        }
      }
    }

    return UpdateConfig(
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      forceUpdate: json['forceUpdate'] == true,
      androidUrl: androidUrl,
      iosUrl: iosUrl,
      changelog: changelog,
    );
  }

  String? storeUrlFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
        return iosUrl ?? androidUrl;
      case TargetPlatform.android:
        return androidUrl ?? iosUrl;
      default:
        return androidUrl ?? iosUrl;
    }
  }

  List<String> notesFor(String version) => changelog[version] ?? const [];
}

class UpdateCheckResult {
  final UpdateAvailability availability;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String? storeUrl;
  final List<String> notes;

  const UpdateCheckResult({
    required this.availability,
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.storeUrl,
    required this.notes,
  });

  bool get isRequired => availability == UpdateAvailability.updateRequired;
}

class UpdateService {
  const UpdateService();

  Future<UpdateConfig> fetchConfig({http.Client? client}) async {
    final url = AppConstants.updateConfigUrl.trim();
    if (url.isEmpty) {
      throw Exception('Update config URL is not set');
    }

    final uri = Uri.parse(url);
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load update config: ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Update config JSON is invalid');
      }
      return UpdateConfig.fromJson(decoded);
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// 업데이트 확인
  ///
  /// 원격 설정을 가져와 현재 버전과 비교합니다.
  /// 네트워크 오류 발생 시 "최신 상태"로 Fallback 처리합니다.
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
    TargetPlatform? platform,
    http.Client? client,
  }) async {
    try {
      final config = await fetchConfig(client: client);
      return evaluate(
        currentVersion: currentVersion,
        config: config,
        platform: platform,
      );
    } catch (e) {
      // 네트워크 오류 시 Fallback: 현재 버전을 최신으로 간주
      if (kDebugMode) {
        debugPrint('[UpdateService] Failed to fetch config: $e');
      }
      return UpdateCheckResult(
        availability: UpdateAvailability.upToDate,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        minSupportedVersion: currentVersion,
        storeUrl: null,
        notes: [],
      );
    }
  }

  UpdateCheckResult evaluate({
    required String currentVersion,
    required UpdateConfig config,
    TargetPlatform? platform,
  }) {
    final effectivePlatform = platform ?? defaultTargetPlatform;
    final storeUrl = config.storeUrlFor(effectivePlatform);
    final notes = config.notesFor(config.latestVersion);

    final belowMin = _compareVersions(currentVersion, config.minSupportedVersion) < 0;
    final belowLatest = _compareVersions(currentVersion, config.latestVersion) < 0;

    UpdateAvailability availability = UpdateAvailability.upToDate;
    if (belowMin || (config.forceUpdate && belowLatest)) {
      availability = UpdateAvailability.updateRequired;
    } else if (belowLatest) {
      availability = UpdateAvailability.updateAvailable;
    }

    return UpdateCheckResult(
      availability: availability,
      currentVersion: currentVersion,
      latestVersion: config.latestVersion,
      minSupportedVersion: config.minSupportedVersion,
      storeUrl: storeUrl,
      notes: notes,
    );
  }

  int _compareVersions(String current, String target) {
    final currentParts = _parseVersion(current);
    final targetParts = _parseVersion(target);
    final length = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < length; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final targetValue = i < targetParts.length ? targetParts[i] : 0;
      if (currentValue != targetValue) {
        return currentValue.compareTo(targetValue);
      }
    }
    return 0;
  }

  List<int> _parseVersion(String version) {
    final normalized = version.split('+').first.trim();
    if (normalized.isEmpty) {
      return const [0];
    }
    return normalized.split('.').map((part) {
      final match = RegExp(r'\d+').firstMatch(part);
      if (match == null) return 0;
      return int.parse(match.group(0)!);
    }).toList();
  }
}
