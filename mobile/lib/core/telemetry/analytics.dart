/// What will be measured, typed. Nothing is sent until the analytics milestone (M9) replaces [NoAnalytics].
sealed class Event {
  const Event();
}

class AppOpened extends Event {
  const AppOpened();
}

class ScreenSeen extends Event {
  const ScreenSeen(this.name);
  final String name;
}

class StoryOpened extends Event {
  const StoryOpened(this.id, {required this.from});
  final String id;
  final String from;
}

class StoryRead extends Event {
  const StoryRead(this.id, this.percent);
  final String id;
  final int percent;
}

class VideoPlayed extends Event {
  const VideoPlayed(this.id, this.percent);
  final String id;
  final int percent;
}

class StoryShared extends Event {
  const StoryShared(this.id);
  final String id;
}

class StorySaved extends Event {
  const StorySaved(this.id, {required this.saved});
  final String id;
  final bool saved;
}

class OnboardingFinished extends Event {
  const OnboardingFinished({required this.skipped, required this.topics});
  final bool skipped;
  final int topics;
}

abstract interface class Analytics {
  void track(Event event);
}

class NoAnalytics implements Analytics {
  const NoAnalytics();

  @override
  void track(Event event) {}
}
