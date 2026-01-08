import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/crashlytics_service.dart';

/// 앱 전역 에러 처리 설정
/// 
/// main() 함수에서 앱 실행 전에 호출하여 에러 핸들링을 설정합니다.
class ErrorBoundary {
  ErrorBoundary._();

  /// 에러 핸들러 초기화
  /// 
  /// [onError] - 에러 발생 시 호출될 콜백 (예: Crashlytics 로깅)
  static void initialize({
    void Function(Object error, StackTrace stack)? onError,
  }) {
    // Flutter 프레임워크 에러 핸들링
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack ?? StackTrace.current);
      onError?.call(details.exception, details.stack ?? StackTrace.current);
    };

    // 위젯 빌드 에러 시 표시할 커스텀 에러 위젯
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _MindlogErrorWidget(details: details);
    };

    // PlatformDispatcher 에러 핸들링 (Flutter 3.10+)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      onError?.call(error, stack);
      return true;
    };
  }

  /// 앱을 에러 존 안에서 실행
  /// 
  /// [appBuilder] - 앱 위젯을 반환하는 함수
  /// [onEnsureInitialized] - 앱 실행 전 초기화 로직 (Zone 내부에서 실행됨)
  /// [onError] - 에러 발생 시 호출될 콜백
  static void runAppWithErrorHandling({
    required Widget Function() appBuilder,
    Future<void> Function()? onEnsureInitialized,
    void Function(Object error, StackTrace stack)? onError,
  }) {
    runZonedGuarded(
      () async {
        // ✅ Zone 내부 진입 후 바인딩 초기화
        WidgetsFlutterBinding.ensureInitialized();
        
        // 추가 초기화 로직 실행
        if (onEnsureInitialized != null) {
          await onEnsureInitialized();
        }

        initialize(onError: onError);
        runApp(appBuilder());
      },
      (error, stack) {
        _logError(error, stack);
        onError?.call(error, stack);
      },
    );
  }

  /// 에러 로깅 (디버그 모드에서만 출력)
  static void _logError(Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('🚨 [ErrorBoundary] Uncaught error: $error');
      debugPrint('$stack');
    }
    CrashlyticsService.recordError(
      error,
      stack,
      fatal: true,
    );
  }
}

/// MindLog 커스텀 에러 위젯
/// 
/// 위젯 빌드 중 에러가 발생했을 때 사용자에게 표시됩니다.
class _MindlogErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _MindlogErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    // 디버그 모드에서는 기본 에러 위젯 표시
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }

    // 릴리즈 모드에서는 사용자 친화적 UI 표시
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 에러 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sentiment_dissatisfied,
                  size: 48,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // 에러 메시지
              const Text(
                '앗, 문제가 발생했어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '잠시 후 다시 시도해주세요.\n문제가 계속되면 앱을 재시작해주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 재시도 안내
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 화면을 아래로 당기거나\n뒤로가기를 눌러보세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
