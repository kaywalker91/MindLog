import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/safety_constants.dart';

void main() {
  group('SafetyConstants', () {
    group('containsEmergencyKeyword', () {
      test('자살 관련 키워드를 감지해야 한다', () {
        expect(
          SafetyConstants.containsEmergencyKeyword('오늘 너무 힘들어서 자살하고 싶다'),
          true,
        );
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

      test('암시적/완곡한 위기 표현을 감지해야 한다', () {
        // 간접적 죽음 표현
        expect(SafetyConstants.containsEmergencyKeyword('영원히 잠들고 싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('영원히 쉬고 싶어'), true);
        expect(SafetyConstants.containsEmergencyKeyword('이 세상 떠나고 싶다'), true);

        // 끝내고 싶다는 표현
        expect(SafetyConstants.containsEmergencyKeyword('모두 끝나면 좋겠다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('다 끝내고 싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('이 고통 끝내고 싶어'), true);

        // 한계/버티기 힘듦
        expect(SafetyConstants.containsEmergencyKeyword('더이상 못 버티겠다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('더 이상 못 버티겠어'), true);
        expect(SafetyConstants.containsEmergencyKeyword('한계에 도달했다'), true);

        // 해방 표현
        expect(SafetyConstants.containsEmergencyKeyword('해방되고싶다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('고통에서 벗어나고 싶다'), true);

        // 마지막/극단적 선택
        expect(
          SafetyConstants.containsEmergencyKeyword('이게 마지막이라고 생각한다'),
          true,
        );
        expect(SafetyConstants.containsEmergencyKeyword('극단적 선택을 고민했다'), true);
      });

      test('암시적 표현의 띄어쓰기 변형도 감지해야 한다', () {
        expect(SafetyConstants.containsEmergencyKeyword('더 이 상 못버티겠다'), true);
        expect(SafetyConstants.containsEmergencyKeyword('영 원 히 잠 들'), true);
        expect(SafetyConstants.containsEmergencyKeyword('해 방 되 고 싶 다'), true);
      });

      test('일반적인 부정 감정은 응급으로 감지하지 않아야 한다 (False Positive 방지)', () {
        // 일반 스트레스/피로
        expect(
          SafetyConstants.containsEmergencyKeyword('오늘 회사에서 스트레스를 많이 받았다'),
          false,
        );
        expect(SafetyConstants.containsEmergencyKeyword('기분이 우울하다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('피곤하고 지쳤다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('화가 난다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('불안하다'), false);

        // 일상적 힘듦 표현 (위기가 아닌 경우)
        expect(SafetyConstants.containsEmergencyKeyword('오늘 정말 힘들었다'), false);
        expect(
          SafetyConstants.containsEmergencyKeyword('일이 너무 많아서 지친다'),
          false,
        );
        expect(SafetyConstants.containsEmergencyKeyword('요즘 슬럼프다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('번아웃이 온 것 같다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('무기력하다'), false);

        // "끝" 관련 일반 표현
        expect(SafetyConstants.containsEmergencyKeyword('프로젝트가 끝났다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('회의가 끝나서 다행이다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('오늘 업무 끝'), false);

        // "버티다" 관련 일반 표현
        expect(SafetyConstants.containsEmergencyKeyword('오늘 하루 잘 버텼다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('힘들었지만 버텼다'), false);

        // "쉬다" 관련 일반 표현
        expect(SafetyConstants.containsEmergencyKeyword('주말에 푹 쉬어야겠다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('잠시 쉬고 싶다'), false);

        // "떠나다" 관련 일반 표현
        expect(SafetyConstants.containsEmergencyKeyword('여행 떠나고 싶다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('퇴근하고 싶다'), false);

        // 수면 관련 일반 표현
        expect(SafetyConstants.containsEmergencyKeyword('빨리 자고 싶다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('잠이 너무 온다'), false);
      });

      test('긍정적인 내용은 응급으로 감지하지 않아야 한다', () {
        expect(
          SafetyConstants.containsEmergencyKeyword('오늘 정말 좋은 하루였다'),
          false,
        );
        expect(
          SafetyConstants.containsEmergencyKeyword('프로젝트를 잘 마무리했다'),
          false,
        );
        expect(
          SafetyConstants.containsEmergencyKeyword('친구와 맛있는 저녁을 먹었다'),
          false,
        );
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

      test('경계 케이스: 키워드가 포함된 더 긴 문장에서도 감지해야 한다', () {
        expect(
          SafetyConstants.containsEmergencyKeyword(
            '요즘 계속 힘들어서 영원히 잠들면 어떨까 하는 생각이 든다',
          ),
          true,
        );
        expect(
          SafetyConstants.containsEmergencyKeyword(
            '아무도 나를 이해하지 못하고 더이상 못 버티겠다는 생각뿐이다',
          ),
          true,
        );
        expect(
          SafetyConstants.containsEmergencyKeyword('이런 고통에서 벗어나고 싶은 마음이 크다'),
          true,
        );
      });

      test('경계 케이스: 유사하지만 위기가 아닌 표현', () {
        // "죽" 포함하지만 위기 아님
        expect(SafetyConstants.containsEmergencyKeyword('죽도록 일했다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('배고파 죽겠다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('더워 죽겠어'), false);

        // "끝" 포함하지만 위기 아님
        expect(SafetyConstants.containsEmergencyKeyword('일이 끝나지 않는다'), false);
        expect(SafetyConstants.containsEmergencyKeyword('끝까지 해보자'), false);

        // "떠나" 포함하지만 위기 아님
        expect(SafetyConstants.containsEmergencyKeyword('회사를 떠나고 싶다'), false);
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
