import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n/gen/strings.dart';

/// 1.3K, 3.4M, the same letters in both languages (ADR-0034). Matches the website's `compact`.
String compact(int n) {
  if (n < 1000) return '$n';
  const units = [(1000, 'K'), (1000000, 'M'), (1000000000, 'B')];
  for (var i = 0; i < units.length; i++) {
    final (size, letter) = units[i];
    final value = (n / size * 10).round() / 10;
    // 999,950 is 1M, not 1000K.
    if (value < 1000 || i == units.length - 1) {
      return value == value.roundToDouble()
          ? '${value.toInt()}$letter'
          : '${value.toStringAsFixed(1)}$letter';
    }
  }
  return '$n';
}

/// The whole number, for those who listen.
String exact(int n) => NumberFormat.decimalPattern('en').format(n);

/// 0:08, 12:30, 1:02:05.
String clock(Duration d) {
  final s = (d.inMilliseconds / 1000).round();
  String two(int n) => '$n'.padLeft(2, '0');
  final (h, m) = (s ~/ 3600, s ~/ 60 % 60);
  return h > 0 ? '$h:${two(m)}:${two(s % 60)}' : '$m:${two(s % 60)}';
}

const _days = {
  'sw': ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'],
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
};
const _months = {
  'sw': [
    'Januari',
    'Februari',
    'Machi',
    'Aprili',
    'Mei',
    'Juni',
    'Julai',
    'Agosti',
    'Septemba',
    'Oktoba',
    'Novemba',
    'Desemba',
  ],
  'en': [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
};

/// The newsroom's clock: East Africa, which never changes it.
DateTime eat(DateTime t) => t.toUtc().add(const Duration(hours: 3));

String longDate(DateTime t, String locale) {
  final d = eat(t);
  return '${_days[locale]![d.weekday - 1]}, ${d.day} ${_months[locale]![d.month - 1]}';
}

String shortDate(DateTime t, String locale) {
  final d = eat(t);
  return '${d.day} ${_months[locale]![d.month - 1].substring(0, 3)}';
}

/// "dakika 5 zilizopita" under a day, then a date. Never "0 minutes ago".
String ago(DateTime t, Strings s, DateTime now) {
  final past = now.difference(t);
  if (past.inMinutes < 60) return s.ago(past.inMinutes < 1 ? 1 : past.inMinutes);
  if (past.inHours < 24) return s.agoHours(past.inHours);
  return shortDate(t, s.localeName);
}
