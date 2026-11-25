// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_seo.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteSeoCWProxy {
  SiteSeo googleVerification(String googleVerification);

  SiteSeo bingVerification(String bingVerification);

  SiteSeo indexnowKey(String indexnowKey);

  SiteSeo sameAs(List<String> sameAs);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteSeo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteSeo(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteSeo call({
    String googleVerification,
    String bingVerification,
    String indexnowKey,
    List<String> sameAs,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteSeo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteSeo.copyWith.fieldName(...)`
class _$SiteSeoCWProxyImpl implements _$SiteSeoCWProxy {
  const _$SiteSeoCWProxyImpl(this._value);

  final SiteSeo _value;

  @override
  SiteSeo googleVerification(String googleVerification) =>
      this(googleVerification: googleVerification);

  @override
  SiteSeo bingVerification(String bingVerification) =>
      this(bingVerification: bingVerification);

  @override
  SiteSeo indexnowKey(String indexnowKey) => this(indexnowKey: indexnowKey);

  @override
  SiteSeo sameAs(List<String> sameAs) => this(sameAs: sameAs);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteSeo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteSeo(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteSeo call({
    Object? googleVerification = const $CopyWithPlaceholder(),
    Object? bingVerification = const $CopyWithPlaceholder(),
    Object? indexnowKey = const $CopyWithPlaceholder(),
    Object? sameAs = const $CopyWithPlaceholder(),
  }) {
    return SiteSeo(
      googleVerification: googleVerification == const $CopyWithPlaceholder()
          ? _value.googleVerification
          // ignore: cast_nullable_to_non_nullable
          : googleVerification as String,
      bingVerification: bingVerification == const $CopyWithPlaceholder()
          ? _value.bingVerification
          // ignore: cast_nullable_to_non_nullable
          : bingVerification as String,
      indexnowKey: indexnowKey == const $CopyWithPlaceholder()
          ? _value.indexnowKey
          // ignore: cast_nullable_to_non_nullable
          : indexnowKey as String,
      sameAs: sameAs == const $CopyWithPlaceholder()
          ? _value.sameAs
          // ignore: cast_nullable_to_non_nullable
          : sameAs as List<String>,
    );
  }
}

extension $SiteSeoCopyWith on SiteSeo {
  /// Returns a callable class that can be used as follows: `instanceOfSiteSeo.copyWith(...)` or like so:`instanceOfSiteSeo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteSeoCWProxy get copyWith => _$SiteSeoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteSeo _$SiteSeoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SiteSeo',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'google_verification',
            'bing_verification',
            'indexnow_key',
            'same_as'
          ],
        );
        final val = SiteSeo(
          googleVerification:
              $checkedConvert('google_verification', (v) => v as String),
          bingVerification:
              $checkedConvert('bing_verification', (v) => v as String),
          indexnowKey: $checkedConvert('indexnow_key', (v) => v as String),
          sameAs: $checkedConvert('same_as',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'googleVerification': 'google_verification',
        'bingVerification': 'bing_verification',
        'indexnowKey': 'indexnow_key',
        'sameAs': 'same_as'
      },
    );

Map<String, dynamic> _$SiteSeoToJson(SiteSeo instance) => <String, dynamic>{
      'google_verification': instance.googleVerification,
      'bing_verification': instance.bingVerification,
      'indexnow_key': instance.indexnowKey,
      'same_as': instance.sameAs,
    };
