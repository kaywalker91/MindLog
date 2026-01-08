import '../../core/errors/failure_mapper.dart';
import '../../core/errors/failures.dart';

/// Repository 예외를 Failure로 표준화하는 공통 헬퍼
mixin RepositoryFailureHandler {
  Future<T> guardFailure<T>(
    String message,
    Future<T> Function() action,
  ) async {
    return guardFailureWithHook(message, action);
  }

  Future<T> guardFailureWithHook<T>(
    String message,
    Future<T> Function() action, {
    Future<void> Function(Failure failure)? onFailure,
    void Function(Object error, StackTrace stackTrace)? onUnknownFailure,
  }) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      final failure = FailureMapper.from(e, message: message);
      if (failure is UnknownFailure && onUnknownFailure != null) {
        onUnknownFailure(e, stackTrace);
      }
      if (onFailure != null) {
        await onFailure(failure);
      }
      throw failure;
    }
  }
}
