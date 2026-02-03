import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return const UpdateService();
});

final updateConfigProvider = FutureProvider.autoDispose<UpdateConfig>((ref) async {
  final service = ref.read(updateServiceProvider);
  return service.fetchConfig();
});

// ============================================================================
// Changelog Pagination Providers
// ============================================================================

/// 페이지 크기 상수
const int _changelogPageSize = 10;

/// 변경사항 페이지 인덱스 (0부터 시작)
///
/// "이전 버전 더보기" 버튼 클릭 시 증가
final changelogPageIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// "이전 버전 더보기"로 추가 로드했는지 여부
///
/// pageIndex > 0이면 true (더 로드한 상태)
/// "다시 접기" 버튼 표시 조건으로 사용
final hasLoadedMoreChangelogProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(changelogPageIndexProvider) > 0;
});

/// 정렬된 전체 버전 리스트 (캐싱)
final sortedChangelogVersionsProvider = Provider.autoDispose<List<String>>((ref) {
  final config = ref.watch(updateConfigProvider).valueOrNull;
  if (config == null) return [];
  return _sortedVersions(config.changelog.keys);
});

/// 현재 페이지까지 표시할 버전 목록
///
/// pageSize(10개)씩 슬라이싱하여 반환
final paginatedVersionsProvider = Provider.autoDispose<List<String>>((ref) {
  final allVersions = ref.watch(sortedChangelogVersionsProvider);
  final pageIndex = ref.watch(changelogPageIndexProvider);
  final endIndex =
      ((pageIndex + 1) * _changelogPageSize).clamp(0, allVersions.length);
  return allVersions.sublist(0, endIndex);
});

/// 더 불러올 데이터 존재 여부
final hasMoreChangelogProvider = Provider.autoDispose<bool>((ref) {
  final allVersions = ref.watch(sortedChangelogVersionsProvider);
  final pageIndex = ref.watch(changelogPageIndexProvider);
  return (pageIndex + 1) * _changelogPageSize < allVersions.length;
});

// ============================================================================
// Version Sorting Helpers
// ============================================================================

/// 버전 문자열을 내림차순으로 정렬
List<String> _sortedVersions(Iterable<String> versions) {
  final list =
      versions.map((version) => version.trim()).where((v) => v.isNotEmpty).toList();
  list.sort((a, b) => _compareVersions(b, a));
  return list;
}

/// 두 버전 문자열 비교 (semantic versioning)
int _compareVersions(String current, String target) {
  final currentParts = _parseVersion(current);
  final targetParts = _parseVersion(target);
  final length =
      currentParts.length > targetParts.length ? currentParts.length : targetParts.length;

  for (var i = 0; i < length; i++) {
    final currentValue = i < currentParts.length ? currentParts[i] : 0;
    final targetValue = i < targetParts.length ? targetParts[i] : 0;
    if (currentValue != targetValue) {
      return currentValue.compareTo(targetValue);
    }
  }
  return 0;
}

/// 버전 문자열을 정수 리스트로 파싱
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
