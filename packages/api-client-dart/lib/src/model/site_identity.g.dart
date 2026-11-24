// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_identity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteIdentityCWProxy {
  SiteIdentity brandName(String brandName);

  SiteIdentity taglineSw(String taglineSw);

  SiteIdentity taglineEn(String taglineEn);

  SiteIdentity accentLight(String accentLight);

  SiteIdentity accentDark(String accentDark);

  SiteIdentity logoLight(PublicImage? logoLight);

  SiteIdentity logoDark(PublicImage? logoDark);

  SiteIdentity favicon(PublicImage? favicon);

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
    String accentLight,
    String accentDark,
    PublicImage? logoLight,
    PublicImage? logoDark,
    PublicImage? favicon,
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
  SiteIdentity accentLight(String accentLight) =>
      this(accentLight: accentLight);

  @override
  SiteIdentity accentDark(String accentDark) => this(accentDark: accentDark);

  @override
  SiteIdentity logoLight(PublicImage? logoLight) => this(logoLight: logoLight);

  @override
  SiteIdentity logoDark(PublicImage? logoDark) => this(logoDark: logoDark);

  @override
  SiteIdentity favicon(PublicImage? favicon) => this(favicon: favicon);

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
    Object? accentLight = const $CopyWithPlaceholder(),
    Object? accentDark = const $CopyWithPlaceholder(),
    Object? logoLight = const $CopyWithPlaceholder(),
    Object? logoDark = const $CopyWithPlaceholder(),
    Object? favicon = const $CopyWithPlaceholder(),
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
      accentLight: accentLight == const $CopyWithPlaceholder()
          ? _value.accentLight
          // ignore: cast_nullable_to_non_nullable
          : accentLight as String,
      accentDark: accentDark == const $CopyWithPlaceholder()
          ? _value.accentDark
          // ignore: cast_nullable_to_non_nullable
          : accentDark as String,
      logoLight: logoLight == const $CopyWithPlaceholder()
          ? _value.logoLight
          // ignore: cast_nullable_to_non_nullable
          : logoLight as PublicImage?,
      logoDark: logoDark == const $CopyWithPlaceholder()
          ? _value.logoDark
          // ignore: cast_nullable_to_non_nullable
          : logoDark as PublicImage?,
      favicon: favicon == const $CopyWithPlaceholder()
          ? _value.favicon
          // ignore: cast_nullable_to_non_nullable
          : favicon as PublicImage?,
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
            'accent_light',
            'accent_dark',
            'logo_light',
            'logo_dark',
            'favicon'
          ],
        );
        final val = SiteIdentity(
          brandName: $checkedConvert('brand_name', (v) => v as String),
          taglineSw: $checkedConvert('tagline_sw', (v) => v as String),
          taglineEn: $checkedConvert('tagline_en', (v) => v as String),
          accentLight: $checkedConvert('accent_light', (v) => v as String),
          accentDark: $checkedConvert('accent_dark', (v) => v as String),
          logoLight: $checkedConvert(
              'logo_light',
              (v) => v == null
                  ? null
                  : PublicImage.fromJson(v as Map<String, dynamic>)),
          logoDark: $checkedConvert(
              'logo_dark',
              (v) => v == null
                  ? null
                  : PublicImage.fromJson(v as Map<String, dynamic>)),
          favicon: $checkedConvert(
              'favicon',
              (v) => v == null
                  ? null
                  : PublicImage.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'brandName': 'brand_name',
        'taglineSw': 'tagline_sw',
        'taglineEn': 'tagline_en',
        'accentLight': 'accent_light',
        'accentDark': 'accent_dark',
        'logoLight': 'logo_light',
        'logoDark': 'logo_dark'
      },
    );

Map<String, dynamic> _$SiteIdentityToJson(SiteIdentity instance) =>
    <String, dynamic>{
      'brand_name': instance.brandName,
      'tagline_sw': instance.taglineSw,
      'tagline_en': instance.taglineEn,
      'accent_light': instance.accentLight,
      'accent_dark': instance.accentDark,
      'logo_light': instance.logoLight?.toJson(),
      'logo_dark': instance.logoDark?.toJson(),
      'favicon': instance.favicon?.toJson(),
    };
