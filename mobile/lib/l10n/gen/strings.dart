import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_en.dart';
import 'strings_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Strings
/// returned by `Strings.of(context)`.
///
/// Applications need to include `Strings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Strings.localizationsDelegates,
///   supportedLocales: Strings.supportedLocales,
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
/// be consistent with the languages listed in the Strings.supportedLocales
/// property.
abstract class Strings {
  Strings(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Strings of(BuildContext context) {
    return Localizations.of<Strings>(context, Strings)!;
  }

  static const LocalizationsDelegate<Strings> delegate = _StringsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('sw'), Locale('en')];

  /// No description provided for @navHome.
  ///
  /// In sw, this message translates to:
  /// **'Nyumbani'**
  String get navHome;

  /// No description provided for @navVideo.
  ///
  /// In sw, this message translates to:
  /// **'Video'**
  String get navVideo;

  /// No description provided for @navExplore.
  ///
  /// In sw, this message translates to:
  /// **'Gundua'**
  String get navExplore;

  /// No description provided for @navSaved.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get navSaved;

  /// No description provided for @navYou.
  ///
  /// In sw, this message translates to:
  /// **'Wewe'**
  String get navYou;

  /// No description provided for @live.
  ///
  /// In sw, this message translates to:
  /// **'Mubashara'**
  String get live;

  /// No description provided for @breaking.
  ///
  /// In sw, this message translates to:
  /// **'Habari za dharura'**
  String get breaking;

  /// No description provided for @liveNow.
  ///
  /// In sw, this message translates to:
  /// **'Moja kwa moja'**
  String get liveNow;

  /// No description provided for @forYou.
  ///
  /// In sw, this message translates to:
  /// **'Kwa ajili yako'**
  String get forYou;

  /// No description provided for @latest.
  ///
  /// In sw, this message translates to:
  /// **'Habari mpya'**
  String get latest;

  /// No description provided for @topStories.
  ///
  /// In sw, this message translates to:
  /// **'Habari kuu'**
  String get topStories;

  /// No description provided for @videos.
  ///
  /// In sw, this message translates to:
  /// **'Video'**
  String get videos;

  /// No description provided for @shorts.
  ///
  /// In sw, this message translates to:
  /// **'Fupi'**
  String get shorts;

  /// No description provided for @longVideos.
  ///
  /// In sw, this message translates to:
  /// **'Ndefu'**
  String get longVideos;

  /// No description provided for @more.
  ///
  /// In sw, this message translates to:
  /// **'Zaidi'**
  String get more;

  /// No description provided for @moreTabs.
  ///
  /// In sw, this message translates to:
  /// **'Sehemu zaidi'**
  String get moreTabs;

  /// No description provided for @earlierTabs.
  ///
  /// In sw, this message translates to:
  /// **'Sehemu za awali'**
  String get earlierTabs;

  /// No description provided for @all.
  ///
  /// In sw, this message translates to:
  /// **'Zote'**
  String get all;

  /// No description provided for @gallery.
  ///
  /// In sw, this message translates to:
  /// **'Picha'**
  String get gallery;

  /// No description provided for @opinion.
  ///
  /// In sw, this message translates to:
  /// **'Maoni'**
  String get opinion;

  /// No description provided for @liveBlog.
  ///
  /// In sw, this message translates to:
  /// **'Taarifa za moja kwa moja'**
  String get liveBlog;

  /// No description provided for @photos.
  ///
  /// In sw, this message translates to:
  /// **'{n, plural, one {Picha #} other {Picha #}}'**
  String photos(int n);

  /// No description provided for @sensitive.
  ///
  /// In sw, this message translates to:
  /// **'Picha zinazoweza kuhuzunisha'**
  String get sensitive;

  /// No description provided for @sensitiveShow.
  ///
  /// In sw, this message translates to:
  /// **'Tazama'**
  String get sensitiveShow;

  /// No description provided for @minutesRead.
  ///
  /// In sw, this message translates to:
  /// **'Dakika {n} kusoma'**
  String minutesRead(int n);

  /// No description provided for @ago.
  ///
  /// In sw, this message translates to:
  /// **'dakika {n} {n, plural, one {iliyopita} other {zilizopita}}'**
  String ago(int n);

  /// No description provided for @agoHours.
  ///
  /// In sw, this message translates to:
  /// **'saa {n} {n, plural, one {iliyopita} other {zilizopita}}'**
  String agoHours(int n);

  /// No description provided for @published.
  ///
  /// In sw, this message translates to:
  /// **'Imechapishwa {when}'**
  String published(String when);

