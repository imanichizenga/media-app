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

  @override
  String get skipToNews => 'Ruka hadi habari';

  @override
  String get olderStories => 'Habari za awali';

  @override
  String get openInApp => 'Soma kwa urahisi kwenye programu';

  @override
  String get open => 'Fungua';

  @override
  String get search => 'Tafuta';

  @override
  String get searchSoon => 'Chagua kundi usome habari zake.';

  @override
  String get serverErrorTitle => 'Hitilafu imetokea';

  @override
  String get legal => 'Kurasa za tovuti';

  @override
  String get correctionsPage => 'Marekebisho yetu';

  @override
  String get publishedAt => 'Imechapishwa';

  @override
  String get updatedAt => 'Imesasishwa';

  @override
  String get authorStories => 'Habari zake';

  @override
  String pageOf(int n) {
    return 'Ukurasa wa $n';
  }

  @override
  String get places => 'Sehemu kuu';

  @override
  String get savedEmptyWeb =>
      'Gusa alama ya kuhifadhi kwenye habari yoyote. Itabaki kwenye kifaa hiki.';

  @override
  String get offlineNote => 'Huna mtandao.';

  @override
  String get searchLabel => 'Tafuta habari';

  @override
  String get searchPlaceholder => 'Habari, mahali, mtu au mwandishi';

  @override
  String get searchGo => 'Tafuta';

  @override
  String get searchClear => 'Futa maneno';

  @override
  String searchResultsFor(String v) {
    return 'Matokeo ya “$v”';
  }

  @override
  String searchCount(int n) {
    return 'Habari $n zimepatikana';
  }

  @override
  String searchCountMany(int n) {
    return 'Zaidi ya habari $n zimepatikana';
  }

  @override
  String get searchNoneTitle => 'Hakuna habari zinazolingana';

  @override
  String get searchNoneBody => 'Jaribu neno jingine, angalia tahajia, au ondoa vichujio.';

  @override
  String get searchRecent => 'Ulizotafuta karibuni';

  @override
  String get searchClearRecent => 'Futa ulizotafuta';

  @override
  String get searchFilters => 'Vichujio';

  @override
  String get searchSort => 'Mpangilio';

  @override
  String get searchSortBest => 'Zinazolingana zaidi';

  @override
  String get searchSortNewest => 'Mpya kwanza';

  @override
  String get searchType => 'Aina';

  @override
  String get searchTypeAll => 'Zote';

  @override
  String get searchTypeStories => 'Habari';

  @override
  String get searchTypeVideos => 'Video';

  @override
  String get searchTypeLive => 'Mubashara';

  @override
  String get searchTypeGalleries => 'Picha';

  @override
  String get searchWhen => 'Lini';

  @override
  String get searchAnyTime => 'Wakati wowote';

  @override
  String get searchPastDay => 'Saa 24 zilizopita';

  @override
  String get searchPastWeek => 'Wiki iliyopita';

  @override
  String get searchPastMonth => 'Mwezi uliopita';

  @override
  String get searchPastYear => 'Mwaka uliopita';

  @override
  String get searchMore => 'Matokeo zaidi';

  @override
  String get searchUnavailable =>
      'Utafutaji haupatikani kwa sasa. Jaribu tena baada ya muda mfupi.';

  @override
  String get searchSections => 'Au chagua kundi';

  @override
  String seeAllIn(String name) {
    return 'Habari zote za $name';
  }

  @override
  String get seeAll => 'Ona zote';

  @override
  String get earlierStories => 'Habari zilizotangulia';

  @override
  String get moreStories => 'Habari zaidi';

  @override
  String savedCount(int n) {
    return 'Habari $n zimehifadhiwa';
  }

  @override
  String breakingOf(String at, String total) {
    return '$at kati ya $total';
  }

  @override
  String get breakingPause => 'Simamisha habari za dharura';

  @override
  String get breakingPlay => 'Endelea na habari za dharura';

  @override
  String get savedDoneWeb => 'Imewekwa kwenye Hifadhi.';

  @override
  String get savedUndone => 'Imeondolewa kwenye Hifadhi.';

  @override
  String get signIn => 'Ingia';

  @override
  String get signInTitle => 'Ingia au jisajili';

  @override
  String get signInLead =>
      'Akaunti moja kwa tovuti na programu: penda, toa maoni na hifadhi habari zako popote.';

  @override
  String get signInToLike => 'Ingia ili kupenda habari hii';

  @override
  String get signInToComment => 'Ingia ili kutoa maoni';

  @override
  String get signInToSave => 'Ingia ili kuhifadhi kwenye akaunti yako';

  @override
  String get signInToFollow => 'Ingia ili kufuatilia';

  @override
  String get phoneLabel => 'Namba ya simu';

  @override
  String get phoneHint => 'Tutakutumia msimbo wa tarakimu 6 kwa SMS.';

  @override
  String get sendCode => 'Tuma msimbo';

  @override
  String get orWith => 'au endelea na';

  @override
  String get withGoogle => 'Endelea na Google';

  @override
  String get withApple => 'Endelea na Apple';

  @override
  String get codeTitle => 'Weka msimbo';

  @override
  String codeLead(String v) {
    return 'Tumetuma msimbo kwa $v.';
  }

  @override
  String get codeLabel => 'Msimbo wa tarakimu 6';

  @override
  String codeResendIn(int n) {
    return 'Tuma tena baada ya sekunde $n';
  }

  @override
  String get codeResend => 'Tuma msimbo tena';

  @override
  String get codeChangePhone => 'Badilisha namba';

  @override
  String codeLocal(String v) {
    return 'Majaribio: msimbo wako ni $v';
  }

  @override
  String get verify => 'Thibitisha';

  @override
  String get welcomeName => 'Karibu! Tukuiteje?';

  @override
  String get nameLabel => 'Jina lako';

  @override
  String get nameHint =>
      'Litaonekana kwenye maoni yako na kwenye orodha za waliosoma habari (unaweza kulificha).';

  @override
  String get acceptTerms => 'Nakubali miongozo ya jumuiya na sera ya faragha';

  @override
  String get continueOn => 'Endelea';

  @override
  String get signOut => 'Toka';

  @override
  String get accountTitle => 'Akaunti yangu';

  @override
  String get editName => 'Badilisha jina';

  @override
  String get saveChanges => 'Hifadhi mabadiliko';

  @override
  String get downloadData => 'Pakua data yangu';

  @override
  String get deleteAccount => 'Futa akaunti';

  @override
  String get deleteConfirm =>
      'Akaunti itafutwa baada ya siku 30. Ukiingia tena kabla ya hapo, itabaki. Endelea?';

  @override
  String get joinTitle => 'Jiunge na wasomaji wetu';

  @override
  String get joinPoints => 'Penda habari · Toa maoni · Hifadhi kwenye vifaa vyote';

  @override
  String get likeStory => 'Penda';

  @override
  String likesCount(int n) {
    return 'Wamependa $n';
  }

  @override
  String commentsCount(int n) {
    return 'Maoni $n';
  }

  @override
  String get comments => 'Maoni';

  @override
  String get commentsNone => 'Bado hakuna maoni. Kuwa wa kwanza.';

  @override
  String get commentsClosed => 'Maoni yamefungwa kwa habari hii.';

  @override
  String get commentPlaceholder => 'Andika maoni yako…';

  @override
  String commentReplyTo(String name) {
    return 'Jibu $name';
  }

  @override
  String get commentSend => 'Tuma';

  @override
  String get commentReply => 'Jibu';

  @override
  String get commentDelete => 'Futa';

  @override
  String get commentHeld => 'Inasubiri idhini';

  @override
  String get commentWriter => 'Mwandishi';

  @override
  String commentReplies(int n) {
    return 'Ona majibu $n';
  }

  @override
  String get commentsMore => 'Maoni zaidi';

  @override
  String get commentSlow => 'Subiri kidogo kabla ya maoni mengine.';

  @override
  String get commentFailed => 'Maoni hayakutumwa. Jaribu tena.';

  @override
  String get followTopic => 'Fuatilia';

  @override
  String get followingTopic => 'Unafuatilia';

  @override
  String get errorTryAgain => 'Kuna tatizo. Jaribu tena.';

  @override
  String get errorPhone => 'Namba hii si sahihi. Mfano: 0712 345 678';

  @override
  String get errorCountry => 'Hatuwezi kutuma SMS kwa nchi hii.';

  @override
  String get errorWait => 'Subiri kidogo kisha ujaribu tena.';

  @override
  String errorCodeWrong(int n) {
    return 'Msimbo si sahihi. Majaribio $n yamebaki.';
  }

  @override
  String get errorCodeExpired => 'Msimbo umeisha muda. Omba mpya.';

  @override
  String get errorSmsDown => 'SMS haziwezi kutumwa sasa. Jaribu baadaye.';

  @override
  String signedInToast(String name) {
    return 'Karibu, $name!';
  }

  @override
  String get signedOutToast => 'Umetoka.';

  @override
  String get signInFailed => 'Kuingia hakukufaulu. Jaribu tena.';

  @override
  String logoAlt(String name) {
    return 'Nembo ya $name';
  }

  @override
  String viewsCount(int n) {
    return 'Imesomwa mara $n';
  }

  @override
  String readersCount(int n) {
    return 'Wasomaji $n';
  }

  @override
  String get readersTitle => 'Waliosoma habari hii';

  @override
  String readersGuests(int n) {
    return 'na wageni $n wasiojisajili';
  }

  @override
  String get readersNone => 'Bado hakuna msomaji aliyejisajili.';

  @override
  String get readersPrivate => 'Ficha jina langu kwenye orodha za wasomaji';

  @override
  String get notifications => 'Arifa';

  @override
  String get notifyTurnOn => 'Washa arifa za habari mpya';

  @override
  String get notifyTurnOff => 'Zima arifa za habari mpya';

  @override
  String get notifyOn => 'Arifa zimewashwa: utaambiwa kila habari mpya.';

  @override
  String get notifyOff => 'Arifa zimezimwa.';

  @override
  String get notifyBlocked =>
      'Arifa zimezuiwa kwenye kivinjari hiki. Ziruhusu kwenye mipangilio ya tovuti.';

  @override
  String get notifyUnsupported =>
      'Kivinjari hiki hakionyeshi arifa. Kwenye iPhone, weka tovuti kwenye skrini ya mwanzo kwanza.';

  @override
  String get storiesRail => 'Habari za sasa';

  @override
  String get seenStory => 'Umeshaiona';

  @override
  String get searchOpen => 'Tafuta habari';

  @override
  String get profileTitle => 'Wasifu wako';

  @override
  String get fullName => 'Jina kamili';

  @override
  String get username => 'Jina la mtumiaji';

  @override
  String get usernameHint => 'Herufi, namba au _ ; 3 hadi 30.';

  @override
  String get bio => 'Kuhusu wewe';

  @override
  String get bioHint => 'Sentensi moja au mbili, hadi herufi 160.';

  @override
  String get email => 'Barua pepe';

  @override
  String get emailHint => 'Kwa mawasiliano tu; haitumiki kuingia.';

  @override
  String get profileSaved => 'Wasifu umehifadhiwa.';

  @override
  String get usernameTaken => 'Jina hili limeshachukuliwa.';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get accountActions => 'Akaunti';

  @override
  String memberSince(String v) {
    return 'Msomaji tangu $v';
  }

  @override
  String get addBio => 'Ongeza maelezo mafupi kukuhusu';
}
