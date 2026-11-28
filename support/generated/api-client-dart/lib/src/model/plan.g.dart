// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanCWProxy {
  Plan id(String id);

  Plan code(String code);

  Plan interval(PlanIntervalEnum interval);

  Plan price(int price);

  Plan currency(String currency);

  Plan name(String name);

  Plan tagline(String tagline);

  Plan features(List<String> features);

  Plan badge(String badge);

  Plan tone(String tone);

  Plan highlighted(bool highlighted);

  Plan monthlyEquivalent(int monthlyEquivalent);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Plan(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Plan(...).copyWith(id: 12, name: "My name")
  /// ````
  Plan call({
    String id,
    String code,
    PlanIntervalEnum interval,
    int price,
    String currency,
    String name,
    String tagline,
    List<String> features,
    String badge,
    String tone,
    bool highlighted,
    int monthlyEquivalent,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlan.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlan.copyWith.fieldName(...)`
class _$PlanCWProxyImpl implements _$PlanCWProxy {
  const _$PlanCWProxyImpl(this._value);

  final Plan _value;

  @override
  Plan id(String id) => this(id: id);

  @override
  Plan code(String code) => this(code: code);

  @override
  Plan interval(PlanIntervalEnum interval) => this(interval: interval);

  @override
  Plan price(int price) => this(price: price);

  @override
  Plan currency(String currency) => this(currency: currency);

  @override
  Plan name(String name) => this(name: name);

  @override
  Plan tagline(String tagline) => this(tagline: tagline);

  @override
  Plan features(List<String> features) => this(features: features);

  @override
  Plan badge(String badge) => this(badge: badge);

  @override
  Plan tone(String tone) => this(tone: tone);

  @override
  Plan highlighted(bool highlighted) => this(highlighted: highlighted);

  @override
  Plan monthlyEquivalent(int monthlyEquivalent) =>
      this(monthlyEquivalent: monthlyEquivalent);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Plan(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Plan(...).copyWith(id: 12, name: "My name")
  /// ````
  Plan call({
    Object? id = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? price = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? tagline = const $CopyWithPlaceholder(),
    Object? features = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? tone = const $CopyWithPlaceholder(),
    Object? highlighted = const $CopyWithPlaceholder(),
    Object? monthlyEquivalent = const $CopyWithPlaceholder(),
  }) {
    return Plan(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      interval: interval == const $CopyWithPlaceholder()
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as PlanIntervalEnum,
      price: price == const $CopyWithPlaceholder()
          ? _value.price
          // ignore: cast_nullable_to_non_nullable
          : price as int,
      currency: currency == const $CopyWithPlaceholder()
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      tagline: tagline == const $CopyWithPlaceholder()
          ? _value.tagline
          // ignore: cast_nullable_to_non_nullable
          : tagline as String,
      features: features == const $CopyWithPlaceholder()
          ? _value.features
          // ignore: cast_nullable_to_non_nullable
          : features as List<String>,
      badge: badge == const $CopyWithPlaceholder()
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as String,
      tone: tone == const $CopyWithPlaceholder()
          ? _value.tone
          // ignore: cast_nullable_to_non_nullable
          : tone as String,
      highlighted: highlighted == const $CopyWithPlaceholder()
          ? _value.highlighted
          // ignore: cast_nullable_to_non_nullable
          : highlighted as bool,
      monthlyEquivalent: monthlyEquivalent == const $CopyWithPlaceholder()
          ? _value.monthlyEquivalent
          // ignore: cast_nullable_to_non_nullable
          : monthlyEquivalent as int,
    );
  }
}

extension $PlanCopyWith on Plan {
  /// Returns a callable class that can be used as follows: `instanceOfPlan.copyWith(...)` or like so:`instanceOfPlan.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanCWProxy get copyWith => _$PlanCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Plan', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'code',
          'interval',
          'price',
          'currency',
          'name',
          'tagline',
          'features',
          'badge',
          'tone',
          'highlighted',
          'monthly_equivalent',
        ],
      );
      final val = Plan(
        id: $checkedConvert('id', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        interval: $checkedConvert(
          'interval',
          (v) => $enumDecode(_$PlanIntervalEnumEnumMap, v),
        ),
        price: $checkedConvert('price', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        tagline: $checkedConvert('tagline', (v) => v as String),
        features: $checkedConvert(
          'features',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        badge: $checkedConvert('badge', (v) => v as String),
        tone: $checkedConvert('tone', (v) => v as String),
        highlighted: $checkedConvert('highlighted', (v) => v as bool),
        monthlyEquivalent: $checkedConvert(
          'monthly_equivalent',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'monthlyEquivalent': 'monthly_equivalent'});

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'interval': _$PlanIntervalEnumEnumMap[instance.interval]!,
  'price': instance.price,
  'currency': instance.currency,
  'name': instance.name,
  'tagline': instance.tagline,
  'features': instance.features,
  'badge': instance.badge,
  'tone': instance.tone,
  'highlighted': instance.highlighted,
  'monthly_equivalent': instance.monthlyEquivalent,
};

const _$PlanIntervalEnumEnumMap = {
  PlanIntervalEnum.month: 'month',
  PlanIntervalEnum.year: 'year',
};
