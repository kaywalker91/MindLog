import 'package:flutter/foundation.dart';

DebugPrintCallback? _savedDebugPrint;

/// 의도적 에러 경로 테스트의 debugPrint 노이즈 억제.
void muteDebugPrint() {
  _savedDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {};
}

void restoreDebugPrint() {
  final saved = _savedDebugPrint;
  if (saved != null) {
    debugPrint = saved;
    _savedDebugPrint = null;
  }
}