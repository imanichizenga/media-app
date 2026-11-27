// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_engagement.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteEngagementCWProxy {
  SiteEngagement cardCounts(bool cardCounts);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteEngagement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteEngagement(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteEngagement call({bool cardCounts});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteEngagement.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteEngagement.copyWith.fieldName(...)`
class _$SiteEngagementCWProxyImpl implements _$SiteEngagementCWProxy {
  const _$SiteEngagementCWProxyImpl(this._value);

  final SiteEngagement _value;

  @override
  SiteEngagement cardCounts(bool cardCounts) => this(cardCounts: cardCounts);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteEngagement(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteEngagement(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteEngagement call({Object? cardCounts = const $CopyWithPlaceholder()}) {
    return SiteEngagement(
      cardCounts: cardCounts == const $CopyWithPlaceholder()
          ? _value.cardCounts
          // ignore: cast_nullable_to_non_nullable
          : cardCounts as bool,
    );
  }
}

extension $SiteEngagementCopyWith on SiteEngagement {
  /// Returns a callable class that can be used as follows: `instanceOfSiteEngagement.copyWith(...)` or like so:`instanceOfSiteEngagement.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteEngagementCWProxy get copyWith => _$SiteEngagementCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteEngagement _$SiteEngagementFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteEngagement', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['card_counts']);
      final val = SiteEngagement(
        cardCounts: $checkedConvert('card_counts', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'cardCounts': 'card_counts'});

Map<String, dynamic> _$SiteEngagementToJson(SiteEngagement instance) =>
    <String, dynamic>{'card_counts': instance.cardCounts};
