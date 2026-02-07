import 'dart:math';

import 'package:flutter/foundation.dart';

import 'emotion_trend_service.dart';
import 'notification_service.dart';

/// 감정 트렌드 감지 시 즉시 알림을 보내는 서비스
class EmotionTrendNotificationService {
  EmotionTrendNotificationService._();

  static Random _random = Random();

  // ── 테스트 오버라이드 ──

  @visibleForTesting
  static Future<void> Function({
    required String title,
    required String body,
    String? payload,
    String channel,
  })? showNotificationOverride;

  /// 테스트용: Random 인스턴스 설정
  static void setRandom(Random random) => _random = random;

  /// 테스트용 리셋
  @visibleForTesting
  static void resetForTesting() {
    showNotificationOverride = null;
    _random = Random();
  }

  // ── 트렌드별 메시지 풀 ──

  /// declining (하락): 공감/위로
  static const List<String> _decliningTitles = [
    '마음이 무거운 날이 계속되고 있나요?',
    '요즘 힘든 시간을 보내고 있군요',
    '마음이 가라앉아 있는 것 같아요',
  ];

  static const List<String> _decliningBodies = [
    '당신의 감정은 소중해요. 잠시 쉬어가도 괜찮아요.',
    '힘든 날도 지나갈 거예요. 오늘은 자신에게 친절해보세요.',
    '무거운 마음을 기록해보면 조금 가벼워질 수 있어요.',
  ];

  /// recovering (회복): 격려
  static const List<String> _recoveringTitles = [
    '기분이 나아지고 있어요!',
    '회복의 흐름이 느껴져요',
    '조금씩 좋아지고 있네요',
  ];

  static const List<String> _recoveringBodies = [
    '힘든 시간을 잘 견뎌냈어요. 이 흐름을 이어가세요!',
    '당신의 회복력은 대단해요. 작은 변화가 큰 차이를 만들어요.',
    '좋은 방향으로 가고 있어요. 오늘의 기분도 기록해보세요.',
  ];

  /// gap (공백): 부드러운 리마인더
  static const List<String> _gapTitles = [
    '요즘 어떻게 지내고 있나요?',
    '마음 기록이 그리워요',
    '안부를 전해요',
  ];

  static const List<String> _gapBodies = [
    '며칠간 기록이 없었네요. 오늘의 마음은 어떤가요?',
    '바쁜 날들을 보내고 있나요? 잠깐이라도 마음을 돌아봐요.',
    '기록은 언제든 다시 시작할 수 있어요. 오늘부터 시작해볼까요?',
  ];

  /// steady (안정): 유지 격려
  static const List<String> _steadyTitles = [
    '좋은 하루가 계속되고 있어요!',
    '안정적인 마음이 느껴져요',
    '꾸준한 기록의 힘',
  ];

  static const List<String> _steadyBodies = [
    '긍정적인 상태를 잘 유지하고 있어요. 이 에너지를 계속 간직하세요!',
    '안정된 감정은 소중한 자산이에요. 오늘도 좋은 하루 되세요.',
    '꾸준한 기록이 마음의 힘이 되고 있어요. 대단해요!',
  ];

  /// 트렌드에 따른 메시지 반환
  static ({String title, String body}) _getMessageForTrend(
    EmotionTrend trend,
  ) {
    final List<String> titles;
    final List<String> bodies;

    switch (trend) {
      case EmotionTrend.declining:
        titles = _decliningTitles;
        bodies = _decliningBodies;
      case EmotionTrend.recovering:
        titles = _recoveringTitles;
        bodies = _recoveringBodies;
      case EmotionTrend.gap:
        titles = _gapTitles;
        bodies = _gapBodies;
      case EmotionTrend.steady:
        titles = _steadyTitles;
        bodies = _steadyBodies;
    }

    return (
      title: titles[_random.nextInt(titles.length)],
      body: bodies[_random.nextInt(bodies.length)],
    );
  }

  /// 감정 트렌드 감지 시 즉시 로컬 알림 발송
  ///
  /// [result] EmotionTrendService.analyzeTrend() 결과
  static Future<void> notifyTrend(EmotionTrendResult result) async {
    final message = _getMessageForTrend(result.trend);

    if (kDebugMode) {
      debugPrint(
        '[EmotionTrendNotification] Sending ${result.trend.name}: "${message.title}"',
      );
    }

    if (showNotificationOverride != null) {
      await showNotificationOverride!(
        title: message.title,
        body: message.body,
        payload: '{"type":"mindcare","subtype":"emotion_trend","trend":"${result.trend.name}"}',
        channel: NotificationService.channelMindcare,
      );
    } else {
      await NotificationService.showNotification(
        title: message.title,
        body: message.body,
        payload: '{"type":"mindcare","subtype":"emotion_trend","trend":"${result.trend.name}"}',
        channel: NotificationService.channelMindcare,
      );
    }
  }

  // ── 테스트용 접근자 ──

  static List<String> get decliningTitles =>
      List.unmodifiable(_decliningTitles);
  static List<String> get decliningBodies =>
      List.unmodifiable(_decliningBodies);
  static List<String> get recoveringTitles =>
      List.unmodifiable(_recoveringTitles);
  static List<String> get recoveringBodies =>
      List.unmodifiable(_recoveringBodies);
  static List<String> get gapTitles => List.unmodifiable(_gapTitles);
  static List<String> get gapBodies => List.unmodifiable(_gapBodies);
  static List<String> get steadyTitles => List.unmodifiable(_steadyTitles);
  static List<String> get steadyBodies => List.unmodifiable(_steadyBodies);
}
