import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/config/version.dart';
import 'package:news_app/core/format/format.dart';
import 'package:news_app/l10n/gen/strings_en.dart';
import 'package:news_app/l10n/gen/strings_sw.dart';

void main() {
  test('compact counts are the website\'s', () {
    const cases = {
      0: '0',
      999: '999',
      1284: '1.3K',
      12480: '12.5K',
      123456: '123.5K',
      999950: '1M',
      3400000: '3.4M',
      1200000000: '1.2B',
    };
    cases.forEach((n, text) => expect(compact(n), text));
    expect(exact(1284), '1,284');
  });
  test('lengths', () {
    expect(clock(const Duration(seconds: 8)), '0:08');
    expect(clock(const Duration(minutes: 12, seconds: 30)), '12:30');
    expect(clock(const Duration(hours: 1, minutes: 2, seconds: 5)), '1:02:05');
  });
  test('times are said in the reader\'s language and never lie', () {
    final now = DateTime.utc(2026, 11, 24, 9);
    String sw(Duration d) => ago(now.subtract(d), StringsSw(), now);
    String en(Duration d) => ago(now.subtract(d), StringsEn(), now);
    expect(sw(const Duration(seconds: 5)), 'dakika 1 iliyopita');
    expect(sw(const Duration(minutes: 5)), 'dakika 5 zilizopita');
    expect(sw(const Duration(hours: 3)), 'saa 3 zilizopita');
    expect(en(const Duration(hours: 3)), '3h ago');
    expect(en(const Duration(days: 2)), '22 Nov');
    expect(sw(const Duration(days: 40)), '15 Okt');
    // The newsroom's midnight, not the phone's.
    expect(longDate(DateTime.utc(2026, 11, 23, 22), 'sw'), 'Jumanne, 24 Novemba');
  });
  test('versions', () {
    expect(isOlder('1.2.3', '1.2.10'), isTrue);
    expect(isOlder('1.3.0', '1.2.10'), isFalse);
    expect(isOlder('1.2.3', '1.2.3'), isFalse);
    expect(isOlder('1.2.3+45', '2.0.0'), isTrue);
    expect(isOlder('1.2.3', ''), isFalse);
    expect(isOlder('1.2.3', 'soon'), isFalse);
  });
}
