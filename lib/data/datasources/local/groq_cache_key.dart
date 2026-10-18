import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/constants/ai_character.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prompt_constants.dart';

/// Groq 분석 캐시 키 생성기.
///
/// 동일한 입력(content + character + userName + model + prompt version)에
/// 대해 결정적으로 같은 sha256 해시를 반환한다. 일기 ID 대신 content hash 기반이라
/// 임시저장/복원/재시도 시에도 안정적으로 적중한다.
class GroqCacheKey {
  GroqCacheKey._();

  /// 텍스트 분석 캐시 키.
  static String forText({
    required String content,
    required AiCharacter character,
    String? userName,
  }) {
    return _hash({
      'v': 1,
      'model': AppConstants.groqModel,
      'content': _normalizeContent(content),
      'character': character.id,
      'userName': userName ?? '',
      'imageHashes': const <String>[],
      'promptVersion': PromptConstants.version,
    });
  }

  /// 캐싱 의도 비교에 사용되는 정규화: 양끝 공백 제거 + 연속 공백 단일화.
  static String _normalizeContent(String content) {
    return content.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _hash(Map<String, Object?> payload) {
    final canonical = jsonEncode(payload);
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
