// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_pages.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicPagesCWProxy {
  PublicPages results(List<PublicPageLink> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPages(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPages(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPages call({
    List<PublicPageLink> results,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicPages.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicPages.copyWith.fieldName(...)`
class _$PublicPagesCWProxyImpl implements _$PublicPagesCWProxy {
  const _$PublicPagesCWProxyImpl(this._value);

  final PublicPages _value;

  @override
  PublicPages results(List<PublicPageLink> results) => this(results: results);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPages(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPages(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPages call({
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return PublicPages(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<PublicPageLink>,
    );
  }
}

extension $PublicPagesCopyWith on PublicPages {
  /// Returns a callable class that can be used as follows: `instanceOfPublicPages.copyWith(...)` or like so:`instanceOfPublicPages.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicPagesCWProxy get copyWith => _$PublicPagesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPages _$PublicPagesFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PublicPages',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['results'],
        );
        final val = PublicPages(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PublicPageLink.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicPagesToJson(PublicPages instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
