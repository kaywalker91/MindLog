import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 정확한 알람 권한 안내 다이얼로그
class ExactAlarmPermissionDialog extends StatelessWidget {
  const ExactAlarmPermissionDialog({super.key});

  /// 다이얼로그 표시 유틸리티 메서드
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const ExactAlarmPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.alarm_outlined, size: 24),
          SizedBox(width: 8),
          Expanded(child: Text('정확한 알람 권한 필요')),
        ],
      ),
      content: const Text(
        '리마인더가 정확한 시간에 울리려면 "알람 및 리마인더" 권한이 필요합니다.\n\n'
        '설정에서 권한을 허용해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('나중에'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
          child: const Text('설정으로 이동'),
        ),
      ],
    );
  }
}

/// 배터리 최적화 안내 다이얼로그
class BatteryOptimizationDialog extends StatelessWidget {
  const BatteryOptimizationDialog({super.key});

  /// 다이얼로그 표시 유틸리티 메서드
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const BatteryOptimizationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.battery_alert_outlined, size: 24),
          SizedBox(width: 8),
          Expanded(child: Text('배터리 최적화 설정')),
        ],
      ),
      content: const Text(
        '리마인더 알림이 정확히 전달되려면 배터리 최적화에서 이 앱을 제외해야 합니다.\n\n'
        '배터리 최적화가 활성화되면 시스템이 알람을 지연시키거나 전달하지 않을 수 있습니다.\n\n'
        '"허용"을 선택하여 배터리 최적화를 비활성화해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('나중에'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
          child: const Text('허용'),
        ),
      ],
    );
  }
}
