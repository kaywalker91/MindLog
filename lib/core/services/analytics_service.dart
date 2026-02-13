import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 서비스
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// 초기화
  static Future<void> initialize() async {
    _analytics ??= FirebaseAnalytics.instance;
    _observer ??= FirebaseAnalyticsObserver(analytics: _analytics!);

    if (kDebugMode) {
      await _analytics!.setAnalyticsCollectionEnabled(true);
    }
  }

  /// Navigator Observer (자동 화면 추적)
  static FirebaseAnalyticsObserver? get observer => _observer;

  static FirebaseAnalytics? _instance() {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics;
  }

  /// 화면 조회 이벤트
  static Future<void> logScreenView(String screenName) async {
    await _instance()?.logScreenView(screenName: screenName);
    _debugLog('screen_view', {'screen_name': screenName});
  }

  /// 앱 오픈 이벤트
  static Future<void> logAppOpen() async {
    await _instance()?.logAppOpen();
    _debugLog('app_open', {});
  }

  /// 일기 작성 이벤트
  static Future<void> logDiaryCreated({
    required int contentLength,
    String? aiCharacterId,
  }) async {
    await _instance()?.logEvent(
      name: 'diary_created',
      parameters: {
        'content_length': contentLength,
        'ai_character_id': aiCharacterId ?? 'default',
      },
    );
    _debugLog('diary_created', {
      'content_length': contentLength,
      'ai_character_id': aiCharacterId,
    });
  }

  /// 일기 분석 완료 이벤트
  static Future<void> logDiaryAnalyzed({
    required String aiCharacterId,
    required int sentimentScore,
    required int energyLevel,
  }) async {
    await _instance()?.logEvent(
      name: 'diary_analyzed',
      parameters: {
        'ai_character_id': aiCharacterId,
        'sentiment_score': sentimentScore,
        'energy_level': energyLevel,
      },
    );
    _debugLog('diary_analyzed', {
      'ai_character_id': aiCharacterId,
      'sentiment_score': sentimentScore,
    });
  }

  /// 행동 지침 완료 이벤트
  static Future<void> logActionItemCompleted({
    required String actionItemText,
  }) async {
    await _instance()?.logEvent(
      name: 'action_item_completed',
      parameters: {
        'action_item_preview': actionItemText.length > 50
            ? actionItemText.substring(0, 50)
            : actionItemText,
      },
    );
    _debugLog('action_item_completed', {});
  }

  /// AI 캐릭터 변경 이벤트
  static Future<void> logAiCharacterChanged({
    required String fromCharacterId,
    required String toCharacterId,
  }) async {
    await _instance()?.logEvent(
      name: 'ai_character_changed',
      parameters: {
        'from_character': fromCharacterId,
        'to_character': toCharacterId,
      },
    );
    _debugLog('ai_character_changed', {
      'from': fromCharacterId,
      'to': toCharacterId,
    });
  }

  /// 통계 화면 조회 이벤트
  static Future<void> logStatisticsViewed({required String period}) async {
    await _instance()?.logEvent(
      name: 'statistics_viewed',
      parameters: {'period': period},
    );
    _debugLog('statistics_viewed', {'period': period});
  }

  /// 리마인더 스케줄링 이벤트
  ///
  /// [hour] 스케줄된 시간 (0-23)
  /// [minute] 스케줄된 분 (0-59)
  /// [source] 스케줄링 트리거 소스 ('user_toggle', 'app_start', 'time_change')
  /// [scheduleMode] 스케줄 모드 ('exact' 또는 'inexact')
  /// [timezoneName] 현재 timezone 이름 (예: 'Asia/Seoul')
  static Future<void> logReminderScheduled({
    required int hour,
    required int minute,
    required String source,
    String? scheduleMode,
    String? timezoneName,
  }) async {
    final params = <String, Object>{
      'reminder_hour': hour,
      'reminder_minute': minute,
      'source': source,
    };
    if (scheduleMode != null) params['schedule_mode'] = scheduleMode;
    if (timezoneName != null) params['timezone'] = timezoneName;

    await _instance()?.logEvent(name: 'reminder_scheduled', parameters: params);
    _debugLog('reminder_scheduled', {
      'hour': hour,
      'minute': minute,
      'source': source,
      if (scheduleMode != null) 'schedule_mode': scheduleMode,
      if (timezoneName != null) 'timezone': timezoneName,
    });
  }

  /// 리마인더 취소 이벤트
  ///
  /// [source] 취소 트리거 소스 ('user_toggle', 'reschedule')
  static Future<void> logReminderCancelled({required String source}) async {
    await _instance()?.logEvent(
      name: 'reminder_cancelled',
      parameters: {'source': source},
    );
    _debugLog('reminder_cancelled', {'source': source});
  }

  /// 리마인더 스케줄링 실패 이벤트
  ///
  /// [errorType] 에러 타입 (예: 'permission_denied', 'schedule_failed')
  static Future<void> logReminderScheduleFailed({
    required String errorType,
  }) async {
    await _instance()?.logEvent(
      name: 'reminder_schedule_failed',
      parameters: {'error_type': errorType},
    );
    _debugLog('reminder_schedule_failed', {'error_type': errorType});
  }

  /// 마음 케어 알림 활성화 이벤트
  static Future<void> logMindcareEnabled() async {
    await _instance()?.logEvent(name: 'mindcare_enabled');
    _debugLog('mindcare_enabled', {});
  }

  /// 마음 케어 알림 비활성화 이벤트
  static Future<void> logMindcareDisabled() async {
    await _instance()?.logEvent(name: 'mindcare_disabled');
    _debugLog('mindcare_disabled', {});
  }

  /// 일반 이벤트 로깅
  static Future<void> logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _instance()?.logEvent(name: eventName, parameters: parameters);
    _debugLog(eventName, parameters ?? {});
  }

  /// 사용자 속성 설정
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _instance()?.setUserProperty(name: name, value: value);
  }

  static void _debugLog(String event, Map<String, dynamic> params) {
    if (kDebugMode) {
      debugPrint('[Analytics] $event: $params');
    }
  }
}
