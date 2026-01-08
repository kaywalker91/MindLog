import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/analytics_service.dart';

final firebaseAnalyticsObserverProvider =
    Provider<FirebaseAnalyticsObserver?>((ref) {
  return AnalyticsService.observer;
});
