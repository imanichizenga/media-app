// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class StringsSw extends Strings {
  StringsSw([String locale = 'sw']) : super(locale);

  @override
  String get navHome => 'Nyumbani';

  @override
  String get navVideo => 'Video';

  @override
  String get navExplore => 'Gundua';

  @override
  String get navSaved => 'Hifadhi';

  @override
  String get navYou => 'Wewe';

  @override
  String get live => 'Mubashara';

  @override
  String get breaking => 'Habari za dharura';

  @override
  String get liveNow => 'Moja kwa moja';

  @override
  String get forYou => 'Kwa ajili yako';

  @override
  String get latest => 'Habari mpya';

  @override
  String get topStories => 'Habari kuu';

  @override
  String get videos => 'Video';

  @override
  String get shorts => 'Fupi';

  @override
  String get longVideos => 'Ndefu';

  @override
  String get more => 'Zaidi';

  @override
  String get moreTabs => 'Sehemu zaidi';

  @override
  String get earlierTabs => 'Sehemu za awali';

  @override
  String get all => 'Zote';

  @override
  String get gallery => 'Picha';

  @override
  String get opinion => 'Maoni';

  @override
  String get liveBlog => 'Taarifa za moja kwa moja';

  @override
  String photos(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'Picha #', one: 'Picha #');
    return '$_temp0';
  }

  @override
  String get sensitive => 'Picha zinazoweza kuhuzunisha';

  @override
  String get sensitiveShow => 'Tazama';

  @override
  String minutesRead(int n) {
    return 'Dakika $n kusoma';
  }

  @override
  String ago(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'zilizopita',
      one: 'iliyopita',
    );
    return 'dakika $n $_temp0';
  }

  @override
  String agoHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'zilizopita',
      one: 'iliyopita',
    );
    return 'saa $n $_temp0';
  }

  @override
  String published(String when) {
    return 'Imechapishwa $when';
  }

  @override
  String updated(String when) {
    return 'Imesasishwa $when';
  }

  @override
  String get updateNote => 'Sasisho';

  @override
  String get correction => 'Marekebisho';

  @override
  String get verified => 'Amethibitishwa';

  @override
  String get readAlso => 'Soma pia';

  @override
  String get nextStory => 'Habari inayofuata';

  @override
  String get share => 'Sambaza';

  @override
  String get save => 'Hifadhi';

  @override
  String get unsave => 'Ondoa kwenye hifadhi';

  @override
  String get savedDone => 'Imehifadhiwa. Inasomeka hata bila mtandao.';

  @override
  String get removed => 'Imeondolewa';

  @override
  String get undo => 'Rudisha';

  @override
  String get textSize => 'Ukubwa wa maandishi';

  @override
  String get textSizeSample => 'Habari njema husomeka kwa raha.';

  @override
  String get close => 'Funga';

  @override
  String get back => 'Rudi';

  @override
  String get openPost => 'Fungua chapisho';

  @override
  String get unsupported => 'Sehemu hii inahitaji toleo jipya la programu.';

  @override
  String get pinned => 'Imebandikwa';

  @override
  String updates(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Masasisho mapya #',
      one: 'Sasisho jipya #',
    );
    return '$_temp0';
  }

  @override
  String get liveEnded => 'Matangazo yamekwisha';

  @override
  String get play => 'Cheza';

  @override
  String get pause => 'Simamisha';

  @override
  String get mute => 'Zima sauti';

  @override
  String get unmute => 'Washa sauti';

  @override
  String get fullscreen => 'Skrini nzima';

  @override
  String get exitFullscreen => 'Toka skrini nzima';

  @override
  String position(String at, String total) {
    return '$at kati ya $total';
  }

  @override
  String get videoError => 'Video haikucheza';

  @override
  String get youtubePlay => 'Cheza video ya YouTube';

  @override
  String get watchFull => 'Tazama habari kamili';

  @override
  String get shortsEnd => 'Umetazama zote';

  @override
  String get shortsEndBody => 'Rudi baadaye kwa video mpya.';

  @override
  String get watchAgain => 'Tazama tena';

  @override
  String get poll => 'Kura';

  @override
  String get results => 'Matokeo';

  @override
  String get categories => 'Makundi';

  @override
  String get stories => 'Habari zinazoendelea';

  @override
  String get journalists => 'Waandishi';

  @override
  String storiesBy(String name) {
    return 'Habari za $name';
  }

  @override
  String get expertise => 'Ubobezi';

  @override
  String get savedTab => 'Zilizohifadhiwa';

  @override
  String get historyTab => 'Ulizosoma';

  @override
  String get clearHistory => 'Futa historia';

  @override
  String get clearHistoryConfirm => 'Historia yote ya kusoma itafutwa kwenye simu hii.';

  @override
  String get clear => 'Futa';

  @override
  String get cancel => 'Ghairi';

  @override
  String get availableOffline => 'Inasomeka bila mtandao';

  @override
  String get downloading => 'Inapakuliwa';

  @override
  String get savedEmptyTitle => 'Bado hujahifadhi habari';

  @override
  String get savedEmptyBody =>
      'Gusa alama ya kuhifadhi kwenye habari yoyote, na utaisoma hata bila mtandao.';

  @override
  String get savedEmptyAction => 'Tafuta cha kusoma';

  @override
  String get historyEmptyTitle => 'Historia yako iko wazi';

  @override
  String get historyEmptyBody => 'Habari utakazofungua zitaonekana hapa, kwenye simu hii tu.';

  @override
  String get feedEmptyTitle => 'Hakuna habari bado';

  @override
  String get feedEmptyBody => 'Habari mpya zitaonekana hapa.';

  @override
  String get errorTitle => 'Haikufunguka';

  @override
  String get errorBody => 'Kosa ni letu. Jaribu tena baada ya muda mfupi.';

  @override
  String get notFoundTitle => 'Habari hii haipo';

  @override
  String get notFoundBody => 'Huenda imehamishwa au imeondolewa.';

  @override
  String get goHome => 'Rudi nyumbani';

  @override
  String get retry => 'Jaribu tena';

  @override
  String get offlineTitle => 'Huna mtandao';

  @override
  String get offlineBody => 'Habari ulizohifadhi zinasomeka bila mtandao.';

  @override
  String get offlineAction => 'Fungua zilizohifadhiwa';

  @override
  String offlineBanner(String when) {
    return 'Huna mtandao. Unaona habari za $when.';
  }

  @override
  String get skip => 'Ruka';

  @override
  String get next => 'Endelea';

  @override
  String get start => 'Anza';

  @override
  String get welcomeTitle => 'Habari unazoziamini, popote ulipo.';

  @override
  String get welcomeBody =>
      'Habari zilizothibitishwa, matangazo ya moja kwa moja na video, kwa Kiswahili na Kiingereza.';

  @override
  String get languageTitle => 'Chagua lugha yako';

  @override
  String get languageBody => 'Unaweza kubadili wakati wowote.';

  @override
  String get topicsTitle => 'Unapenda habari gani?';

  @override
  String get topicsBody => 'Zinabaki kwenye simu yako.';

  @override
  String topicsChosen(int n) {
    return 'Umechagua $n';
  }

  @override
  String get language => 'Lugha';

  @override
  String get appearance => 'Mwonekano';

  @override
  String get schemeSystem => 'Kama simu';

  @override
  String get schemeLight => 'Mwanga';

  @override
  String get schemeDark => 'Giza';

  @override
  String get reading => 'Kusoma';

  @override
  String get dataSaver => 'Okoa data';

  @override
  String get dataSaverBody => 'Picha nyepesi, na video hazijichezi zenyewe.';

  @override
  String get topics => 'Mada zako';

  @override
  String get aboutSection => 'Kuhusu';

  @override
  String get linkAbout => 'Kuhusu sisi';

  @override
  String get linkEditorial => 'Sera ya uhariri';

  @override
  String get linkCorrections => 'Marekebisho';

  @override
  String get linkContact => 'Wasiliana nasi';

  @override
  String get linkPrivacy => 'Faragha';

  @override
  String get linkTerms => 'Masharti';

  @override
  String get licences => 'Leseni za programu huria';

  @override
  String version(String v) {
    return 'Toleo $v';
  }

  @override
  String get storage => 'Nafasi';

  @override
  String get clearCache => 'Futa picha na habari za muda';

  @override
  String get cacheCleared => 'Imefutwa';

  @override
  String get updateTitle => 'Toleo jipya linahitajika';

  @override
  String get updateBody => 'Toleo hili halitumiki tena. Sasisha uendelee kusoma.';

  @override
  String get updateAction => 'Sasisha';

  @override
  String get updateSoft => 'Kuna toleo jipya';

  @override
  String get later => 'Baadaye';

  @override
  String get maintenanceTitle => 'Tunarudi hivi punde';

  @override
  String counted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Habari #',
      one: 'Habari #',
    );
    return '$_temp0';
  }

  @override
  String imageOf(int n, int i) {
    return 'Picha $i kati ya $n';
  }

  @override
  String readingProgress(int n) {
    return 'Umesoma asilimia $n';
  }

  @override
  String get filterBy => 'Chuja';

  @override
  String get refreshed => 'Habari zimesasishwa';

  @override
  String get copyLink => 'Nakili kiungo';

  @override
  String get linkCopied => 'Kiungo kimenakiliwa';

  @override
  String get newStories => 'Kuna habari mpya';

  @override
  String get shareQuote => 'Sambaza nukuu';

  @override
  String get settingOn => 'Imewashwa';

  @override
  String get settingOff => 'Imezimwa';
}
