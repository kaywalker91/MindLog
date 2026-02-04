class AppChangelogEntry {
  final String version;
  final String title;
  final String? date;
  final List<AppChangelogSection> sections;

  const AppChangelogEntry({
    required this.version,
    required this.title,
    required this.sections,
    this.date,
  });
}

class AppChangelogSection {
  final String title;
  final List<String> items;

  const AppChangelogSection({required this.title, required this.items});
}

class AppChangelog {
  AppChangelog._();

  static const List<AppChangelogEntry> entries = [
    AppChangelogEntry(
      version: '1.4.1',
      title: '사용 경험 개선',
      sections: [
        AppChangelogSection(
          title: '온보딩/앱 크롬',
          items: [
            '로딩 온보딩을 테마 컬러 기반으로 개선했어요.',
            '그라데이션 AppBar와 바텀 네비게이션 필 인디케이터를 적용했어요.',
          ],
        ),
        AppChangelogSection(
          title: '통계 화면',
          items: ['감정 통계 화면의 섹션 카피와 배지를 개선했어요.', '히트맵 셀과 범례를 리디자인했어요.'],
        ),
      ],
    ),
    AppChangelogEntry(
      version: '1.4.0',
      title: 'AI 분석 고도화',
      sections: [
        AppChangelogSection(
          title: 'AI 감정 분석',
          items: [
            '시간대별 맞춤 추천을 제공해요.',
            '상황별 Few-shot 예시를 강화했어요.',
            '다국어 혼입을 제거하는 필터를 적용했어요.',
          ],
        ),
        AppChangelogSection(
          title: 'UI/UX 업데이트',
          items: [
            '감정 분석 리포트에 온도계 게이지와 체크박스를 추가했어요.',
            '메인 화면 카드 디자인과 당겨서 새로고침을 개선했어요.',
            '화면 전환과 요소 등장 애니메이션을 강화했어요.',
          ],
        ),
        AppChangelogSection(
          title: '기능 추가',
          items: ['인앱 웹뷰로 공지사항과 약관을 확인할 수 있어요.', '설정 화면에서 개인정보 처리방침을 연결했어요.'],
        ),
      ],
    ),
  ];

  static AppChangelogEntry? byVersion(String version) {
    final normalized = version.trim();
    for (final entry in entries) {
      if (entry.version == normalized) {
        return entry;
      }
    }
    return null;
  }
}
