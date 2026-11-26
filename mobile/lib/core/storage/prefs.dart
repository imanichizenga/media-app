import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'database.dart';

enum SchemeChoice { system, light, dark }

/// The reader's settings, held in memory and written through. Read whole before the first frame.
@immutable
class Settings {
  const Settings({
    this.onboarded = false,
    this.locale = 'sw',
    this.scheme = SchemeChoice.system,
    this.textScale = 1,
    this.dataSaver = false,
    this.topics = const {},
    this.dismissedVersion = '',
  });

  factory Settings.read(Map<String, String> raw) => Settings(
    onboarded: raw['onboarded'] == '1',
    locale: raw['locale'] == 'en' ? 'en' : 'sw',
    scheme: SchemeChoice.values.asNameMap()[raw['scheme']] ?? SchemeChoice.system,
    textScale: (double.tryParse(raw['textScale'] ?? '') ?? 1).clamp(0.85, 1.6),
    dataSaver: raw['dataSaver'] == '1',
    topics: switch (raw['topics']) {
      final String json => {...(jsonDecode(json) as List<dynamic>).cast<String>()},
      _ => const {},
    },
    dismissedVersion: raw['dismissedVersion'] ?? '',
  );

  final bool onboarded;
  final String locale;
  final SchemeChoice scheme;

  /// Of the article text, on top of the phone's own setting.
  final double textScale;
  final bool dataSaver;

  /// Category ids chosen at the start. Merged into the account in M4.
  final Set<String> topics;
  final String dismissedVersion;

  Map<String, String> write() => {
    'onboarded': onboarded ? '1' : '0',
    'locale': locale,
    'scheme': scheme.name,
    'textScale': '$textScale',
    'dataSaver': dataSaver ? '1' : '0',
    'topics': jsonEncode([...topics]),
    'dismissedVersion': dismissedVersion,
  };

  Settings copyWith({
    bool? onboarded,
    String? locale,
    SchemeChoice? scheme,
    double? textScale,
    bool? dataSaver,
    Set<String>? topics,
    String? dismissedVersion,
  }) => Settings(
    onboarded: onboarded ?? this.onboarded,
    locale: locale ?? this.locale,
    scheme: scheme ?? this.scheme,
    textScale: textScale ?? this.textScale,
    dataSaver: dataSaver ?? this.dataSaver,
    topics: topics ?? this.topics,
    dismissedVersion: dismissedVersion ?? this.dismissedVersion,
  );
}

/// Writes only what changed.
Future<void> saveSettings(AppDatabase db, Settings before, Settings after) async {
  final old = before.write();
  for (final MapEntry(:key, :value) in after.write().entries) {
    if (old[key] != value) await db.putPref(key, value);
  }
}
