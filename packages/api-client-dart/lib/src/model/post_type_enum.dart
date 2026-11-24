//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// * `article` - Article * `breaking` - Breaking * `video` - Video * `gallery` - Gallery * `live_blog` - Live Blog * `live_stream` - Live Stream * `opinion` - Opinion * `short` - Short * `youtube` - Youtube * `instagram_import` - Instagram
enum PostTypeEnum {
  @JsonValue(r'article')
  article(r'article'),
  @JsonValue(r'breaking')
  breaking(r'breaking'),
  @JsonValue(r'video')
  video(r'video'),
  @JsonValue(r'gallery')
  gallery(r'gallery'),
  @JsonValue(r'live_blog')
  liveBlog(r'live_blog'),
  @JsonValue(r'live_stream')
  liveStream(r'live_stream'),
  @JsonValue(r'opinion')
  opinion(r'opinion'),
  @JsonValue(r'short')
  short(r'short'),
  @JsonValue(r'youtube')
  youtube(r'youtube'),
  @JsonValue(r'instagram_import')
  instagramImport(r'instagram_import');

  const PostTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
