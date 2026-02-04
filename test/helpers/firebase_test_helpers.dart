import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Firebase 테스트용 Mock 설정
///
/// Firebase를 사용하는 테스트에서 `setUpAll` 또는 `setUp`에서 호출합니다.
/// ```dart
/// setUpAll(() async {
///   setupFirebaseCoreMocks();
/// });
/// ```
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Firebase Core Platform
  FirebasePlatform.instance = MockFirebasePlatform();

  // Mock Firebase Analytics Platform
  FirebaseAnalyticsPlatform.instance = MockFirebaseAnalyticsPlatform();
}

/// Mock FirebasePlatform
class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp(name: name);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp(name: name ?? defaultFirebaseAppName);
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseApp()];
}

/// Mock FirebaseApp
class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp({String name = defaultFirebaseAppName})
    : super(
        name,
        const FirebaseOptions(
          apiKey: 'mock-api-key',
          appId: 'mock-app-id',
          messagingSenderId: 'mock-sender-id',
          projectId: 'mock-project-id',
        ),
      );

  @override
  bool get isAutomaticDataCollectionEnabled => true;
}

/// Mock FirebaseAnalyticsPlatform
class MockFirebaseAnalyticsPlatform extends FirebaseAnalyticsPlatform
    with MockPlatformInterfaceMixin {
  MockFirebaseAnalyticsPlatform() : super();

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) {
    return this;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    // Mock: 아무 작업도 하지 않음
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setCurrentScreen({
    String? screenName,
    String? screenClassOverride,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<int?> getSessionId() async => null;
}
