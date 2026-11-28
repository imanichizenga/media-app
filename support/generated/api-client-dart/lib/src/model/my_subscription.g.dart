// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_subscription.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MySubscriptionCWProxy {
  MySubscription active(bool active);

  MySubscription plan(Plan? plan);

  MySubscription endsAt(DateTime? endsAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MySubscription(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MySubscription(...).copyWith(id: 12, name: "My name")
  /// ````
  MySubscription call({bool active, Plan? plan, DateTime? endsAt});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMySubscription.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMySubscription.copyWith.fieldName(...)`
class _$MySubscriptionCWProxyImpl implements _$MySubscriptionCWProxy {
  const _$MySubscriptionCWProxyImpl(this._value);

  final MySubscription _value;

  @override
  MySubscription active(bool active) => this(active: active);

  @override
  MySubscription plan(Plan? plan) => this(plan: plan);

  @override
  MySubscription endsAt(DateTime? endsAt) => this(endsAt: endsAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MySubscription(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MySubscription(...).copyWith(id: 12, name: "My name")
  /// ````
  MySubscription call({
    Object? active = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
  }) {
    return MySubscription(
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      plan: plan == const $CopyWithPlaceholder()
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as Plan?,
      endsAt: endsAt == const $CopyWithPlaceholder()
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime?,
    );
  }
}

extension $MySubscriptionCopyWith on MySubscription {
  /// Returns a callable class that can be used as follows: `instanceOfMySubscription.copyWith(...)` or like so:`instanceOfMySubscription.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MySubscriptionCWProxy get copyWith => _$MySubscriptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MySubscription _$MySubscriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MySubscription', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['active', 'plan', 'ends_at']);
      final val = MySubscription(
        active: $checkedConvert('active', (v) => v as bool),
        plan: $checkedConvert(
          'plan',
          (v) => v == null ? null : Plan.fromJson(v as Map<String, dynamic>),
        ),
        endsAt: $checkedConvert(
          'ends_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'endsAt': 'ends_at'});

Map<String, dynamic> _$MySubscriptionToJson(MySubscription instance) =>
    <String, dynamic>{
      'active': instance.active,
      'plan': instance.plan?.toJson(),
      'ends_at': instance.endsAt?.toIso8601String(),
    };
