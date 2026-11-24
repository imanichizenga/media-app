// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_section.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeSectionCWProxy {
  HomeSection category(PublicCategory category);

  HomeSection results(List<Card> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSection(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSection(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSection call({
    PublicCategory category,
    List<Card> results,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeSection.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeSection.copyWith.fieldName(...)`
class _$HomeSectionCWProxyImpl implements _$HomeSectionCWProxy {
  const _$HomeSectionCWProxyImpl(this._value);

  final HomeSection _value;

  @override
  HomeSection category(PublicCategory category) => this(category: category);

  @override
  HomeSection results(List<Card> results) => this(results: results);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSection(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSection(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSection call({
    Object? category = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return HomeSection(
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as PublicCategory,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
    );
  }
}

extension $HomeSectionCopyWith on HomeSection {
  /// Returns a callable class that can be used as follows: `instanceOfHomeSection.copyWith(...)` or like so:`instanceOfHomeSection.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeSectionCWProxy get copyWith => _$HomeSectionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSection _$HomeSectionFromJson(Map<String, dynamic> json) => $checkedCreate(
      'HomeSection',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['category', 'results'],
        );
        final val = HomeSection(
          category: $checkedConvert('category',
              (v) => PublicCategory.fromJson(v as Map<String, dynamic>)),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$HomeSectionToJson(HomeSection instance) =>
    <String, dynamic>{
      'category': instance.category.toJson(),
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