  /// No description provided for @updated.
  ///
  /// In sw, this message translates to:
  /// **'Imesasishwa {when}'**
  String updated(String when);

  /// No description provided for @updateNote.
  ///
  /// In sw, this message translates to:
  /// **'Sasisho'**
  String get updateNote;

  /// No description provided for @correction.
  ///
  /// In sw, this message translates to:
  /// **'Marekebisho'**
  String get correction;

  /// No description provided for @verified.
  ///
  /// In sw, this message translates to:
  /// **'Amethibitishwa'**
  String get verified;

  /// No description provided for @readAlso.
  ///
  /// In sw, this message translates to:
  /// **'Soma pia'**
  String get readAlso;

  /// No description provided for @nextStory.
  ///
  /// In sw, this message translates to:
  /// **'Habari inayofuata'**
  String get nextStory;

  /// No description provided for @share.
  ///
  /// In sw, this message translates to:
  /// **'Sambaza'**
  String get share;

  /// No description provided for @save.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get save;

  /// No description provided for @unsave.
  ///
  /// In sw, this message translates to:
  /// **'Ondoa kwenye hifadhi'**
  String get unsave;

  /// No description provided for @savedDone.
  ///
  /// In sw, this message translates to:
  /// **'Imehifadhiwa. Inasomeka hata bila mtandao.'**
  String get savedDone;

  /// No description provided for @removed.
  ///
  /// In sw, this message translates to:
  /// **'Imeondolewa'**
  String get removed;

  /// No description provided for @undo.
  ///
  /// In sw, this message translates to:
  /// **'Rudisha'**
  String get undo;

  /// No description provided for @textSize.
  ///
  /// In sw, this message translates to:
  /// **'Ukubwa wa maandishi'**
  String get textSize;

  /// No description provided for @textSizeSample.
  ///
  /// In sw, this message translates to:
  /// **'Habari njema husomeka kwa raha.'**
  String get textSizeSample;

  /// No description provided for @close.
  ///
  /// In sw, this message translates to:
  /// **'Funga'**
  String get close;

  /// No description provided for @back.
  ///
  /// In sw, this message translates to:
  /// **'Rudi'**
  String get back;

  /// No description provided for @openPost.
  ///
  /// In sw, this message translates to:
  /// **'Fungua chapisho'**
  String get openPost;

  /// No description provided for @unsupported.
  ///
  /// In sw, this message translates to:
  /// **'Sehemu hii inahitaji toleo jipya la programu.'**
  String get unsupported;

  /// No description provided for @pinned.
  ///
  /// In sw, this message translates to:
  /// **'Imebandikwa'**
  String get pinned;

  /// No description provided for @updates.
  ///
  /// In sw, this message translates to:
  /// **'{n, plural, one {Sasisho jipya #} other {Masasisho mapya #}}'**
  String updates(int n);

  /// No description provided for @liveEnded.
  ///
  /// In sw, this message translates to:
  /// **'Matangazo yamekwisha'**
  String get liveEnded;

  /// No description provided for @play.
  ///
  /// In sw, this message translates to:
  /// **'Cheza'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In sw, this message translates to:
  /// **'Simamisha'**
  String get pause;

  /// No description provided for @mute.
  ///
  /// In sw, this message translates to:
  /// **'Zima sauti'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In sw, this message translates to:
  /// **'Washa sauti'**
  String get unmute;

  /// No description provided for @fullscreen.
  ///
  /// In sw, this message translates to:
  /// **'Skrini nzima'**
  String get fullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In sw, this message translates to:
  /// **'Toka skrini nzima'**
  String get exitFullscreen;

  /// No description provided for @position.
  ///
  /// In sw, this message translates to:
  /// **'{at} kati ya {total}'**
  String position(String at, String total);

  /// No description provided for @videoError.
  ///
  /// In sw, this message translates to:
  /// **'Video haikucheza'**
  String get videoError;

  /// No description provided for @youtubePlay.
  ///
  /// In sw, this message translates to:
  /// **'Cheza video ya YouTube'**
  String get youtubePlay;

  /// No description provided for @watchFull.
  ///
  /// In sw, this message translates to:
  /// **'Tazama habari kamili'**
  String get watchFull;

  /// No description provided for @shortsEnd.
  ///
  /// In sw, this message translates to:
  /// **'Umetazama zote'**
  String get shortsEnd;

  /// No description provided for @shortsEndBody.
  ///
  /// In sw, this message translates to:
  /// **'Rudi baadaye kwa video mpya.'**
  String get shortsEndBody;

