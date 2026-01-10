import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/network/circuit_breaker.dart';

void main() {
  group('CircuitBreakerConfig', () {
    test('기본값이 올바르게 설정되어 있다', () {
      // Given & When
      const config = CircuitBreakerConfig();

      // Then
      expect(config.failureThreshold, 5);
      expect(config.resetTimeout, const Duration(seconds: 30));
      expect(config.successThreshold, 2);
    });

    test('커스텀 값으로 설정할 수 있다', () {
      // Given & When
      const config = CircuitBreakerConfig(
        failureThreshold: 3,
        resetTimeout: Duration(seconds: 60),
        successThreshold: 1,
      );

      // Then
      expect(config.failureThreshold, 3);
      expect(config.resetTimeout, const Duration(seconds: 60));
      expect(config.successThreshold, 1);
    });
  });

  group('CircuitBreakerOpenException', () {
    test('기본 메시지가 설정되어 있다', () {
      // Given & When
      final exception = CircuitBreakerOpenException();

      // Then
      expect(exception.message, contains('unavailable'));
      expect(exception.resetTime, isNull);
    });

    test('커스텀 메시지와 리셋 시간을 설정할 수 있다', () {
      // Given
      final resetTime = DateTime.now().add(const Duration(seconds: 30));

      // When
      final exception = CircuitBreakerOpenException(
        message: '서비스 일시 중단',
        resetTime: resetTime,
      );

      // Then
      expect(exception.message, '서비스 일시 중단');
      expect(exception.resetTime, resetTime);
    });

    test('toString이 올바른 형식을 반환한다', () {
      // Given
      final exception = CircuitBreakerOpenException(message: 'test');

      // When
      final result = exception.toString();

      // Then
      expect(result, 'CircuitBreakerOpenException: test');
    });
  });

  group('CircuitBreaker', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          resetTimeout: Duration(milliseconds: 100),
          successThreshold: 2,
        ),
      );
    });

    group('초기 상태', () {
      test('처음에는 closed 상태이다', () {
        expect(circuitBreaker.state, CircuitState.closed);
      });
    });

    group('closed 상태', () {
      test('성공하는 작업은 정상 실행된다', () async {
        // Given
        int callCount = 0;

        // When
        final result = await circuitBreaker.run(() async {
          callCount++;
          return 'success';
        });

        // Then
        expect(result, 'success');
        expect(callCount, 1);
        expect(circuitBreaker.state, CircuitState.closed);
      });

      test('실패 횟수가 임계값 미만이면 closed 상태를 유지한다', () async {
        // Given: failureThreshold = 3

        // When: 2번 실패
        for (int i = 0; i < 2; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }

        // Then: 여전히 closed
        expect(circuitBreaker.state, CircuitState.closed);
      });

      test('실패 횟수가 임계값에 도달하면 open 상태로 전환된다', () async {
        // Given: failureThreshold = 3

        // When: 3번 실패
        for (int i = 0; i < 3; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }

        // Then: open 상태로 전환
        expect(circuitBreaker.state, CircuitState.open);
      });

      test('성공하면 실패 카운트가 리셋된다', () async {
        // Given: 2번 실패
        for (int i = 0; i < 2; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }

        // When: 1번 성공
        await circuitBreaker.run(() async => 'success');

        // Then: 다시 3번 실패해야 open (리셋됨)
        for (int i = 0; i < 2; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }

        expect(circuitBreaker.state, CircuitState.closed);
      });
    });

    group('open 상태', () {
      setUp(() async {
        // open 상태로 만들기 (3번 실패)
        for (int i = 0; i < 3; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }
        expect(circuitBreaker.state, CircuitState.open);
      });

      test('open 상태에서는 즉시 예외를 던진다', () async {
        // When & Then
        expect(
          () => circuitBreaker.run(() async => 'success'),
          throwsA(isA<CircuitBreakerOpenException>()),
        );
      });

      test('리셋 타임아웃 후 halfOpen 상태로 전환된다', () async {
        // Given: resetTimeout = 100ms
        await Future.delayed(const Duration(milliseconds: 150));

        // When: 다시 시도
        await circuitBreaker.run(() async => 'success');

        // Then: halfOpen을 거쳐 closed로 전환 시작
        expect(
          circuitBreaker.state,
          anyOf(CircuitState.halfOpen, CircuitState.closed),
        );
      });
    });

    group('halfOpen 상태', () {
      setUp(() async {
        // halfOpen 상태로 만들기
        for (int i = 0; i < 3; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 150));
        // 한 번 성공으로 halfOpen 진입
        await circuitBreaker.run(() async => 'success');
      });

      test('연속 성공 시 closed 상태로 전환된다', () async {
        // Given: successThreshold = 2, 이미 1번 성공

        // When: 1번 더 성공 (총 2번)
        await circuitBreaker.run(() async => 'success');

        // Then: closed 상태로 전환
        expect(circuitBreaker.state, CircuitState.closed);
      });

      test('실패 시 다시 open 상태로 전환된다', () async {
        // 새로운 CircuitBreaker로 테스트
        final breaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 1,
            resetTimeout: Duration(milliseconds: 50),
            successThreshold: 2,
          ),
        );

        // open 상태로 만들기
        try {
          await breaker.run(() async => throw Exception('fail'));
        } catch (_) {}
        expect(breaker.state, CircuitState.open);

        // 타임아웃 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // halfOpen으로 전환 (성공)
        await breaker.run(() async => 'success');
        expect(breaker.state, CircuitState.halfOpen);

        // 실패하면 다시 open
        try {
          await breaker.run(() async => throw Exception('fail'));
        } catch (_) {}

        expect(breaker.state, CircuitState.open);
      });
    });

    group('reset', () {
      test('상태를 closed로 리셋한다', () async {
        // Given: open 상태
        for (int i = 0; i < 3; i++) {
          try {
            await circuitBreaker.run(() async {
              throw Exception('failure');
            });
          } catch (_) {}
        }
        expect(circuitBreaker.state, CircuitState.open);

        // When
        circuitBreaker.reset();

        // Then
        expect(circuitBreaker.state, CircuitState.closed);
      });
    });

    group('실제 사용 시나리오', () {
      test('API 호출 실패 후 복구 시나리오', () async {
        // Given: 불안정한 서비스
        int callCount = 0;
        bool serviceHealthy = false;

        Future<String> unstableService() async {
          callCount++;
          if (!serviceHealthy) {
            throw Exception('Service unavailable');
          }
          return 'data';
        }

        final breaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 2,
            resetTimeout: Duration(milliseconds: 50),
            successThreshold: 1,
          ),
        );

        // When: 2번 실패 → 회로 열림
        for (int i = 0; i < 2; i++) {
          try {
            await breaker.run(unstableService);
          } catch (_) {}
        }
        expect(breaker.state, CircuitState.open);
        expect(callCount, 2);

        // 회로 열린 상태에서는 서비스 호출 안됨
        try {
          await breaker.run(unstableService);
        } catch (_) {}
        expect(callCount, 2); // 증가하지 않음

        // 서비스 복구
        serviceHealthy = true;

        // 타임아웃 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // 다시 시도 → 성공 → 회로 닫힘
        final result = await breaker.run(unstableService);
        expect(result, 'data');
        expect(breaker.state, CircuitState.closed);
      });
    });
  });
}
