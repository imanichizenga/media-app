// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sitemap_index.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SitemapIndexCWProxy {
  SitemapIndex months(List<SitemapMonth> months);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapIndex(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapIndex(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapIndex call({List<SitemapMonth> months});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSitemapIndex.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSitemapIndex.copyWith.fieldName(...)`
class _$SitemapIndexCWProxyImpl implements _$SitemapIndexCWProxy {
  const _$SitemapIndexCWProxyImpl(this._value);

  final SitemapIndex _value;

  @override
  SitemapIndex months(List<SitemapMonth> months) => this(months: months);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapIndex(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapIndex(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapIndex call({Object? months = const $CopyWithPlaceholder()}) {
    return SitemapIndex(
      months: months == const $CopyWithPlaceholder()
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as List<SitemapMonth>,
    );
  }
}

extension $SitemapIndexCopyWith on SitemapIndex {
  /// Returns a callable class that can be used as follows: `instanceOfSitemapIndex.copyWith(...)` or like so:`instanceOfSitemapIndex.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SitemapIndexCWProxy get copyWith => _$SitemapIndexCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitemapIndex _$SitemapIndexFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SitemapIndex', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['months']);
      final val = SitemapIndex(
        months: $checkedConvert(
          'months',
          (v) => (v as List<dynamic>)
              .map((e) => SitemapMonth.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SitemapIndexToJson(SitemapIndex instance) =>
    <String, dynamic>{
      'months': instance.months.map((e) => e.toJson()).toList(),
    };
