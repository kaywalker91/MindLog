// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MindLog';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get settings => 'Settings';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get opensourceLicense => 'Open Source License';

  @override
  String get diaryListTitle => 'Diary List';

  @override
  String get diaryListEmpty => 'No diaries yet.\nRecord your mind today!';

  @override
  String get diaryWriteToday => 'Write Today';

  @override
  String get analysisWaitMessage => 'AI is analyzing your diary...';

  @override
  String get analysisComplete => 'Analysis Complete';

  @override
  String get analysisFailed => 'Analysis Failed';

  @override
  String get emotionScore => 'Emotion Score';

  @override
  String get keywords => 'Keywords';

  @override
  String get empathyMessage => 'Empathy Message';

  @override
  String get actionItem => 'Action Item';

  @override
  String get alertDeleteTitle => 'Delete Diary';

  @override
  String get alertDeleteMessage =>
      'Are you sure you want to delete this diary?';

  @override
  String get alertDeleteAllTitle => 'Delete All Diaries';

  @override
  String get alertDeleteAllMessage =>
      'Are you sure you want to delete all diaries?\nThis action cannot be undone.';
}
