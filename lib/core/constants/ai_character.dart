enum AiCharacter {
  warmCounselor,
  realisticCoach,
  cheerfulFriend,
}

extension AiCharacterMetadata on AiCharacter {
  String get id {
    return switch (this) {
      AiCharacter.warmCounselor => 'warm_counselor',
      AiCharacter.realisticCoach => 'realistic_coach',
      AiCharacter.cheerfulFriend => 'cheerful_friend',
    };
  }

  String get displayName {
    return switch (this) {
      AiCharacter.warmCounselor => '따뜻한 상담사',
      AiCharacter.realisticCoach => '현실적 코치',
      AiCharacter.cheerfulFriend => '유쾌한 친구',
    };
  }

  String get description {
    return switch (this) {
      AiCharacter.warmCounselor => '부드럽고 따뜻한 공감 중심',
      AiCharacter.realisticCoach => '명확하고 실행 중심의 조언',
      AiCharacter.cheerfulFriend => '밝고 유쾌한 분위기의 위로',
    };
  }

  String get imagePath {
    return switch (this) {
      AiCharacter.warmCounselor => 'assets/images/characters/warm_counselor.png',
      AiCharacter.realisticCoach => 'assets/images/characters/realistic_coach.png',
      AiCharacter.cheerfulFriend => 'assets/images/characters/cheerful_friend.png',
    };
  }
}

AiCharacter aiCharacterFromId(String? id) {
  return switch (id) {
    'realistic_coach' => AiCharacter.realisticCoach,
    'cheerful_friend' => AiCharacter.cheerfulFriend,
    _ => AiCharacter.warmCounselor,
  };
}
