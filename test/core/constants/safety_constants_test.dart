import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/safety_constants.dart';

void main() {
  group('SafetyConstants', () {
    group('containsEmergencyKeyword', () {
      test('자살 관련 키워드를 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('오늘 너무 힘들어서 자살하고 싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('죽고싶은 마음이 든다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('죽고 싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('목숨을 끊고 싶다'), true);
      });

      test('자해 관련 키워드를 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('자해를 생각했다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('손목을 긋고 싶다'), true);
      });

      test('소멸 희망 관련 키워드를 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('세상에서 사라지고싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('없어지고 싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('끝내고싶다'), true);
      });

      test('삶에 대한 부정 키워드를 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('살기싫다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('살고 싶지 않다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('살 이유가 없다'), true);
      });

      test('일반적인 부정 감정은 응급으로 감지하지 않아야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('오늘 회사에서 스트레스를 많이 받았다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('기분이 우울하다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('피곤하고 지쳤다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('화가 난다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('불안하다'), false);
      });

      test('긍정적인 내용은 응급으로 감지하지 않아야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('오늘 정말 좋은 하루였다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('프로젝트를 잘 마무리했다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('친구와 맛있는 저녁을 먹었다'), false);
      });

      test('빈 문자열은 응급으로 감지하지 않아야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword(''), false);
        expect(SafetyConstants.containsEmergencyKeyword('   '), false);
      });

      test('띄어쓰기 변형을 정규화하여 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('죽 고 싶 다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('자 살'), true);
        expect(SafetyConstants.containsEmergencyKeyword('없어 지고 싶다'), true);
      });
    });

    group('getDetectedKeywords', () {
      test('감지된 키워드 목록을 반환해야 한다', () {
        final keywords = SafetyConstants.getDetectedKeywords('죽고싶고 자해도 생각났다');
        expect(keywords, isNotEmpty);
        expect(keywords.any((k) => k.contains('죽고싶')), true);
        expect(keywords.any((k) => k.contains('자해')), true);
      });

      test('응급 키워드가 없으면 빈 목록을 반환해야 한다', () {
        final keywords = SafetyConstants.getDetectedKeywords('오늘 하루 평화로웠다');
        expect(keywords, isEmpty);
      });
    });

    group('emergencyContacts', () {
      test('긴급 연락처가 정의되어 있어야 한다', () {
        expect(SafetyConstants.emergencyContacts, isNotEmpty);
        expect(SafetyConstants.emergencyContacts['자살예방상담전화'], '1393');
        expect(SafetyConstants.emergencyContacts['정신건강위기상담전화'], '1577-0199');
      });
    });

    group('emergencyMessage', () {
      test('응급 메시지가 정의되어 있어야 한다', () {
        expect(SafetyConstants.emergencyMessage, isNotEmpty);
        expect(SafetyConstants.emergencyMessage.contains('힘드시'), true);
      });
    });
  });
}
