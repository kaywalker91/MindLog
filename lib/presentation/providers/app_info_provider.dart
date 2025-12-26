import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final String version;
  final String buildNumber;

  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });
}

final appInfoProvider = FutureProvider.autoDispose<AppVersionInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersionInfo(
    version: info.version,
    buildNumber: info.buildNumber,
  );
});
