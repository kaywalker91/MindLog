import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/secret/delete_secret_pin_usecase.dart';
import 'package:mindlog/domain/usecases/secret/get_secret_diaries_usecase.dart';
import 'package:mindlog/domain/usecases/secret/has_secret_pin_usecase.dart';
import 'package:mindlog/domain/usecases/secret/set_diary_secret_usecase.dart';
import 'package:mindlog/domain/usecases/secret/set_secret_pin_usecase.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';
import 'package:mindlog/presentation/providers/providers.dart';

// ──────────────────────────────────────────────
// Infrastructure
// ──────────────────────────────────────────────
// secureStorageDataSourceProvider / secretPinRepositoryProvider 는
// core/di/infra_providers.dart 로 이전 (providers.dart 배럴 경유 접근).

// ──────────────────────────────────────────────
// UseCase Providers (PIN 관련)
// ──────────────────────────────────────────────

final setSecretPinUseCaseProvider = Provider<SetSecretPinUseCase>(
  (ref) => SetSecretPinUseCase(ref.watch(secretPinRepositoryProvider)),
);

final verifySecretPinUseCaseProvider = Provider<VerifySecretPinUseCase>(
  (ref) => VerifySecretPinUseCase(ref.watch(secretPinRepositoryProvider)),
);

final hasSecretPinUseCaseProvider = Provider<HasSecretPinUseCase>(
  (ref) => HasSecretPinUseCase(ref.watch(secretPinRepositoryProvider)),
);

final deleteSecretPinUseCaseProvider = Provider<DeleteSecretPinUseCase>(
  (ref) => DeleteSecretPinUseCase(
    ref.watch(secretPinRepositoryProvider),
    ref.watch(diaryRepositoryProvider),
  ),
);

// ──────────────────────────────────────────────
// UseCase Providers (일기 비밀 관련)
// ──────────────────────────────────────────────

final setDiarySecretUseCaseProvider = Provider<SetDiarySecretUseCase>(
  (ref) => SetDiarySecretUseCase(ref.watch(diaryRepositoryProvider)),
);

final getSecretDiariesUseCaseProvider = Provider<GetSecretDiariesUseCase>(
  (ref) => GetSecretDiariesUseCase(ref.watch(diaryRepositoryProvider)),
);

// ──────────────────────────────────────────────
// UI State Providers
// ──────────────────────────────────────────────

/// AppBar 버튼 표시 여부 (PIN 설정 여부)
///
/// PIN 설정/삭제 후 ref.invalidate(hasPinProvider) 필수
final hasPinProvider = FutureProvider<bool>(
  (ref) => ref.watch(hasSecretPinUseCaseProvider).execute(),
);

// ──────────────────────────────────────────────
// SecretDiaryListNotifier
// ──────────────────────────────────────────────

/// 비밀일기 목록 상태 관리
///
/// isSecret 변경 후 ref.invalidate(secretDiaryListProvider) 필수
class SecretDiaryListNotifier extends AsyncNotifier<List<Diary>> {
  @override
  Future<List<Diary>> build() =>
      ref.watch(getSecretDiariesUseCaseProvider).execute();
}

final secretDiaryListProvider =
    AsyncNotifierProvider<SecretDiaryListNotifier, List<Diary>>(
      SecretDiaryListNotifier.new,
    );
