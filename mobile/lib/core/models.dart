import 'package:news_api_client/news_api_client.dart' as api;

/// The contract's card. Renamed, because Flutter has a Card of its own.
typedef Story = api.Card;
typedef Kind = api.PostTypeEnum;

extension StoryReading on Story {
  bool isBreaking(DateTime now) => breakingUntil != null && breakingUntil!.isAfter(now);
  bool get isVideo => type == Kind.video || type == Kind.short || type == Kind.youtube;
  Duration? get length => durationMs == null ? null : Duration(milliseconds: durationMs!);
  String get byline => authors.map((a) => a.name).join(', ');
}

/// What the article screen already knows when it opens: the card that was tapped, and the picture that flies.
class StoryExtra {
  const StoryExtra(this.story, {this.heroTag, this.from = ''});

  final Story story;
  final String? heroTag;
  final String from;
}
