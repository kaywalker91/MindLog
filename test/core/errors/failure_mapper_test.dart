import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/errors/failure_mapper.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/network/circuit_breaker.dart';

void main() {
  group('FailureMapper', () {
    test('Failure는 그대로 반환해야 한다', () {
      const failure = Failure.cache(message: '캐시 오류');

      final result = FailureMapper.from(failure);

      expect(result, isA<CacheFailure>());
      expect(result.message, '캐시 오류');
    });

    test('NetworkException은 NetworkFailure로 변환해야 한다', () {
      final result = FailureMapper.from(NetworkException('네트워크 오류'));

      expect(result, isA<NetworkFailure>());
      expect(result.message, '네트워크 오류');
    });

    test('ApiException은 ApiFailure로 변환해야 한다', () {
      final result = FailureMapper.from(ApiException(
        message: 'API 오류',
        statusCode: 500,
      ));

      expect(result, isA<ApiFailure>());
      expect((result as ApiFailure).statusCode, 500);
      expect(result.message, 'API 오류');
    });

    test('CacheException은 CacheFailure로 변환해야 한다', () {
      final result = FailureMapper.from(CacheException('캐시 실패'));

      expect(result, isA<CacheFailure>());
      expect(result.message, '캐시 실패');
    });

    test('DataNotFoundException은 DataNotFoundFailure로 변환해야 한다', () {
      final result = FailureMapper.from(DataNotFoundException('데이터 없음'));

      expect(result, isA<DataNotFoundFailure>());
      expect(result.message, '데이터 없음');
    });

    test('SafetyBlockException은 SafetyBlockedFailure로 변환해야 한다', () {
      final result = FailureMapper.from(SafetyBlockException());

      expect(result, isA<SafetyBlockedFailure>());
    });

    test('CircuitBreakerOpenException은 ServerFailure로 변환해야 한다', () {
      final result = FailureMapper.from(CircuitBreakerOpenException());

      expect(result, isA<ServerFailure>());
    });

    test('TimeoutException은 NetworkFailure로 변환해야 한다', () {
      final result = FailureMapper.from(
        TimeoutException('timeout'),
        message: '요청 시간이 초과되었습니다.',
      );

      expect(result, isA<NetworkFailure>());
      expect(result.message, '요청 시간이 초과되었습니다.');
    });

    test('FormatException은 ApiFailure로 변환해야 한다', () {
      final result = FailureMapper.from(const FormatException('bad format'));

      expect(result, isA<ApiFailure>());
      expect(result.message, '응답 형식이 올바르지 않습니다.');
    });

    test('알 수 없는 예외는 UnknownFailure로 변환해야 한다', () {
      final result = FailureMapper.from(
        ArgumentError('oops'),
        message: '알 수 없는 오류',
      );

      expect(result, isA<UnknownFailure>());
      expect(result.message, '알 수 없는 오류');
    });
  });
}
