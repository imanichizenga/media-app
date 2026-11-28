// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OfferCWProxy {
  Offer enabled(bool enabled);

  Offer previewParagraphs(int previewParagraphs);

  Offer methods(List<PaymentMethodEnum> methods);

  Offer plans(List<Plan> plans);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Offer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Offer(...).copyWith(id: 12, name: "My name")
  /// ````
  Offer call({
    bool enabled,
    int previewParagraphs,
    List<PaymentMethodEnum> methods,
    List<Plan> plans,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOffer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOffer.copyWith.fieldName(...)`
class _$OfferCWProxyImpl implements _$OfferCWProxy {
  const _$OfferCWProxyImpl(this._value);

  final Offer _value;

  @override
  Offer enabled(bool enabled) => this(enabled: enabled);

  @override
  Offer previewParagraphs(int previewParagraphs) =>
      this(previewParagraphs: previewParagraphs);

  @override
  Offer methods(List<PaymentMethodEnum> methods) => this(methods: methods);

  @override
  Offer plans(List<Plan> plans) => this(plans: plans);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Offer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Offer(...).copyWith(id: 12, name: "My name")
  /// ````
  Offer call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? previewParagraphs = const $CopyWithPlaceholder(),
    Object? methods = const $CopyWithPlaceholder(),
    Object? plans = const $CopyWithPlaceholder(),
  }) {
    return Offer(
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      previewParagraphs: previewParagraphs == const $CopyWithPlaceholder()
          ? _value.previewParagraphs
          // ignore: cast_nullable_to_non_nullable
          : previewParagraphs as int,
      methods: methods == const $CopyWithPlaceholder()
          ? _value.methods
          // ignore: cast_nullable_to_non_nullable
          : methods as List<PaymentMethodEnum>,
      plans: plans == const $CopyWithPlaceholder()
          ? _value.plans
          // ignore: cast_nullable_to_non_nullable
          : plans as List<Plan>,
    );
  }
}

extension $OfferCopyWith on Offer {
  /// Returns a callable class that can be used as follows: `instanceOfOffer.copyWith(...)` or like so:`instanceOfOffer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OfferCWProxy get copyWith => _$OfferCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Offer',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['enabled', 'preview_paragraphs', 'methods', 'plans'],
    );
    final val = Offer(
      enabled: $checkedConvert('enabled', (v) => v as bool),
      previewParagraphs: $checkedConvert(
        'preview_paragraphs',
        (v) => (v as num).toInt(),
      ),
      methods: $checkedConvert(
        'methods',
        (v) => (v as List<dynamic>)
            .map((e) => $enumDecode(_$PaymentMethodEnumEnumMap, e))
            .toList(),
      ),
      plans: $checkedConvert(
        'plans',
        (v) => (v as List<dynamic>)
            .map((e) => Plan.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'previewParagraphs': 'preview_paragraphs'},
);

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'preview_paragraphs': instance.previewParagraphs,
  'methods': instance.methods
      .map((e) => _$PaymentMethodEnumEnumMap[e]!)
      .toList(),
  'plans': instance.plans.map((e) => e.toJson()).toList(),
};

const _$PaymentMethodEnumEnumMap = {
  PaymentMethodEnum.mobile: 'mobile',
  PaymentMethodEnum.card: 'card',
};
