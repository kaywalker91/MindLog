import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'MindLog'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @error.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get privacyPolicy;

  /// No description provided for @opensourceLicense.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get opensourceLicense;

  /// No description provided for @diaryListTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 목록'**
  String get diaryListTitle;

  /// No description provided for @diaryListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'작성된 일기가 없습니다.\n오늘의 마음을 기록해보세요!'**
  String get diaryListEmpty;

  /// No description provided for @diaryWriteToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기록하기'**
  String get diaryWriteToday;

  /// No description provided for @analysisWaitMessage.
  ///
  /// In ko, this message translates to:
  /// **'AI가 일기를 분석하고 있습니다...'**
  String get analysisWaitMessage;

  /// No description provided for @analysisComplete.
  ///
  /// In ko, this message translates to:
  /// **'분석 완료'**
  String get analysisComplete;

  /// No description provided for @analysisFailed.
  ///
  /// In ko, this message translates to:
  /// **'분석 실패'**
  String get analysisFailed;

  /// No description provided for @emotionScore.
  ///
  /// In ko, this message translates to:
  /// **'감정 점수'**
  String get emotionScore;

  /// No description provided for @keywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get keywords;

  /// No description provided for @empathyMessage.
  ///
  /// In ko, this message translates to:
  /// **'공감 메시지'**
  String get empathyMessage;

  /// No description provided for @actionItem.
  ///
  /// In ko, this message translates to:
  /// **'추천 행동'**
  String get actionItem;

  /// No description provided for @alertDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 삭제'**
  String get alertDeleteTitle;

  /// No description provided for @alertDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'정말로 이 일기를 삭제하시겠습니까?'**
  String get alertDeleteMessage;

  /// No description provided for @alertDeleteAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 일기 삭제'**
  String get alertDeleteAllTitle;

  /// No description provided for @alertDeleteAllMessage.
  ///
  /// In ko, this message translates to:
  /// **'정말로 모든 일기를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'**
  String get alertDeleteAllMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
