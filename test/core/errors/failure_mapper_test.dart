import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/errors/failure_mapper.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/network/circuit_breaker.dart';

void main() {
  group('FailureMapper', () {
    group('from', () {
      test('Failure는 그대로 반환한다', () {
        // Given
        const originalFailure = NetworkFailure(message: 'original');

        // When
        final result = FailureMapper.from(originalFailure);

        // Then
        expect(result, same(originalFailure));
      });

      test('SafetyBlockException을 SafetyBlockedFailure로 변환한다', () {
        // Given
        final exception = SafetyBlockException('blocked');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<SafetyBlockedFailure>());
      });

      test('DataNotFoundException을 DataNotFoundFailure로 변환한다', () {
        // Given
        final exception = DataNotFoundException('데이터 없음');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<DataNotFoundFailure>());
        expect(result.displayMessage, '데이터 없음');
      });

      test('CacheException을 CacheFailure로 변환한다', () {
        // Given
        final exception = CacheException('저장 실패');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<CacheFailure>());
        expect(result.displayMessage, '저장 실패');
      });

      test('NetworkException을 NetworkFailure로 변환한다', () {
        // Given
        final exception = NetworkException('연결 끊김');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<NetworkFailure>());
        expect(result.displayMessage, '연결 끊김');
      });

      test('ApiException을 ApiFailure로 변환한다', () {
        // Given
        final exception = ApiException(message: 'API 오류', statusCode: 500);

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<ApiFailure>());
        expect((result as ApiFailure).statusCode, 500);
        expect(result.displayMessage, 'API 오류');
      });

      test('CircuitBreakerOpenException을 ServerFailure로 변환한다', () {
        // Given
        final exception = CircuitBreakerOpenException();

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<ServerFailure>());
        expect(result.displayMessage, contains('잠시 후'));
      });

      test('TimeoutException을 NetworkFailure로 변환한다', () {
        // Given
        final exception = TimeoutException('timeout');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<NetworkFailure>());
        expect(result.displayMessage, contains('시간'));
      });

      test('FormatException을 ApiFailure로 변환한다', () {
        // Given
        const exception = FormatException('invalid');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<ApiFailure>());
        expect(result.displayMessage, contains('형식'));
      });

      test('알 수 없는 예외를 UnknownFailure로 변환한다', () {
        // Given
        final exception = Exception('unknown error');

        // When
        final result = FailureMapper.from(exception);

        // Then
        expect(result, isA<UnknownFailure>());
      });

      test('message 파라미터로 메시지를 오버라이드할 수 있다', () {
        // Given: 메시지 없는 예외
        final exception = NetworkException();

        // When: 외부에서 메시지 제공
        final result = FailureMapper.from(exception, message: '커스텀 메시지');

        // Then
        expect(result, isA<NetworkFailure>());
        expect(result.displayMessage, '커스텀 메시지');
      });

      test('예외의 메시지가 우선된다', () {
        // Given: 메시지 있는 예외
        final exception = NetworkException('예외 메시지');

        // When: 외부에서도 메시지 제공
        final result = FailureMapper.from(exception, message: '외부 메시지');

        // Then: 예외의 메시지가 우선
        expect(result.displayMessage, '예외 메시지');
      });
    });

    group('_mergeMessage', () {
      test('primary가 있으면 primary를 반환한다', () {
        final exception = NetworkException('primary');
        final result = FailureMapper.from(exception, message: 'fallback');
        expect(result.displayMessage, 'primary');
      });

      test('primary가 없으면 fallback을 반환한다', () {
        final exception = NetworkException();
        final result = FailureMapper.from(exception, message: 'fallback');
        expect(result.displayMessage, 'fallback');
      });

      test('primary가 빈 문자열이면 fallback을 반환한다', () {
        final exception = NetworkException('');
        final result = FailureMapper.from(exception, message: 'fallback');
        expect(result.displayMessage, 'fallback');
      });
    });
  });
}
