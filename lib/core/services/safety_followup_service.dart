import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// 위기 감지 후 24시간 뒤 안부 확인 알림 서비스
///
/// isEmergency == true 감지 시, 24시간 후 따뜻한 톤의 팔로업 알림을 예약합니다.
/// - 알림 ID: 2004 (마음케어 채널)
/// - 중복 방지: 24시간 이내 재스케줄링 차단
/// - 48시간 경과 시 팔로업 불필요로 판단
///
/// IMPORTANT: 이 서비스는 isEmergency 플래그만 읽고 수동적 팔로업만 수행합니다.
/// SafetyBlockedFailure 또는 위기 감지 로직을 절대 수정하지 않습니다.
class SafetyFollowupService {
  SafetyFollowupService._();

  // ===== 상수 =====

  static const int notificationId = 2004;
  static const String _prefKey = 'last_emergency_timestamp';
  static const String _followupSentKey = 'safety_followup_sent';
  static const Duration _followupDelay = Duration(hours: 24);
  static const Duration _followupWindow = Duration(hours: 48);

  // ===== 메시지 풀 (따뜻한, 비임상적 한국어) =====

  static const List<String> _titles = ['마음은 좀 괜찮아졌나요?', '안부를 전해요', '하루가 지났어요'];

  static const List<String> _bodies = [
    '어제의 마음이 조금이나마 가벼워졌길 바라요',
    '언제든 마음을 기록해보세요. 당신의 이야기를 들을게요',
    '힘든 시간이 지나갔다면, 오늘은 작은 쉼을 가져보세요',
  ];

  // ===== 테스트 오버라이드 =====

  /// 현재 시간 오버라이드 (테스트용)
  @visibleForTesting
  static DateTime Function()? nowOverride;

  /// NotificationService.scheduleOneTimeNotification() 대체 (테스트용)
  @visibleForTesting
  static Future<bool> Function({
    required int id,
    required String title,
    required String body,
    required dynamic scheduledDate,
    String? payload,
    String channel,
  })?
  scheduleOneTimeOverride;

  /// Random 인스턴스 (테스트에서 결정론적 동작 보장)
  static Random _random = Random();

  /// 테스트용: Random 인스턴스 설정
  @visibleForTesting
  static void setRandom(Random random) => _random = random;

  /// 테스트 상태 전체 리셋
  @visibleForTesting
  static void resetForTesting() {
    nowOverride = null;
    scheduleOneTimeOverride = null;
    _random = Random();
  }

  // ===== 내부 유틸 =====

  /// 현재 시간 반환 (테스트 오버라이드 지원)
  static DateTime _now() => nowOverride?.call() ?? DateTime.now();

  // ===== 테스트용 접근자 =====

  static List<String> get titles => List.unmodifiable(_titles);
  static List<String> get bodies => List.unmodifiable(_bodies);

  // ===== 공개 API =====

  /// 위기 감지 후 24시간 뒤 팔로업 알림 예약
  ///
  /// [emergencyTime] 위기가 감지된 시점
  ///
  /// Returns:
  /// - `true` 스케줄링 성공
  /// - `false` 중복(24시간 이내 이미 예약됨) 또는 스케줄링 실패
  static Future<bool> scheduleFollowup(DateTime emergencyTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = _now();

      // 중복 방지: 24시간 이내 이미 예약된 경우 스킵
      final lastTimestamp = prefs.getInt(_prefKey);
      if (lastTimestamp != null) {
        final lastEmergency = DateTime.fromMillisecondsSinceEpoch(
          lastTimestamp,
        );
        final elapsed = now.difference(lastEmergency);
        if (elapsed < _followupDelay) {
          if (kDebugMode) {
            debugPrint(
              '[SafetyFollowup] Skipped: existing emergency within 24h '
              '(${elapsed.inHours}h ago)',
            );
          }
          return false;
        }
      }

      // 타임스탬프 저장
      await prefs.setInt(_prefKey, emergencyTime.millisecondsSinceEpoch);
      await prefs.setBool(_followupSentKey, false);

      // 24시간 뒤 알림 시간 계산
      final scheduledTime = emergencyTime.add(_followupDelay);
      final tzScheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      // 랜덤 메시지 선택
      final title = _titles[_random.nextInt(_titles.length)];
      final body = _bodies[_random.nextInt(_bodies.length)];

      // 알림 스케줄링
      final bool success;
      if (scheduleOneTimeOverride != null) {
        success = await scheduleOneTimeOverride!(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          payload: '{"type":"mindcare","subtype":"safety_followup"}',
          channel: NotificationService.channelMindcare,
        );
      } else {
        success = await NotificationService.scheduleOneTimeNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          payload: '{"type":"mindcare","subtype":"safety_followup"}',
          channel: NotificationService.channelMindcare,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[SafetyFollowup] Scheduled followup: '
          '$title / $body at $tzScheduledDate (success=$success)',
        );
      }

      return success;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Failed to schedule followup: $e');
        debugPrint('[SafetyFollowup] Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// 팔로업이 필요한지 확인
  ///
  /// 조건:
  /// 1. 마지막 위기 타임스탬프가 존재
  /// 2. 48시간 이내
  /// 3. 아직 팔로업 알림이 전송되지 않음
  ///
  /// Returns: `true` 팔로업 필요, `false` 불필요
  static Future<bool> needsFollowup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getInt(_prefKey);

      if (lastTimestamp == null) return false;

      final lastEmergency = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
      final elapsed = _now().difference(lastEmergency);

      // 48시간 초과 → 팔로업 불필요
      if (elapsed >= _followupWindow) return false;

      // 이미 팔로업 전송됨 → 불필요
      final followupSent = prefs.getBool(_followupSentKey) ?? false;
      if (followupSent) return false;

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Failed to check needsFollowup: $e');
      }
      return false;
    }
  }

  /// 팔로업 알림 취소 + 타임스탬프 정리
  static Future<void> cancelFollowup() async {
    try {
      await NotificationService.cancelNotification(notificationId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      await prefs.remove(_followupSentKey);

      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Cancelled and cleared followup state');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Failed to cancel followup: $e');
      }
    }
  }

  /// 팔로업 알림 전송 완료 마킹
  ///
  /// 알림이 실제 표시된 후 호출하여 중복 전송 방지
  static Future<void> markFollowupSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_followupSentKey, true);

      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Marked followup as sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SafetyFollowup] Failed to mark followup sent: $e');
      }
    }
  }
}
