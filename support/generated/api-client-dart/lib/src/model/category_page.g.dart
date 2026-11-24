// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryPageCWProxy {
  CategoryPage nextCursor(String? nextCursor);

  CategoryPage results(List<Card> results);

  CategoryPage category(PublicCategoryDetail category);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CategoryPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CategoryPage(...).copyWith(id: 12, name: "My name")
  /// ````
  CategoryPage call({
    String? nextCursor,
    List<Card> results,
    PublicCategoryDetail category,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCategoryPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCategoryPage.copyWith.fieldName(...)`
class _$CategoryPageCWProxyImpl implements _$CategoryPageCWProxy {
  const _$CategoryPageCWProxyImpl(this._value);

  final CategoryPage _value;

  @override
  CategoryPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  CategoryPage results(List<Card> results) => this(results: results);

  @override
  CategoryPage category(PublicCategoryDetail category) =>
      this(category: category);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CategoryPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CategoryPage(...).copyWith(id: 12, name: "My name")
  /// ````
  CategoryPage call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
  }) {
    return CategoryPage(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as PublicCategoryDetail,
    );
  }
}

extension $CategoryPageCopyWith on CategoryPage {
  /// Returns a callable class that can be used as follows: `instanceOfCategoryPage.copyWith(...)` or like so:`instanceOfCategoryPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryPageCWProxy get copyWith => _$CategoryPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryPage _$CategoryPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CategoryPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['next_cursor', 'results', 'category'],
        );
        final val = CategoryPage(
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
          category: $checkedConvert('category',
              (v) => PublicCategoryDetail.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$CategoryPageToJson(CategoryPage instance) =>
    <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'category': instance.category.toJson(),
    };
