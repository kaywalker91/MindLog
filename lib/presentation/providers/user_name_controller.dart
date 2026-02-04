import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/presentation/providers/providers.dart';

/// 유저 이름 상태 관리 컨트롤러
class UserNameController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    return repository.getUserName();
  }

  /// 유저 이름 설정 (null 전달 시 삭제)
  Future<void> setUserName(String? name) async {
    final repository = ref.read(settingsRepositoryProvider);
    final trimmedName = name?.trim();
    final finalName = (trimmedName?.isEmpty ?? true) ? null : trimmedName;

    await repository.setUserName(finalName);
    state = AsyncValue.data(finalName);
  }
}

final userNameProvider = AsyncNotifierProvider<UserNameController, String?>(() {
  return UserNameController();
});
