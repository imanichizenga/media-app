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

  @override
  String get skipToNews => 'Skip to the news';

  @override
  String get olderStories => 'Older stories';

  @override
  String get openInApp => 'Read more easily in the app';

  @override
  String get open => 'Open';

  @override
  String get search => 'Search';

  @override
  String get searchSoon => 'Choose a section to read its stories.';

  @override
  String get serverErrorTitle => 'Something went wrong';

  @override
  String get legal => 'About this site';

  @override
  String get correctionsPage => 'Our corrections';

  @override
  String get publishedAt => 'Published';

  @override
  String get updatedAt => 'Updated';

  @override
  String get authorStories => 'Stories';

  @override
  String pageOf(int n) {
    return 'Page $n';
  }

  @override
  String get places => 'Main places';

  @override
  String get savedEmptyWeb => 'Tap the bookmark on any story. It stays on this device.';

  @override
  String get offlineNote => 'You are offline.';

  @override
  String get searchLabel => 'Search the news';

  @override
  String get searchPlaceholder => 'Stories, places, people or writers';

  @override
  String get searchGo => 'Search';

  @override
  String get searchClear => 'Clear the words';

  @override
  String searchResultsFor(String v) {
    return 'Results for “$v”';
  }

  @override
  String searchCount(int n) {
    return '$n stories found';
  }

  @override
  String searchCountMany(int n) {
    return 'More than $n stories found';
  }

  @override
  String get searchNoneTitle => 'No stories match';

  @override
  String get searchNoneBody => 'Try another word, check the spelling, or remove the filters.';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClearRecent => 'Clear recent searches';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchSort => 'Order';

  @override
  String get searchSortBest => 'Best match';

  @override
  String get searchSortNewest => 'Newest first';

  @override
  String get searchType => 'Type';

  @override
  String get searchTypeAll => 'All';

  @override
  String get searchTypeStories => 'Stories';

  @override
  String get searchTypeVideos => 'Videos';

  @override
  String get searchTypeLive => 'Live';

  @override
  String get searchTypeGalleries => 'Galleries';

  @override
  String get searchWhen => 'When';

  @override
  String get searchAnyTime => 'Any time';

  @override
  String get searchPastDay => 'Past 24 hours';

  @override
  String get searchPastWeek => 'Past week';

  @override
  String get searchPastMonth => 'Past month';

  @override
  String get searchPastYear => 'Past year';

  @override
  String get searchMore => 'More results';

  @override
  String get searchUnavailable => 'Search is not available right now. Try again in a moment.';

  @override
  String get searchSections => 'Or choose a section';

  @override
  String seeAllIn(String name) {
    return 'All $name stories';
  }

  @override
  String get seeAll => 'See all';

  @override
  String get earlierStories => 'Earlier stories';

  @override
  String get moreStories => 'More stories';

  @override
  String savedCount(int n) {
    return '$n saved stories';
  }

  @override
  String breakingOf(String at, String total) {
    return '$at of $total';
  }

  @override
  String get breakingPause => 'Pause breaking news';

  @override
  String get breakingPlay => 'Play breaking news';

  @override
  String get savedDoneWeb => 'Added to Saved.';

  @override
  String get savedUndone => 'Removed from Saved.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInTitle => 'Sign in or sign up';

  @override
  String get signInLead =>
      'One account for the website and the app: like, comment and keep your stories everywhere.';

  @override
  String get signInToLike => 'Sign in to like this story';

  @override
  String get signInToComment => 'Sign in to comment';

  @override
  String get signInToSave => 'Sign in to save to your account';

  @override
  String get signInToFollow => 'Sign in to follow';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => 'We will send you a 6-digit code by SMS.';

  @override
  String get sendCode => 'Send code';

  @override
  String get orWith => 'or continue with';

  @override
  String get withGoogle => 'Continue with Google';

  @override
  String get withApple => 'Continue with Apple';

  @override
  String get codeTitle => 'Enter the code';

  @override
  String codeLead(String v) {
    return 'We sent a code to $v.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String codeResendIn(int n) {
    return 'Send again in $n s';
  }

  @override
  String get codeResend => 'Send the code again';

  @override
  String get codeChangePhone => 'Change number';

  @override
  String codeLocal(String v) {
    return 'Testing: your code is $v';
  }

  @override
  String get verify => 'Verify';

  @override
  String get welcomeName => 'Welcome! What should we call you?';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHint =>
      'It shows on your comments and in the lists of who read a story (you can hide it).';

  @override
  String get acceptTerms => 'I accept the community guidelines and the privacy policy';

  @override
  String get continueOn => 'Continue';

  @override
  String get signOut => 'Sign out';

  @override
  String get accountTitle => 'My account';

  @override
  String get editName => 'Change name';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get downloadData => 'Download my data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteConfirm =>
      'The account is deleted after 30 days. Signing in again before then keeps it. Continue?';

  @override
  String get joinTitle => 'Join our readers';

  @override
  String get joinPoints => 'Like stories · Comment · Saved on all your devices';

  @override
  String get likeStory => 'Like';

  @override
  String likesCount(int n) {
    return '$n likes';
  }

  @override
  String commentsCount(int n) {
    return '$n comments';
  }

  @override
  String get comments => 'Comments';

  @override
  String get commentsNone => 'No comments yet. Be the first.';

  @override
  String get commentsClosed => 'Comments are closed for this story.';

  @override
  String get commentPlaceholder => 'Write a comment…';

  @override
  String commentReplyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get commentSend => 'Post';

  @override
  String get commentReply => 'Reply';

  @override
  String get commentDelete => 'Delete';

  @override
  String get commentHeld => 'Waiting for approval';

  @override
  String get commentWriter => 'Writer';

  @override
  String commentReplies(int n) {
    return 'View $n replies';
  }

  @override
  String get commentsMore => 'More comments';

  @override
  String get commentSlow => 'Wait a moment before another comment.';

  @override
  String get commentFailed => 'The comment was not posted. Try again.';

  @override
  String get followTopic => 'Follow';

  @override
  String get followingTopic => 'Following';

  @override
  String get errorTryAgain => 'Something went wrong. Try again.';

  @override
  String get errorPhone => 'This number is not right. For example: 0712 345 678';

  @override
  String get errorCountry => 'We cannot send SMS to this country.';

  @override
  String get errorWait => 'Wait a little, then try again.';

  @override
  String errorCodeWrong(int n) {
    return 'The code is not right. $n tries left.';
  }

  @override
  String get errorCodeExpired => 'The code has expired. Ask for a new one.';

  @override
  String get errorSmsDown => 'SMS cannot be sent right now. Try later.';

  @override
  String signedInToast(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get signedOutToast => 'You are signed out.';

  @override
  String get signInFailed => 'Signing in did not work. Try again.';

  @override
  String logoAlt(String name) {
    return '$name logo';
  }

  @override
  String viewsCount(int n) {
    return '$n views';
  }

  @override
  String readersCount(int n) {
    return '$n readers';
  }

  @override
  String get readersTitle => 'Who read this story';

  @override
  String readersGuests(int n) {
    return 'and $n guests without an account';
  }

  @override
  String get readersNone => 'No signed-in reader yet.';

  @override
  String get readersPrivate => 'Hide my name from reader lists';
}
