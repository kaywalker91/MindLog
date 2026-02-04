import 'dart:async';

import '../network/circuit_breaker.dart';
import 'exceptions.dart';
import 'failures.dart';

/// 예외를 Failure로 변환하는 표준 매퍼
class FailureMapper {
  const FailureMapper._();

  static Failure from(Object error, {String? message}) {
    if (error is Failure) return error;
    if (error is SafetyBlockException) return const Failure.safetyBlocked();
    if (error is DataNotFoundException) {
      return Failure.dataNotFound(
        message: _mergeMessage(error.message, message),
      );
    }
    if (error is CacheException) {
      return Failure.cache(message: _mergeMessage(error.message, message));
    }
    if (error is NetworkException) {
      return Failure.network(message: _mergeMessage(error.message, message));
    }
    if (error is ApiException) {
      return Failure.api(
        message: _mergeMessage(error.message, message),
        statusCode: error.statusCode,
      );
    }
    if (error is CircuitBreakerOpenException) {
      return const Failure.server(message: '요청이 많아 잠시 후 다시 시도해주세요.');
    }
    if (error is ImageProcessingException) {
      return Failure.imageProcessing(
        message: _mergeMessage(error.message, message),
      );
    }
    if (error is TimeoutException) {
      return const Failure.network(message: '요청 시간이 초과되었습니다.');
    }
    if (error is FormatException) {
      return const Failure.api(message: '응답 형식이 올바르지 않습니다.');
    }
    return Failure.unknown(message: message ?? error.toString());
  }

  static String? _mergeMessage(String? primary, String? fallback) {
    if (primary == null || primary.isEmpty) return fallback;
    return primary;
  }
}