  /// No description provided for @watchAgain.
  ///
  /// In sw, this message translates to:
  /// **'Tazama tena'**
  String get watchAgain;

  /// No description provided for @poll.
  ///
  /// In sw, this message translates to:
  /// **'Kura'**
  String get poll;

  /// No description provided for @results.
  ///
  /// In sw, this message translates to:
  /// **'Matokeo'**
  String get results;

  /// No description provided for @categories.
  ///
  /// In sw, this message translates to:
  /// **'Makundi'**
  String get categories;

  /// No description provided for @stories.
  ///
  /// In sw, this message translates to:
  /// **'Habari zinazoendelea'**
  String get stories;

  /// No description provided for @journalists.
  ///
  /// In sw, this message translates to:
  /// **'Waandishi'**
  String get journalists;

  /// No description provided for @storiesBy.
  ///
  /// In sw, this message translates to:
  /// **'Habari za {name}'**
  String storiesBy(String name);

  /// No description provided for @expertise.
  ///
  /// In sw, this message translates to:
  /// **'Ubobezi'**
  String get expertise;

  /// No description provided for @savedTab.
  ///
  /// In sw, this message translates to:
  /// **'Zilizohifadhiwa'**
  String get savedTab;

  /// No description provided for @historyTab.
  ///
  /// In sw, this message translates to:
  /// **'Ulizosoma'**
  String get historyTab;

  /// No description provided for @clearHistory.
  ///
  /// In sw, this message translates to:
  /// **'Futa historia'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In sw, this message translates to:
  /// **'Historia yote ya kusoma itafutwa kwenye simu hii.'**
  String get clearHistoryConfirm;

  /// No description provided for @clear.
  ///
  /// In sw, this message translates to:
  /// **'Futa'**
  String get clear;

  /// No description provided for @cancel.
  ///
  /// In sw, this message translates to:
  /// **'Ghairi'**
  String get cancel;

  /// No description provided for @availableOffline.
  ///
  /// In sw, this message translates to:
  /// **'Inasomeka bila mtandao'**
  String get availableOffline;

  /// No description provided for @downloading.
  ///
  /// In sw, this message translates to:
  /// **'Inapakuliwa'**
  String get downloading;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In sw, this message translates to:
  /// **'Bado hujahifadhi habari'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In sw, this message translates to:
  /// **'Gusa alama ya kuhifadhi kwenye habari yoyote, na utaisoma hata bila mtandao.'**
  String get savedEmptyBody;

  /// No description provided for @savedEmptyAction.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta cha kusoma'**
  String get savedEmptyAction;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In sw, this message translates to:
  /// **'Historia yako iko wazi'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In sw, this message translates to:
  /// **'Habari utakazofungua zitaonekana hapa, kwenye simu hii tu.'**
  String get historyEmptyBody;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna habari bado'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In sw, this message translates to:
  /// **'Habari mpya zitaonekana hapa.'**
  String get feedEmptyBody;

  /// No description provided for @errorTitle.
  ///
  /// In sw, this message translates to:
  /// **'Haikufunguka'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In sw, this message translates to:
  /// **'Kosa ni letu. Jaribu tena baada ya muda mfupi.'**
  String get errorBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In sw, this message translates to:
  /// **'Habari hii haipo'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In sw, this message translates to:
  /// **'Huenda imehamishwa au imeondolewa.'**
  String get notFoundBody;

  /// No description provided for @goHome.
  ///
  /// In sw, this message translates to:
  /// **'Rudi nyumbani'**
  String get goHome;

  /// No description provided for @retry.
  ///
  /// In sw, this message translates to:
  /// **'Jaribu tena'**
  String get retry;

  /// No description provided for @offlineTitle.
  ///
  /// In sw, this message translates to:
  /// **'Huna mtandao'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In sw, this message translates to:
  /// **'Habari ulizohifadhi zinasomeka bila mtandao.'**
  String get offlineBody;

  /// No description provided for @offlineAction.
  ///
  /// In sw, this message translates to:
  /// **'Fungua zilizohifadhiwa'**
  String get offlineAction;

  /// No description provided for @offlineBanner.
  ///
  /// In sw, this message translates to:
  /// **'Huna mtandao. Unaona habari za {when}.'**
  String offlineBanner(String when);

  /// No description provided for @skip.
  ///
  /// In sw, this message translates to:
  /// **'Ruka'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In sw, this message translates to:
  /// **'Endelea'**
  String get next;

  /// No description provided for @start.
  ///
  /// In sw, this message translates to:
  /// **'Anza'**
  String get start;

