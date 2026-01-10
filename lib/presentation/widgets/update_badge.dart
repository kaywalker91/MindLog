import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/update_state_provider.dart';

/// 업데이트 가용 시 표시되는 작은 뱃지 인디케이터
class UpdateBadge extends ConsumerWidget {
  const UpdateBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateStateProvider);

    if (!state.shouldShowBadge) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
      ),
    );
  }
}
