// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_identity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteIdentityCWProxy {
  SiteIdentity brandName(String brandName);

  SiteIdentity taglineSw(String taglineSw);

  SiteIdentity taglineEn(String taglineEn);

  SiteIdentity wordmarkLight(Logo? wordmarkLight);

  SiteIdentity wordmarkDark(Logo? wordmarkDark);

  SiteIdentity symbol(Logo? symbol);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteIdentity(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteIdentity(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteIdentity call({
    String brandName,
    String taglineSw,
    String taglineEn,
    Logo? wordmarkLight,
    Logo? wordmarkDark,
    Logo? symbol,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteIdentity.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteIdentity.copyWith.fieldName(...)`
class _$SiteIdentityCWProxyImpl implements _$SiteIdentityCWProxy {
  const _$SiteIdentityCWProxyImpl(this._value);

  final SiteIdentity _value;

  @override
  SiteIdentity brandName(String brandName) => this(brandName: brandName);

  @override
  SiteIdentity taglineSw(String taglineSw) => this(taglineSw: taglineSw);

  @override
  SiteIdentity taglineEn(String taglineEn) => this(taglineEn: taglineEn);

  @override
  SiteIdentity wordmarkLight(Logo? wordmarkLight) =>
      this(wordmarkLight: wordmarkLight);

  @override
  SiteIdentity wordmarkDark(Logo? wordmarkDark) =>
      this(wordmarkDark: wordmarkDark);

  @override
  SiteIdentity symbol(Logo? symbol) => this(symbol: symbol);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteIdentity(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteIdentity(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteIdentity call({
    Object? brandName = const $CopyWithPlaceholder(),
    Object? taglineSw = const $CopyWithPlaceholder(),
    Object? taglineEn = const $CopyWithPlaceholder(),
    Object? wordmarkLight = const $CopyWithPlaceholder(),
    Object? wordmarkDark = const $CopyWithPlaceholder(),
    Object? symbol = const $CopyWithPlaceholder(),
  }) {
    return SiteIdentity(
      brandName: brandName == const $CopyWithPlaceholder()
          ? _value.brandName
          // ignore: cast_nullable_to_non_nullable
          : brandName as String,
      taglineSw: taglineSw == const $CopyWithPlaceholder()
          ? _value.taglineSw
          // ignore: cast_nullable_to_non_nullable
          : taglineSw as String,
      taglineEn: taglineEn == const $CopyWithPlaceholder()
          ? _value.taglineEn
          // ignore: cast_nullable_to_non_nullable
          : taglineEn as String,
      wordmarkLight: wordmarkLight == const $CopyWithPlaceholder()
          ? _value.wordmarkLight
          // ignore: cast_nullable_to_non_nullable
          : wordmarkLight as Logo?,
      wordmarkDark: wordmarkDark == const $CopyWithPlaceholder()
          ? _value.wordmarkDark
          // ignore: cast_nullable_to_non_nullable
          : wordmarkDark as Logo?,
      symbol: symbol == const $CopyWithPlaceholder()
          ? _value.symbol
          // ignore: cast_nullable_to_non_nullable
          : symbol as Logo?,
    );
  }
}

extension $SiteIdentityCopyWith on SiteIdentity {
  /// Returns a callable class that can be used as follows: `instanceOfSiteIdentity.copyWith(...)` or like so:`instanceOfSiteIdentity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteIdentityCWProxy get copyWith => _$SiteIdentityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteIdentity _$SiteIdentityFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SiteIdentity',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'brand_name',
            'tagline_sw',
            'tagline_en',
            'wordmark_light',
            'wordmark_dark',
            'symbol',
          ],
        );
        final val = SiteIdentity(
          brandName: $checkedConvert('brand_name', (v) => v as String),
          taglineSw: $checkedConvert('tagline_sw', (v) => v as String),
          taglineEn: $checkedConvert('tagline_en', (v) => v as String),
          wordmarkLight: $checkedConvert(
            'wordmark_light',
            (v) => v == null ? null : Logo.fromJson(v as Map<String, dynamic>),
          ),
          wordmarkDark: $checkedConvert(
            'wordmark_dark',
            (v) => v == null ? null : Logo.fromJson(v as Map<String, dynamic>),
          ),
          symbol: $checkedConvert(
            'symbol',
            (v) => v == null ? null : Logo.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'brandName': 'brand_name',
        'taglineSw': 'tagline_sw',
        'taglineEn': 'tagline_en',
        'wordmarkLight': 'wordmark_light',
        'wordmarkDark': 'wordmark_dark',
      },
    );

Map<String, dynamic> _$SiteIdentityToJson(SiteIdentity instance) =>
    <String, dynamic>{
      'brand_name': instance.brandName,
      'tagline_sw': instance.taglineSw,
      'tagline_en': instance.taglineEn,
      'wordmark_light': instance.wordmarkLight?.toJson(),
      'wordmark_dark': instance.wordmarkDark?.toJson(),
      'symbol': instance.symbol?.toJson(),
    };
