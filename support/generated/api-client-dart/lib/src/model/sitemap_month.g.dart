// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sitemap_month.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SitemapMonthCWProxy {
  SitemapMonth month(String month);

  SitemapMonth count(int count);

  SitemapMonth modifiedAt(DateTime modifiedAt);

  SitemapMonth videos(int videos);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapMonth(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapMonth(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapMonth call({String month, int count, DateTime modifiedAt, int videos});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSitemapMonth.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSitemapMonth.copyWith.fieldName(...)`
class _$SitemapMonthCWProxyImpl implements _$SitemapMonthCWProxy {
  const _$SitemapMonthCWProxyImpl(this._value);

  final SitemapMonth _value;

  @override
  SitemapMonth month(String month) => this(month: month);

  @override
  SitemapMonth count(int count) => this(count: count);

  @override
  SitemapMonth modifiedAt(DateTime modifiedAt) => this(modifiedAt: modifiedAt);

  @override
  SitemapMonth videos(int videos) => this(videos: videos);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapMonth(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapMonth(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapMonth call({
    Object? month = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
    Object? videos = const $CopyWithPlaceholder(),
  }) {
    return SitemapMonth(
      month: month == const $CopyWithPlaceholder()
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as String,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      modifiedAt: modifiedAt == const $CopyWithPlaceholder()
          ? _value.modifiedAt
          // ignore: cast_nullable_to_non_nullable
          : modifiedAt as DateTime,
      videos: videos == const $CopyWithPlaceholder()
          ? _value.videos
          // ignore: cast_nullable_to_non_nullable
          : videos as int,
    );
  }
}

extension $SitemapMonthCopyWith on SitemapMonth {
  /// Returns a callable class that can be used as follows: `instanceOfSitemapMonth.copyWith(...)` or like so:`instanceOfSitemapMonth.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SitemapMonthCWProxy get copyWith => _$SitemapMonthCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitemapMonth _$SitemapMonthFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SitemapMonth', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['month', 'count', 'modified_at', 'videos'],
      );
      final val = SitemapMonth(
        month: $checkedConvert('month', (v) => v as String),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        modifiedAt: $checkedConvert(
          'modified_at',
          (v) => DateTime.parse(v as String),
        ),
        videos: $checkedConvert('videos', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'modifiedAt': 'modified_at'});

Map<String, dynamic> _$SitemapMonthToJson(SitemapMonth instance) =>
    <String, dynamic>{
      'month': instance.month,
      'count': instance.count,
      'modified_at': instance.modifiedAt.toIso8601String(),
      'videos': instance.videos,
    };
