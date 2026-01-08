import '../../core/errors/failure_mapper.dart';

/// Repository 예외를 Failure로 표준화하는 공통 헬퍼
mixin RepositoryFailureHandler {
  Future<T> guardFailure<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      throw FailureMapper.from(e, message: message);
    }
  }
}
