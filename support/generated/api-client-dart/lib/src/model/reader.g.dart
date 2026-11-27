// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReaderCWProxy {
  Reader id(String id);

  Reader displayName(String displayName);

  Reader username(String username);

  Reader initial(String initial);

  Reader phone(String phone);

  Reader email(String email);

  Reader locale(LocaleEnum locale);

  Reader methods(List<MethodsEnum> methods);

  Reader onboarding(bool onboarding);

  Reader hideFromReaders(bool hideFromReaders);

  Reader joined(DateTime joined);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Reader(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Reader(...).copyWith(id: 12, name: "My name")
  /// ````
  Reader call({
    String id,
    String displayName,
    String username,
    String initial,
    String phone,
    String email,
    LocaleEnum locale,
    List<MethodsEnum> methods,
    bool onboarding,
    bool hideFromReaders,
    DateTime joined,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReader.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReader.copyWith.fieldName(...)`
class _$ReaderCWProxyImpl implements _$ReaderCWProxy {
  const _$ReaderCWProxyImpl(this._value);

  final Reader _value;

  @override
  Reader id(String id) => this(id: id);

  @override
  Reader displayName(String displayName) => this(displayName: displayName);

  @override
  Reader username(String username) => this(username: username);

  @override
  Reader initial(String initial) => this(initial: initial);

  @override
  Reader phone(String phone) => this(phone: phone);

  @override
  Reader email(String email) => this(email: email);

  @override
  Reader locale(LocaleEnum locale) => this(locale: locale);

  @override
  Reader methods(List<MethodsEnum> methods) => this(methods: methods);

  @override
  Reader onboarding(bool onboarding) => this(onboarding: onboarding);

  @override
  Reader hideFromReaders(bool hideFromReaders) =>
      this(hideFromReaders: hideFromReaders);

  @override
  Reader joined(DateTime joined) => this(joined: joined);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Reader(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Reader(...).copyWith(id: 12, name: "My name")
  /// ````
  Reader call({
    Object? id = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? initial = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? methods = const $CopyWithPlaceholder(),
    Object? onboarding = const $CopyWithPlaceholder(),
    Object? hideFromReaders = const $CopyWithPlaceholder(),
    Object? joined = const $CopyWithPlaceholder(),
  }) {
    return Reader(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      initial: initial == const $CopyWithPlaceholder()
          ? _value.initial
          // ignore: cast_nullable_to_non_nullable
          : initial as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as LocaleEnum,
      methods: methods == const $CopyWithPlaceholder()
          ? _value.methods
          // ignore: cast_nullable_to_non_nullable
          : methods as List<MethodsEnum>,
      onboarding: onboarding == const $CopyWithPlaceholder()
          ? _value.onboarding
          // ignore: cast_nullable_to_non_nullable
          : onboarding as bool,
      hideFromReaders: hideFromReaders == const $CopyWithPlaceholder()
          ? _value.hideFromReaders
          // ignore: cast_nullable_to_non_nullable
          : hideFromReaders as bool,
      joined: joined == const $CopyWithPlaceholder()
          ? _value.joined
          // ignore: cast_nullable_to_non_nullable
          : joined as DateTime,
    );
  }
}

extension $ReaderCopyWith on Reader {
  /// Returns a callable class that can be used as follows: `instanceOfReader.copyWith(...)` or like so:`instanceOfReader.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReaderCWProxy get copyWith => _$ReaderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reader _$ReaderFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Reader',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'display_name',
        'username',
        'initial',
        'phone',
        'email',
        'locale',
        'methods',
        'onboarding',
        'hide_from_readers',
        'joined',
      ],
    );
    final val = Reader(
      id: $checkedConvert('id', (v) => v as String),
      displayName: $checkedConvert('display_name', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String),
      initial: $checkedConvert('initial', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      locale: $checkedConvert(
        'locale',
        (v) => $enumDecode(_$LocaleEnumEnumMap, v),
      ),
      methods: $checkedConvert(
        'methods',
        (v) => (v as List<dynamic>)
            .map((e) => $enumDecode(_$MethodsEnumEnumMap, e))
            .toList(),
      ),
      onboarding: $checkedConvert('onboarding', (v) => v as bool),
      hideFromReaders: $checkedConvert('hide_from_readers', (v) => v as bool),
      joined: $checkedConvert('joined', (v) => DateTime.parse(v as String)),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'hideFromReaders': 'hide_from_readers',
  },
);

Map<String, dynamic> _$ReaderToJson(Reader instance) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'username': instance.username,
  'initial': instance.initial,
  'phone': instance.phone,
  'email': instance.email,
  'locale': _$LocaleEnumEnumMap[instance.locale]!,
  'methods': instance.methods.map((e) => _$MethodsEnumEnumMap[e]!).toList(),
  'onboarding': instance.onboarding,
  'hide_from_readers': instance.hideFromReaders,
  'joined': instance.joined.toIso8601String(),
};

const _$LocaleEnumEnumMap = {LocaleEnum.sw: 'sw', LocaleEnum.en: 'en'};

const _$MethodsEnumEnumMap = {
  MethodsEnum.phone: 'phone',
  MethodsEnum.google: 'google',
  MethodsEnum.apple: 'apple',
};
