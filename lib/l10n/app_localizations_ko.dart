// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'MindLog';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get error => '오류';

  @override
  String get loading => '로딩 중...';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get settings => '설정';

  @override
  String get version => '버전';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get opensourceLicense => '오픈소스 라이선스';

  @override
  String get diaryListTitle => '일기 목록';

  @override
  String get diaryListEmpty => '작성된 일기가 없습니다.\n오늘의 마음을 기록해보세요!';

  @override
  String get diaryWriteToday => '오늘 기록하기';

  @override
  String get analysisWaitMessage => 'AI가 일기를 분석하고 있습니다...';

  @override
  String get analysisComplete => '분석 완료';

  @override
  String get analysisFailed => '분석 실패';

  @override
  String get emotionScore => '감정 점수';

  @override
  String get keywords => '키워드';

  @override
  String get empathyMessage => '공감 메시지';

  @override
  String get actionItem => '추천 행동';

  @override
  String get alertDeleteTitle => '일기 삭제';

  @override
  String get alertDeleteMessage => '정말로 이 일기를 삭제하시겠습니까?';

  @override
  String get alertDeleteAllTitle => '모든 일기 삭제';

  @override
  String get alertDeleteAllMessage => '정말로 모든 일기를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';
}
