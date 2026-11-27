// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeCWProxy {
  Home breaking(List<Card> breaking);

  Home live(List<Card> live);

  Home lead(List<Card> lead);

  Home latest(List<Card> latest);

  Home videos(List<Card> videos);

  Home shorts(List<Card> shorts);

  Home sections(List<HomeSection> sections);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Home(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Home(...).copyWith(id: 12, name: "My name")
  /// ````
  Home call({
    List<Card> breaking,
    List<Card> live,
    List<Card> lead,
    List<Card> latest,
    List<Card> videos,
    List<Card> shorts,
    List<HomeSection> sections,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHome.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHome.copyWith.fieldName(...)`
class _$HomeCWProxyImpl implements _$HomeCWProxy {
  const _$HomeCWProxyImpl(this._value);

  final Home _value;

  @override
  Home breaking(List<Card> breaking) => this(breaking: breaking);

  @override
  Home live(List<Card> live) => this(live: live);

  @override
  Home lead(List<Card> lead) => this(lead: lead);

  @override
  Home latest(List<Card> latest) => this(latest: latest);

  @override
  Home videos(List<Card> videos) => this(videos: videos);

  @override
  Home shorts(List<Card> shorts) => this(shorts: shorts);

  @override
  Home sections(List<HomeSection> sections) => this(sections: sections);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Home(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Home(...).copyWith(id: 12, name: "My name")
  /// ````
  Home call({
    Object? breaking = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? lead = const $CopyWithPlaceholder(),
    Object? latest = const $CopyWithPlaceholder(),
    Object? videos = const $CopyWithPlaceholder(),
    Object? shorts = const $CopyWithPlaceholder(),
    Object? sections = const $CopyWithPlaceholder(),
  }) {
    return Home(
      breaking: breaking == const $CopyWithPlaceholder()
          ? _value.breaking
          // ignore: cast_nullable_to_non_nullable
          : breaking as List<Card>,
      live: live == const $CopyWithPlaceholder()
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as List<Card>,
      lead: lead == const $CopyWithPlaceholder()
          ? _value.lead
          // ignore: cast_nullable_to_non_nullable
          : lead as List<Card>,
      latest: latest == const $CopyWithPlaceholder()
          ? _value.latest
          // ignore: cast_nullable_to_non_nullable
          : latest as List<Card>,
      videos: videos == const $CopyWithPlaceholder()
          ? _value.videos
          // ignore: cast_nullable_to_non_nullable
          : videos as List<Card>,
      shorts: shorts == const $CopyWithPlaceholder()
          ? _value.shorts
          // ignore: cast_nullable_to_non_nullable
          : shorts as List<Card>,
      sections: sections == const $CopyWithPlaceholder()
          ? _value.sections
          // ignore: cast_nullable_to_non_nullable
          : sections as List<HomeSection>,
    );
  }
}

extension $HomeCopyWith on Home {
  /// Returns a callable class that can be used as follows: `instanceOfHome.copyWith(...)` or like so:`instanceOfHome.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeCWProxy get copyWith => _$HomeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Home _$HomeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Home', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'breaking',
          'live',
          'lead',
          'latest',
          'videos',
          'shorts',
          'sections',
        ],
      );
      final val = Home(
        breaking: $checkedConvert(
          'breaking',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        live: $checkedConvert(
          'live',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        lead: $checkedConvert(
          'lead',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        latest: $checkedConvert(
          'latest',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        videos: $checkedConvert(
          'videos',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        shorts: $checkedConvert(
          'shorts',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        sections: $checkedConvert(
          'sections',
          (v) => (v as List<dynamic>)
              .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HomeToJson(Home instance) => <String, dynamic>{
  'breaking': instance.breaking.map((e) => e.toJson()).toList(),
  'live': instance.live.map((e) => e.toJson()).toList(),
  'lead': instance.lead.map((e) => e.toJson()).toList(),
  'latest': instance.latest.map((e) => e.toJson()).toList(),
  'videos': instance.videos.map((e) => e.toJson()).toList(),
  'shorts': instance.shorts.map((e) => e.toJson()).toList(),
  'sections': instance.sections.map((e) => e.toJson()).toList(),
};