  /// No description provided for @welcomeTitle.
  ///
  /// In sw, this message translates to:
  /// **'Habari unazoziamini, popote ulipo.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In sw, this message translates to:
  /// **'Habari zilizothibitishwa, matangazo ya moja kwa moja na video, kwa Kiswahili na Kiingereza.'**
  String get welcomeBody;

  /// No description provided for @languageTitle.
  ///
  /// In sw, this message translates to:
  /// **'Chagua lugha yako'**
  String get languageTitle;

  /// No description provided for @languageBody.
  ///
  /// In sw, this message translates to:
  /// **'Unaweza kubadili wakati wowote.'**
  String get languageBody;

  /// No description provided for @topicsTitle.
  ///
  /// In sw, this message translates to:
  /// **'Unapenda habari gani?'**
  String get topicsTitle;

  /// No description provided for @topicsBody.
  ///
  /// In sw, this message translates to:
  /// **'Zinabaki kwenye simu yako.'**
  String get topicsBody;

  /// No description provided for @topicsChosen.
  ///
  /// In sw, this message translates to:
  /// **'Umechagua {n}'**
  String topicsChosen(int n);

  /// No description provided for @language.
  ///
  /// In sw, this message translates to:
  /// **'Lugha'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In sw, this message translates to:
  /// **'Mwonekano'**
  String get appearance;

  /// No description provided for @schemeSystem.
  ///
  /// In sw, this message translates to:
  /// **'Kama simu'**
  String get schemeSystem;

  /// No description provided for @schemeLight.
  ///
  /// In sw, this message translates to:
  /// **'Mwanga'**
  String get schemeLight;

  /// No description provided for @schemeDark.
  ///
  /// In sw, this message translates to:
  /// **'Giza'**
  String get schemeDark;

  /// No description provided for @reading.
  ///
  /// In sw, this message translates to:
  /// **'Kusoma'**
  String get reading;

  /// No description provided for @dataSaver.
  ///
  /// In sw, this message translates to:
  /// **'Okoa data'**
  String get dataSaver;

  /// No description provided for @dataSaverBody.
  ///
  /// In sw, this message translates to:
  /// **'Picha nyepesi, na video hazijichezi zenyewe.'**
  String get dataSaverBody;

  /// No description provided for @topics.
  ///
  /// In sw, this message translates to:
  /// **'Mada zako'**
  String get topics;

  /// No description provided for @aboutSection.
  ///
  /// In sw, this message translates to:
  /// **'Kuhusu'**
  String get aboutSection;

  /// No description provided for @linkAbout.
  ///
  /// In sw, this message translates to:
  /// **'Kuhusu sisi'**
  String get linkAbout;

  /// No description provided for @linkEditorial.
  ///
  /// In sw, this message translates to:
  /// **'Sera ya uhariri'**
  String get linkEditorial;

  /// No description provided for @linkCorrections.
  ///
  /// In sw, this message translates to:
  /// **'Marekebisho'**
  String get linkCorrections;

  /// No description provided for @linkContact.
  ///
  /// In sw, this message translates to:
  /// **'Wasiliana nasi'**
  String get linkContact;

  /// No description provided for @linkPrivacy.
  ///
  /// In sw, this message translates to:
  /// **'Faragha'**
  String get linkPrivacy;

  /// No description provided for @linkTerms.
  ///
  /// In sw, this message translates to:
  /// **'Masharti'**
  String get linkTerms;

  /// No description provided for @licences.
  ///
  /// In sw, this message translates to:
  /// **'Leseni za programu huria'**
  String get licences;

  /// No description provided for @version.
  ///
  /// In sw, this message translates to:
  /// **'Toleo {v}'**
  String version(String v);

  /// No description provided for @storage.
  ///
  /// In sw, this message translates to:
  /// **'Nafasi'**
  String get storage;

  /// No description provided for @clearCache.
  ///
  /// In sw, this message translates to:
  /// **'Futa picha na habari za muda'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In sw, this message translates to:
  /// **'Imefutwa'**
  String get cacheCleared;

  /// No description provided for @updateTitle.
  ///
  /// In sw, this message translates to:
  /// **'Toleo jipya linahitajika'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In sw, this message translates to:
  /// **'Toleo hili halitumiki tena. Sasisha uendelee kusoma.'**
  String get updateBody;

  /// No description provided for @updateAction.
  ///
  /// In sw, this message translates to:
  /// **'Sasisha'**
  String get updateAction;

  /// No description provided for @updateSoft.
  ///
  /// In sw, this message translates to:
  /// **'Kuna toleo jipya'**
  String get updateSoft;

