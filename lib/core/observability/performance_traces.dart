import 'dart:async';
import 'dart:developer' show TimelineTask;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// 성능 추적 유틸리티
///
/// debug: `dart:developer`의 [TimelineTask]로 DevTools Performance 탭에 표시
/// prod: Firebase Performance Custom Trace로 P50/P95 수집
///
/// 사용:
/// ```dart
/// final result = await PerformanceTraces.measure(
///   PerformanceTraces.dbGetAllDiaries,
///   () => repository.getAllDiaries(),
/// );
/// ```
class PerformanceTraces {
  PerformanceTraces._();

  /// 일기 전체 목록 DB 조회
  static const String dbGetAllDiaries = 'db.getAllDiaries';

  /// Groq AI 분석 호출 (네트워크 + 파싱 포함)
  static const String groqAnalyze = 'groq.analyze';

  /// 알림 설정 적용 (스케줄링 전체)
  static const String notificationApplySettings =
      'notification.applySettings';

  /// 일기 목록 화면 첫 페인트
  static const String firstDiaryListPaint = 'first.diaryList.paint';

  /// 비동기 작업 측정 — 성공/실패 모두 기록
  ///
  /// [traceName]은 [PerformanceTraces]의 const 상수를 사용한다.
  /// [attributes]는 cache_hit, http_status 등 분기 조건을 기록할 때 사용.
  static Future<T> measure<T>(
    String traceName,
    Future<T> Function() task, {
    Map<String, String>? attributes,
  }) async {
    final timeline = kDebugMode ? TimelineTask(filterKey: traceName) : null;
    timeline?.start(traceName);

    Trace? trace;
    if (!kDebugMode) {
      trace = FirebasePerformance.instance.newTrace(traceName);
      await trace.start();
    }

    try {
      final result = await task();
      attributes?.forEach((key, value) {
        trace?.putAttribute(key, value);
      });
      return result;
    } catch (error, stackTrace) {
      trace?.putAttribute('error', '${error.runtimeType}');
      timeline?.finish(arguments: {'error': '$error'});
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      timeline?.finish();
      await trace?.stop();
    }
  }

  /// 동기 작업 측정 (빠른 구간 측정용)
  static T measureSync<T>(
    String traceName,
    T Function() task, {
    Map<String, String>? attributes,
  }) {
    if (!kDebugMode) {
      // prod: 동기 구간은 마이크로 단위라 Firebase Performance에 의미 없음 → skip
      return task();
    }
    final timeline = TimelineTask(filterKey: traceName);
    timeline.start(traceName);
    try {
      return task();
    } finally {
      timeline.finish(arguments: attributes);
    }
  }

  /// 커스텀 메트릭 기록 (cache hit count 등)
  static Future<void> incrementMetric(
    String traceName,
    String metricName, {
    int by = 1,
  }) async {
    if (kDebugMode) return;
    final trace = FirebasePerformance.instance.newTrace(traceName);
    await trace.start();
    trace.incrementMetric(metricName, by);
    await trace.stop();
  }
}
