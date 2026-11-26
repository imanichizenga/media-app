// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_links.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppLinksCWProxy {
  AppLinks about(String about);

  AppLinks editorial(String editorial);

  AppLinks corrections(String corrections);

  AppLinks contact(String contact);

  AppLinks privacy(String privacy);

  AppLinks terms(String terms);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLinks(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLinks(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLinks call({
    String about,
    String editorial,
    String corrections,
    String contact,
    String privacy,
    String terms,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppLinks.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppLinks.copyWith.fieldName(...)`
class _$AppLinksCWProxyImpl implements _$AppLinksCWProxy {
  const _$AppLinksCWProxyImpl(this._value);

  final AppLinks _value;

  @override
  AppLinks about(String about) => this(about: about);

  @override
  AppLinks editorial(String editorial) => this(editorial: editorial);

  @override
  AppLinks corrections(String corrections) => this(corrections: corrections);

  @override
  AppLinks contact(String contact) => this(contact: contact);

  @override
  AppLinks privacy(String privacy) => this(privacy: privacy);

  @override
  AppLinks terms(String terms) => this(terms: terms);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLinks(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLinks(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLinks call({
    Object? about = const $CopyWithPlaceholder(),
    Object? editorial = const $CopyWithPlaceholder(),
    Object? corrections = const $CopyWithPlaceholder(),
    Object? contact = const $CopyWithPlaceholder(),
    Object? privacy = const $CopyWithPlaceholder(),
    Object? terms = const $CopyWithPlaceholder(),
  }) {
    return AppLinks(
      about: about == const $CopyWithPlaceholder()
          ? _value.about
          // ignore: cast_nullable_to_non_nullable
          : about as String,
      editorial: editorial == const $CopyWithPlaceholder()
          ? _value.editorial
          // ignore: cast_nullable_to_non_nullable
          : editorial as String,
      corrections: corrections == const $CopyWithPlaceholder()
          ? _value.corrections
          // ignore: cast_nullable_to_non_nullable
          : corrections as String,
      contact: contact == const $CopyWithPlaceholder()
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as String,
      privacy: privacy == const $CopyWithPlaceholder()
          ? _value.privacy
          // ignore: cast_nullable_to_non_nullable
          : privacy as String,
      terms: terms == const $CopyWithPlaceholder()
          ? _value.terms
          // ignore: cast_nullable_to_non_nullable
          : terms as String,
    );
  }
}

extension $AppLinksCopyWith on AppLinks {
  /// Returns a callable class that can be used as follows: `instanceOfAppLinks.copyWith(...)` or like so:`instanceOfAppLinks.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppLinksCWProxy get copyWith => _$AppLinksCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLinks _$AppLinksFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AppLinks',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'about',
            'editorial',
            'corrections',
            'contact',
            'privacy',
            'terms'
          ],
        );
        final val = AppLinks(
          about: $checkedConvert('about', (v) => v as String),
          editorial: $checkedConvert('editorial', (v) => v as String),
          corrections: $checkedConvert('corrections', (v) => v as String),
          contact: $checkedConvert('contact', (v) => v as String),
          privacy: $checkedConvert('privacy', (v) => v as String),
          terms: $checkedConvert('terms', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppLinksToJson(AppLinks instance) => <String, dynamic>{
      'about': instance.about,
      'editorial': instance.editorial,
      'corrections': instance.corrections,
      'contact': instance.contact,
      'privacy': instance.privacy,
      'terms': instance.terms,
    };
