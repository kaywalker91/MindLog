/// 시간 추상화 인터페이스
///
/// 테스트에서 시간 의존성을 제어하기 위한 패턴입니다.
/// - 프로덕션: [SystemClock] 사용 (DateTime.now())
/// - 테스트: [FixedClock] 사용 (고정된 시간)
///
/// 사용 예:
/// ```dart
/// // 프로덕션 코드
/// final clock = SystemClock();
/// final now = clock.now();
///
/// // 테스트 코드
/// final clock = FixedClock(DateTime(2024, 1, 1, 12, 0));
/// expect(clock.now(), DateTime(2024, 1, 1, 12, 0));
/// ```
abstract class Clock {
  /// 현재 시간 반환
  DateTime now();

  /// 현재 시간 (UTC)
  DateTime nowUtc() => now().toUtc();
}

/// 시스템 시계 (프로덕션용)
///
/// DateTime.now()를 호출하여 실제 현재 시간을 반환합니다.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// 고정 시계 (테스트용)
///
/// 생성자에서 지정한 시간을 항상 반환합니다.
/// 테스트에서 시간 의존적 로직을 결정론적으로 테스트할 때 사용합니다.
class FixedClock implements Clock {
  final DateTime _fixedTime;

  const FixedClock(this._fixedTime);

  @override
  DateTime now() => _fixedTime;

  @override
  DateTime nowUtc() => _fixedTime.toUtc();
}

/// 조절 가능한 시계 (고급 테스트용)
///
/// 시간을 동적으로 변경하거나 진행시킬 수 있습니다.
/// 시간 경과 시뮬레이션이 필요한 테스트에 유용합니다.
class AdjustableClock implements Clock {
  DateTime _currentTime;

  AdjustableClock([DateTime? initialTime])
    : _currentTime = initialTime ?? DateTime.now();

  @override
  DateTime now() => _currentTime;

  @override
  DateTime nowUtc() => _currentTime.toUtc();

  /// 현재 시간 설정
  void setTime(DateTime time) {
    _currentTime = time;
  }

  /// 시간 진행
  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  /// 시간 되돌리기
  void rewind(Duration duration) {
    _currentTime = _currentTime.subtract(duration);
  }
}
