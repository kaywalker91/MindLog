import 'dart:async';
import 'package:flutter/foundation.dart';

/// 회로 상태
enum CircuitState {
  closed,   // 정상 상태 (닫힘 - 전류 흐름)
  open,     // 차단 상태 (열림 - 전류 차단)
  halfOpen, // 반열림 상태 (테스트 - 일부 허용)
}

/// 서킷 브레이커 설정
class CircuitBreakerConfig {
  /// 실패 임계값 (이 횟수만큼 연속 실패하면 회로가 열림)
  final int failureThreshold;

  /// 회로가 열려있는 시간
  final Duration resetTimeout;

  /// 반열림 상태에서 성공으로 간주하기 위한 성공 횟수
  final int successThreshold;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.successThreshold = 2,
  });
}

/// 서킷 브레이커 예외
class CircuitBreakerOpenException implements Exception {
  final String message;
  final DateTime? resetTime;

  CircuitBreakerOpenException({
    this.message = 'Service unavailable due to repeated failures',
    this.resetTime,
  });

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// 서킷 브레이커 패턴 구현체
/// 
/// 외부 서비스 호출 실패율이 높을 때 요청을 일시적으로 차단하여
/// 시스템 과부하를 방지하고 빠른 실패를 보장합니다.
class CircuitBreaker {
  final CircuitBreakerConfig config;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreaker({
    this.config = const CircuitBreakerConfig(),
  });

  /// 현재 상태 조회
  CircuitState get state => _state;

  /// 보호된 비동기 작업 실행
  Future<T> run<T>(Future<T> Function() action) async {
    if (_state == CircuitState.open) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > config.resetTimeout) {
        _transitionToHalfOpen();
      } else {
        throw CircuitBreakerOpenException(
          resetTime: _lastFailureTime?.add(config.resetTimeout),
        );
      }
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure(e);
      rethrow;
    }
  }

  void _onSuccess() {
    if (_state == CircuitState.halfOpen) {
      _successCount++;
      if (_successCount >= config.successThreshold) {
        _transitionToClosed();
      }
    } else if (_state == CircuitState.closed) {
      _failureCount = 0;
    }
  }

  void _onFailure(Object error) {
    if (_state == CircuitState.closed) {
      _failureCount++;
      if (_failureCount >= config.failureThreshold) {
        _transitionToOpen();
      }
    } else if (_state == CircuitState.halfOpen) {
      _transitionToOpen();
    }
  }

  void _transitionToOpen() {
    _state = CircuitState.open;
    _lastFailureTime = DateTime.now();
    _resetTimer?.cancel();
    
    if (kDebugMode) {
      debugPrint('🔌 Circuit Breaker OPENED');
    }
    
    // 타임아웃 후 반열림 전환 예약 (run 호출 없이도 자동 전환 가능하게 하려면)
    _resetTimer = Timer(config.resetTimeout, () {
      if (_state == CircuitState.open) {
        // 실제로는 요청이 들어올 때 halfOpen으로 전환하는 게 일반적이지만,
        // 여기서는 타이머로도 가능하게 함 (선택적)
      }
    });
  }

  void _transitionToHalfOpen() {
    _state = CircuitState.halfOpen;
    _successCount = 0;
    if (kDebugMode) {
      debugPrint('🔌 Circuit Breaker HALF-OPEN');
    }
  }

  void _transitionToClosed() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _resetTimer?.cancel();
    if (kDebugMode) {
      debugPrint('🔌 Circuit Breaker CLOSED');
    }
  }
  
  /// 상태 리셋
  void reset() {
    _transitionToClosed();
  }
}
