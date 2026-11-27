// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_profile_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PatchedProfileRequestCWProxy {
  PatchedProfileRequest displayName(String? displayName);

  PatchedProfileRequest username(String? username);

  PatchedProfileRequest locale(LocaleEnum? locale);

  PatchedProfileRequest acceptTerms(bool? acceptTerms);

  PatchedProfileRequest hideFromReaders(bool? hideFromReaders);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PatchedProfileRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PatchedProfileRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PatchedProfileRequest call({
    String? displayName,
    String? username,
    LocaleEnum? locale,
    bool? acceptTerms,
    bool? hideFromReaders,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPatchedProfileRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPatchedProfileRequest.copyWith.fieldName(...)`
class _$PatchedProfileRequestCWProxyImpl
    implements _$PatchedProfileRequestCWProxy {
  const _$PatchedProfileRequestCWProxyImpl(this._value);

  final PatchedProfileRequest _value;

  @override
  PatchedProfileRequest displayName(String? displayName) =>
      this(displayName: displayName);

  @override
  PatchedProfileRequest username(String? username) => this(username: username);

  @override
  PatchedProfileRequest locale(LocaleEnum? locale) => this(locale: locale);

  @override
  PatchedProfileRequest acceptTerms(bool? acceptTerms) =>
      this(acceptTerms: acceptTerms);

  @override
  PatchedProfileRequest hideFromReaders(bool? hideFromReaders) =>
      this(hideFromReaders: hideFromReaders);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PatchedProfileRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PatchedProfileRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PatchedProfileRequest call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? acceptTerms = const $CopyWithPlaceholder(),
    Object? hideFromReaders = const $CopyWithPlaceholder(),
  }) {
    return PatchedProfileRequest(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String?,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as LocaleEnum?,
      acceptTerms: acceptTerms == const $CopyWithPlaceholder()
          ? _value.acceptTerms
          // ignore: cast_nullable_to_non_nullable
          : acceptTerms as bool?,
      hideFromReaders: hideFromReaders == const $CopyWithPlaceholder()
          ? _value.hideFromReaders
          // ignore: cast_nullable_to_non_nullable
          : hideFromReaders as bool?,
    );
  }
}

extension $PatchedProfileRequestCopyWith on PatchedProfileRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPatchedProfileRequest.copyWith(...)` or like so:`instanceOfPatchedProfileRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PatchedProfileRequestCWProxy get copyWith =>
      _$PatchedProfileRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedProfileRequest _$PatchedProfileRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PatchedProfileRequest',
  json,
  ($checkedConvert) {
    final val = PatchedProfileRequest(
      displayName: $checkedConvert('display_name', (v) => v as String?),
      username: $checkedConvert('username', (v) => v as String?),
      locale: $checkedConvert(
        'locale',
        (v) => $enumDecodeNullable(_$LocaleEnumEnumMap, v),
      ),
      acceptTerms: $checkedConvert('accept_terms', (v) => v as bool?),
      hideFromReaders: $checkedConvert('hide_from_readers', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'acceptTerms': 'accept_terms',
    'hideFromReaders': 'hide_from_readers',
  },
);

Map<String, dynamic> _$PatchedProfileRequestToJson(
  PatchedProfileRequest instance,
) => <String, dynamic>{
  'display_name': ?instance.displayName,
  'username': ?instance.username,
  'locale': ?_$LocaleEnumEnumMap[instance.locale],
  'accept_terms': ?instance.acceptTerms,
  'hide_from_readers': ?instance.hideFromReaders,
};

const _$LocaleEnumEnumMap = {LocaleEnum.sw: 'sw', LocaleEnum.en: 'en'};
