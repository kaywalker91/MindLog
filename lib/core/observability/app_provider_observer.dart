import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod Provider 상태 변화 관찰자
///
/// DevTools에서 Provider 상태 전이를 추적할 수 있도록 로깅합니다.
/// 디버그 모드에서만 출력되며, 프로덕션 빌드에서는 완전히 제거됩니다.
class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    assert(() {
      debugPrint(
        '[Provider] ✅ Created: ${provider.name ?? provider.runtimeType}',
      );
      return true;
    }());
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    assert(() {
      debugPrint(
        '[Provider] 🔄 Updated: ${provider.name ?? provider.runtimeType}',
      );
      return true;
    }());
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    assert(() {
      debugPrint(
        '[Provider] 🗑️ Disposed: ${provider.name ?? provider.runtimeType}',
      );
      return true;
    }());
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    assert(() {
      debugPrint(
        '[Provider] ❌ Failed: ${provider.name ?? provider.runtimeType} — $error',
      );
      return true;
    }());
  }
}
