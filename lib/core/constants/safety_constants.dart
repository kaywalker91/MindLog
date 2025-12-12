/// 안전 필터 관련 상수
/// 자해/자살 등 응급 상황 감지를 위한 키워드 사전
class SafetyConstants {
  SafetyConstants._();

  /// 응급 상황 감지 키워드 목록
  /// 이 키워드가 감지되면 SOS 카드로 분기
  static const List<String> emergencyKeywords = [
    // 자살 관련
    '자살',
    '죽고싶',
    '죽고 싶',
    '죽을래',
    '죽을 래',
    '죽어버릴',
    '죽어 버릴',
    '목숨을 끊',
    '목숨 끊',
    '생을 마감',
    '삶을 끝',
    '삶을 마감',

    // 자해 관련
    '자해',
    '손목을 긋',
    '손목 긋',
    '피를 보',
    '스스로 상처',

    // 소멸 희망
    '없어지고싶',
    '없어지고 싶',
    '사라지고싶',
    '사라지고 싶',
    '세상에서 떠나',
    '세상 떠나',
    '끝내고싶',
    '끝내고 싶',
    '끝장내',

    // 삶에 대한 부정
    '살기싫',
    '살기 싫',
    '살고싶지않',
    '살고 싶지 않',
    '살 이유가 없',
    '살아있기 싫',
    '살아 있기 싫',

    // 극단적 표현
    '죽음',
    '자살충동',
    '자살 충동',
    '죽는게 나',
    '죽는 게 나',
    '차라리 죽',
  ];

  /// SOS 카드에 표시할 긴급 연락처
  static const Map<String, String> emergencyContacts = {
    '자살예방상담전화': '1393',
    '정신건강위기상담전화': '1577-0199',
    '생명의전화': '1588-9191',
    '청소년전화': '1388',
  };

  /// 응급 상황 감지 시 표시할 메시지
  static const String emergencyMessage =
      '지금 많이 힘드시죠. 혼자 감당하지 않으셔도 됩니다.\n'
      '전문 상담사와 이야기를 나눠보시는 건 어떨까요?';

  /// 텍스트에서 응급 키워드가 포함되어 있는지 확인
  static bool containsEmergencyKeyword(String text) {
    final normalizedText = text.replaceAll(' ', '').toLowerCase();

    for (final keyword in emergencyKeywords) {
      final normalizedKeyword = keyword.replaceAll(' ', '').toLowerCase();
      if (normalizedText.contains(normalizedKeyword)) {
        return true;
      }
    }
    return false;
  }

  /// 감지된 응급 키워드 목록 반환 (디버깅/로깅용)
  static List<String> getDetectedKeywords(String text) {
    final normalizedText = text.replaceAll(' ', '').toLowerCase();
    final detected = <String>[];

    for (final keyword in emergencyKeywords) {
      final normalizedKeyword = keyword.replaceAll(' ', '').toLowerCase();
      if (normalizedText.contains(normalizedKeyword)) {
        detected.add(keyword);
      }
    }
    return detected;
  }
}
