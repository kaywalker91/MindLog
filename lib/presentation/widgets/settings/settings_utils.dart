import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';

/// 버전 라벨 포맷팅
String formatVersionLabel(AppVersionInfo info) {
  final build = info.buildNumber.trim();
  if (build.isEmpty) {
    return 'v${info.version}';
  }
  return 'v${info.version} ($build)';
}

/// 시간 라벨 포맷팅
String formatTimeLabel(BuildContext context, int hour, int minute) {
  final timeOfDay = TimeOfDay(hour: hour, minute: minute);
  return MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);
}

/// SnackBar 표시 유틸리티
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// 외부 URL 열기 (이메일, Play Store 등)
///
/// 다중 fallback 전략을 적용하여 URL 열기 성공률을 높입니다.
Future<bool> launchExternalUrl(String url, [BuildContext? context]) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('잘못된 URL 형식입니다.')));
    }
    return false;
  }

  try {
    // 1차 시도: 외부 앱으로 직접 열기
    var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    // 2차 시도: 브라우저 외 외부 앱
    if (!launched) {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    }

    // 3차 시도: 시스템 기본 방식
    if (!launched) {
      launched = await launchUrl(uri);
    }

    if (!launched && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다. Play Store에서 직접 검색해주세요.')),
      );
    }
    return launched;
  } catch (e) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('링크 열기 실패: $e')));
    }
    return false;
  }
}
