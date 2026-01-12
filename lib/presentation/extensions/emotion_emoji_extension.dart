import '../../domain/entities/diary.dart';

/// EmotionCategory에 대한 이모지 매핑 (Presentation Layer)
///
/// UI 관련 로직은 Domain Layer가 아닌 Presentation Layer에 위치해야 합니다.
/// Clean Architecture 원칙에 따라 Domain Entity는 순수 비즈니스 로직만 포함합니다.
extension EmotionCategoryEmoji on EmotionCategory {
  /// 1차 감정에 해당하는 이모지 반환
  String get primaryEmoji {
    return switch (primary) {
      '기쁨' => '😊',
      '슬픔' => '😢',
      '분노' => '😠',
      '공포' => '😨',
      '놀람' => '😲',
      '혐오' => '🤢',
      '평온' => '😌',
      _ => '😌', // default
    };
  }
}

/// EmotionTrigger에 대한 이모지 매핑 (Presentation Layer)
extension EmotionTriggerEmoji on EmotionTrigger {
  /// 카테고리에 해당하는 아이콘 이모지 반환
  String get categoryEmoji {
    return switch (category) {
      '일/업무' => '💼',
      '관계' => '👥',
      '건강' => '🏥',
      '재정' => '💰',
      '자아' => '🪞',
      '환경' => '🏠',
      '기타' => '📌',
      _ => '📌', // default
    };
  }
}
