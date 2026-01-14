import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/data/dto/analysis_response_dto.dart';

void main() {
  group('AnalysisResponseDto', () {
    group('fromJson - action_items 파싱', () {
      test('action_items가 List<String>인 경우 정상 파싱해야 한다', () {
        final json = {
          'keywords': ['테스트', '키워드'],
          'sentiment_score': 7,
          'empathy_message': '좋은 하루였네요.',
          'action_item': '',
          'action_items': ['즉시 행동', '오늘 행동', '이번주 행동'],
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['즉시 행동', '오늘 행동', '이번주 행동']);
        expect(dto.actionItems.length, 3);
      });

      test('action_items가 JSON 배열 문자열인 경우 파싱해야 한다', () {
        // AI가 문자열로 반환한 실제 발생 케이스
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '',
          'action_items': '["즉시 행동", "오늘 행동"]',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['즉시 행동', '오늘 행동']);
      });

      test('action_items가 단일 문자열인 경우 리스트로 변환해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '',
          'action_items': '잠시 휴식을 취하세요',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['잠시 휴식을 취하세요']);
      });

      test('action_items가 빈 배열이고 action_item이 있으면 레거시 값을 사용해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '레거시 행동 아이템',
          'action_items': <String>[],
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['레거시 행동 아이템']);
        expect(dto.actionItem, '레거시 행동 아이템');
      });

      test('action_items와 action_item 모두 없으면 빈 배열이어야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, isEmpty);
      });

      test('action_items가 null이고 action_item만 있으면 레거시 값을 사용해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '유일한 행동',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['유일한 행동']);
      });

      test('action_items가 잘못된 JSON 문자열이면 단일 요소로 처리해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트 메시지',
          'action_item': '',
          'action_items': '[잘못된 JSON',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.actionItems, ['[잘못된 JSON']);
      });
    });

    group('fromJson - 기타 필드', () {
      test('keywords가 동적 타입 리스트여도 String으로 변환해야 한다', () {
        final json = {
          'keywords': [1, 'string', true, 3.14],
          'sentiment_score': 5,
          'empathy_message': '테스트',
          'action_item': '',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.keywords, ['1', 'string', 'true', '3.14']);
      });

      test('emotionCategory가 null이면 null로 유지해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트',
          'action_item': '',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.emotionCategory, isNull);
      });

      test('emotionCategory가 있으면 올바르게 파싱해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트',
          'action_item': '',
          'emotion_category': {
            'primary': '기쁨',
            'secondary': '만족',
          },
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.emotionCategory, isNotNull);
        expect(dto.emotionCategory!.primary, '기쁨');
        expect(dto.emotionCategory!.secondary, '만족');
      });

      test('emotionTrigger가 있으면 올바르게 파싱해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트',
          'action_item': '',
          'emotion_trigger': {
            'category': '직장/학업',
            'description': '프로젝트 성공',
          },
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.emotionTrigger, isNotNull);
        expect(dto.emotionTrigger!.category, '직장/학업');
        expect(dto.emotionTrigger!.description, '프로젝트 성공');
      });

      test('is_emergency 기본값은 false여야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 5,
          'empathy_message': '테스트',
          'action_item': '',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.isEmergency, false);
      });

      test('is_emergency가 true면 true로 파싱해야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 1,
          'empathy_message': '힘드시겠어요',
          'action_item': '1393 전화',
          'is_emergency': true,
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.isEmergency, true);
      });

      test('energyLevel과 cognitivePattern이 파싱되어야 한다', () {
        final json = {
          'keywords': ['테스트'],
          'sentiment_score': 7,
          'empathy_message': '테스트',
          'action_item': '',
          'energy_level': 8,
          'cognitive_pattern': '긍정적 사고',
        };

        final dto = AnalysisResponseDto.fromJson(json);

        expect(dto.energyLevel, 8);
        expect(dto.cognitivePattern, '긍정적 사고');
      });
    });

    group('toEntity', () {
      test('sentimentScore가 1-10 범위로 클램핑되어야 한다', () {
        final dto1 = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 15,
          empathyMessage: '테스트',
          actionItem: '',
        );

        final dto2 = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: -5,
          empathyMessage: '테스트',
          actionItem: '',
        );

        final entity1 = dto1.toEntity();
        final entity2 = dto2.toEntity();

        expect(entity1.sentimentScore, 10);
        expect(entity2.sentimentScore, 1);
      });

      test('energyLevel이 null이면 null로 유지해야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
          energyLevel: null,
        );

        final entity = dto.toEntity();

        expect(entity.energyLevel, isNull);
      });

      test('energyLevel도 1-10 범위로 클램핑되어야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
          energyLevel: 20,
        );

        final entity = dto.toEntity();

        expect(entity.energyLevel, 10);
      });

      test('analyzedAt 파라미터가 없으면 현재 시간을 사용해야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
        );

        final before = DateTime.now();
        final entity = dto.toEntity();
        final after = DateTime.now();

        expect(entity.analyzedAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(entity.analyzedAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('analyzedAt 파라미터가 있으면 해당 시간을 사용해야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
        );
        final customTime = DateTime(2024, 1, 15, 12, 0);

        final entity = dto.toEntity(analyzedAt: customTime);

        expect(entity.analyzedAt, customTime);
      });

      test('emotionCategory가 Entity로 올바르게 변환되어야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
          emotionCategory: const EmotionCategoryDto(
            primary: '슬픔',
            secondary: '외로움',
          ),
        );

        final entity = dto.toEntity();

        expect(entity.emotionCategory, isNotNull);
        expect(entity.emotionCategory!.primary, '슬픔');
        expect(entity.emotionCategory!.secondary, '외로움');
      });

      test('emotionTrigger가 Entity로 올바르게 변환되어야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
          emotionTrigger: const EmotionTriggerDto(
            category: '관계',
            description: '친구와의 대화',
          ),
        );

        final entity = dto.toEntity();

        expect(entity.emotionTrigger, isNotNull);
        expect(entity.emotionTrigger!.category, '관계');
        expect(entity.emotionTrigger!.description, '친구와의 대화');
      });
    });

    group('toJson', () {
      test('모든 필드가 올바르게 직렬화되어야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['키워드1', '키워드2'],
          sentimentScore: 7,
          empathyMessage: '공감 메시지',
          actionItem: '레거시',
          actionItems: ['행동1', '행동2'],
          isEmergency: false,
          emotionCategory: const EmotionCategoryDto(primary: '기쁨', secondary: '만족'),
          emotionTrigger: const EmotionTriggerDto(category: '일', description: '성과'),
          energyLevel: 8,
          cognitivePattern: '긍정적',
        );

        final json = dto.toJson();

        expect(json['keywords'], ['키워드1', '키워드2']);
        expect(json['sentiment_score'], 7);
        expect(json['empathy_message'], '공감 메시지');
        expect(json['action_item'], '레거시');
        expect(json['action_items'], ['행동1', '행동2']);
        expect(json['is_emergency'], false);
        expect(json['emotion_category'], isNotNull);
        expect(json['emotion_trigger'], isNotNull);
        expect(json['energy_level'], 8);
        expect(json['cognitive_pattern'], '긍정적');
      });

      test('null 필드는 JSON에 포함되지 않아야 한다', () {
        final dto = AnalysisResponseDto(
          keywords: ['테스트'],
          sentimentScore: 5,
          empathyMessage: '테스트',
          actionItem: '',
        );

        final json = dto.toJson();

        expect(json.containsKey('emotion_category'), false);
        expect(json.containsKey('emotion_trigger'), false);
        expect(json.containsKey('energy_level'), false);
        expect(json.containsKey('cognitive_pattern'), false);
      });
    });

    group('EmotionCategoryDto', () {
      test('fromJson에서 null 값은 기본값으로 대체되어야 한다', () {
        final json = <String, dynamic>{};

        final dto = EmotionCategoryDto.fromJson(json);

        expect(dto.primary, '평온');
        expect(dto.secondary, '보통');
      });

      test('toEntity가 올바르게 변환되어야 한다', () {
        final dto = const EmotionCategoryDto(
          primary: '분노',
          secondary: '짜증',
        );

        final entity = dto.toEntity();

        expect(entity.primary, '분노');
        expect(entity.secondary, '짜증');
      });
    });

    group('EmotionTriggerDto', () {
      test('fromJson에서 null 값은 기본값으로 대체되어야 한다', () {
        final json = <String, dynamic>{};

        final dto = EmotionTriggerDto.fromJson(json);

        expect(dto.category, '기타');
        expect(dto.description, '');
      });

      test('toEntity가 올바르게 변환되어야 한다', () {
        final dto = const EmotionTriggerDto(
          category: '건강',
          description: '운동 후',
        );

        final entity = dto.toEntity();

        expect(entity.category, '건강');
        expect(entity.description, '운동 후');
      });
    });
  });
}
