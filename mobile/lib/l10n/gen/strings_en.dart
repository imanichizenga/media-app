// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class StringsEn extends Strings {
  StringsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navVideo => 'Video';

  @override
  String get navExplore => 'Explore';

  @override
  String get navSaved => 'Saved';

  @override
  String get navYou => 'You';

  @override
  String get live => 'Live';

  @override
  String get breaking => 'Breaking news';

  @override
  String get liveNow => 'Live now';

  @override
  String get forYou => 'For you';

  @override
  String get latest => 'Latest';

  @override
  String get topStories => 'Top stories';

  @override
  String get videos => 'Videos';

  @override
  String get shorts => 'Shorts';

  @override
  String get longVideos => 'Videos';

  @override
  String get more => 'More';

  @override
  String get moreTabs => 'More sections';

  @override
  String get earlierTabs => 'Earlier sections';

  @override
  String get all => 'All';

  @override
  String get gallery => 'Pictures';

  @override
  String get opinion => 'Opinion';

  @override
  String get liveBlog => 'Live updates';

  @override
  String photos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# pictures',
      one: '# picture',
    );
    return '$_temp0';
  }

  @override
  String get sensitive => 'May be distressing';

  @override
  String get sensitiveShow => 'View';

  @override
  String minutesRead(int n) {
    return '$n min read';
  }

  @override
  String ago(int n) {
    return '${n}m ago';
  }

  @override
  String agoHours(int n) {
    return '${n}h ago';
  }

  @override
  String published(String when) {
    return 'Published $when';
  }

  @override
  String updated(String when) {
    return 'Updated $when';
  }

  @override
  String get updateNote => 'Update';

  @override
  String get correction => 'Correction';

  @override
  String get verified => 'Verified';

  @override
  String get readAlso => 'Read also';

  @override
  String get nextStory => 'Next story';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get unsave => 'Remove from saved';

  @override
  String get savedDone => 'Saved. You can read it offline.';

  @override
  String get removed => 'Removed';

  @override
  String get undo => 'Undo';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeSample => 'Good news reads with ease.';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get openPost => 'Open the post';

  @override
  String get unsupported => 'This part needs a newer version of the app.';

  @override
  String get pinned => 'Pinned';

  @override
  String updates(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# new updates',
      one: '# new update',
    );
    return '$_temp0';
  }

  @override
  String get liveEnded => 'Coverage has ended';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get fullscreen => 'Full screen';

  @override
  String get exitFullscreen => 'Exit full screen';

  @override
  String position(String at, String total) {
    return '$at of $total';
  }

  @override
  String get videoError => 'The video did not play';

  @override
  String get youtubePlay => 'Play the YouTube video';

  @override
  String get watchFull => 'Open the full story';

  @override
  String get shortsEnd => 'You have seen them all';

  @override
  String get shortsEndBody => 'Come back later for new ones.';

  @override
  String get watchAgain => 'Watch again';

  @override
  String get poll => 'Poll';

  @override
  String get results => 'Results';

  @override
  String get categories => 'Categories';

  @override
  String get stories => 'Developing stories';

  @override
  String get journalists => 'Journalists';

  @override
  String storiesBy(String name) {
    return 'Stories by $name';
  }

  @override
  String get expertise => 'Expertise';

  @override
  String get savedTab => 'Saved';

  @override
  String get historyTab => 'History';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryConfirm => 'All reading history on this phone will be removed.';

  @override
  String get clear => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String get availableOffline => 'Available offline';

  @override
  String get downloading => 'Downloading';

  @override
  String get savedEmptyTitle => 'Nothing saved yet';

  @override
  String get savedEmptyBody => 'Tap the bookmark on any story to read it later, even offline.';

  @override
  String get savedEmptyAction => 'Find something to read';

  @override
  String get historyEmptyTitle => 'Your history is empty';

  @override
  String get historyEmptyBody => 'Stories you open appear here, on this phone only.';

  @override
  String get feedEmptyTitle => 'No stories yet';

  @override
  String get feedEmptyBody => 'New stories will appear here.';

  @override
  String get errorTitle => 'That did not open';

  @override
  String get errorBody => 'The fault is ours. Please try again in a moment.';

  @override
  String get notFoundTitle => 'This story is not here';

  @override
  String get notFoundBody => 'It may have moved or been removed.';

  @override
  String get goHome => 'Go to home';

  @override
  String get retry => 'Try again';

  @override
  String get offlineTitle => 'You are offline';

  @override
  String get offlineBody => 'The stories you saved can be read without a connection.';

  @override
  String get offlineAction => 'Open saved stories';

  @override
  String offlineBanner(String when) {
    return 'You are offline. Showing stories from $when.';
  }

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Continue';

  @override
  String get start => 'Get started';

  @override
  String get welcomeTitle => 'News you can trust, wherever you are.';

  @override
  String get welcomeBody => 'Verified stories, live coverage and video, in Swahili and English.';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageBody => 'You can change it at any time.';

  @override
  String get topicsTitle => 'What do you like to read?';

  @override
  String get topicsBody => 'They stay on your phone.';

  @override
  String topicsChosen(int n) {
    return '$n chosen';
  }

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get schemeSystem => 'As the phone';

  @override
  String get schemeLight => 'Light';

  @override
  String get schemeDark => 'Dark';

  @override
  String get reading => 'Reading';

  @override
  String get dataSaver => 'Data saver';

  @override
  String get dataSaverBody => 'Lighter pictures, and videos do not play by themselves.';

  @override
  String get topics => 'Your topics';

  @override
  String get aboutSection => 'About';

  @override
  String get linkAbout => 'About us';

  @override
  String get linkEditorial => 'Editorial policy';

  @override
  String get linkCorrections => 'Corrections';

  @override
  String get linkContact => 'Contact us';

  @override
  String get linkPrivacy => 'Privacy';

  @override
  String get linkTerms => 'Terms';

  @override
  String get licences => 'Open source licences';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get storage => 'Storage';

  @override
  String get clearCache => 'Clear cached pictures and stories';

  @override
  String get cacheCleared => 'Cleared';

  @override
  String get updateTitle => 'Please update the app';

  @override
  String get updateBody => 'This version is no longer supported. Update to keep reading.';

  @override
  String get updateAction => 'Update';

  @override
  String get updateSoft => 'A new version is available';

  @override
  String get later => 'Later';

  @override
  String get maintenanceTitle => 'We will be right back';

  @override
  String counted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# stories',
      one: '# story',
    );
    return '$_temp0';
  }

  @override
  String imageOf(int n, int i) {
    return 'Picture $i of $n';
  }

  @override
  String readingProgress(int n) {
    return '$n percent read';
  }

  @override
  String get filterBy => 'Filter';

  @override
  String get refreshed => 'Stories refreshed';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get newStories => 'New stories';

  @override
  String get shareQuote => 'Share quote';

  @override
  String get settingOn => 'On';

  @override
  String get settingOff => 'Off';
}