  /// No description provided for @later.
  ///
  /// In sw, this message translates to:
  /// **'Baadaye'**
  String get later;

  /// No description provided for @maintenanceTitle.
  ///
  /// In sw, this message translates to:
  /// **'Tunarudi hivi punde'**
  String get maintenanceTitle;

  /// No description provided for @counted.
  ///
  /// In sw, this message translates to:
  /// **'{n, plural, one {Habari #} other {Habari #}}'**
  String counted(int n);

  /// No description provided for @imageOf.
  ///
  /// In sw, this message translates to:
  /// **'Picha {i} kati ya {n}'**
  String imageOf(int n, int i);

  /// No description provided for @readingProgress.
  ///
  /// In sw, this message translates to:
  /// **'Umesoma asilimia {n}'**
  String readingProgress(int n);

  /// No description provided for @filterBy.
  ///
  /// In sw, this message translates to:
  /// **'Chuja'**
  String get filterBy;

  /// No description provided for @refreshed.
  ///
  /// In sw, this message translates to:
  /// **'Habari zimesasishwa'**
  String get refreshed;

  /// No description provided for @copyLink.
  ///
  /// In sw, this message translates to:
  /// **'Nakili kiungo'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In sw, this message translates to:
  /// **'Kiungo kimenakiliwa'**
  String get linkCopied;

  /// No description provided for @newStories.
  ///
  /// In sw, this message translates to:
  /// **'Kuna habari mpya'**
  String get newStories;

  /// No description provided for @shareQuote.
  ///
  /// In sw, this message translates to:
  /// **'Sambaza nukuu'**
  String get shareQuote;

  /// No description provided for @settingOn.
  ///
  /// In sw, this message translates to:
  /// **'Imewashwa'**
  String get settingOn;

  /// No description provided for @settingOff.
  ///
  /// In sw, this message translates to:
  /// **'Imezimwa'**
  String get settingOff;

  /// No description provided for @skipToNews.
  ///
  /// In sw, this message translates to:
  /// **'Ruka hadi habari'**
  String get skipToNews;

  /// No description provided for @olderStories.
  ///
  /// In sw, this message translates to:
  /// **'Habari za awali'**
  String get olderStories;

  /// No description provided for @openInApp.
  ///
  /// In sw, this message translates to:
  /// **'Soma kwa urahisi kwenye programu'**
  String get openInApp;

  /// No description provided for @open.
  ///
  /// In sw, this message translates to:
  /// **'Fungua'**
  String get open;

  /// No description provided for @search.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta'**
  String get search;

  /// No description provided for @searchSoon.
  ///
  /// In sw, this message translates to:
  /// **'Chagua kundi usome habari zake.'**
  String get searchSoon;

  /// No description provided for @serverErrorTitle.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu imetokea'**
  String get serverErrorTitle;

  /// No description provided for @legal.
  ///
  /// In sw, this message translates to:
  /// **'Kurasa za tovuti'**
  String get legal;

  /// No description provided for @correctionsPage.
  ///
  /// In sw, this message translates to:
  /// **'Marekebisho yetu'**
  String get correctionsPage;

  /// No description provided for @publishedAt.
  ///
  /// In sw, this message translates to:
  /// **'Imechapishwa'**
  String get publishedAt;

  /// No description provided for @updatedAt.
  ///
  /// In sw, this message translates to:
  /// **'Imesasishwa'**
  String get updatedAt;

  /// No description provided for @authorStories.
  ///
  /// In sw, this message translates to:
  /// **'Habari zake'**
  String get authorStories;

  /// No description provided for @pageOf.
  ///
  /// In sw, this message translates to:
  /// **'Ukurasa wa {n}'**
  String pageOf(int n);

  /// No description provided for @places.
  ///
  /// In sw, this message translates to:
  /// **'Sehemu kuu'**
  String get places;

  /// No description provided for @savedEmptyWeb.
  ///
  /// In sw, this message translates to:
  /// **'Gusa alama ya kuhifadhi kwenye habari yoyote. Itabaki kwenye kifaa hiki.'**
  String get savedEmptyWeb;

  /// No description provided for @offlineNote.
  ///
  /// In sw, this message translates to:
  /// **'Huna mtandao.'**
  String get offlineNote;
}

class _StringsDelegate extends LocalizationsDelegate<Strings> {
  const _StringsDelegate();

  @override
  Future<Strings> load(Locale locale) {
    return SynchronousFuture<Strings>(lookupStrings(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_StringsDelegate old) => false;
}

Strings lookupStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return StringsEn();
    case 'sw':
      return StringsSw();
  }

  throw FlutterError(
    'Strings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
