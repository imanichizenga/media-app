import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/network/pinning.dart';

class _Certificate extends Mock implements X509Certificate {}

void main() {
  // openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
  const pin = '2PR5tL2jGxA47Hhkyp1WbNqj4yj5t73T0/x4LB0WIO8=';
  const other = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  final der = File('test/fixtures/certificate.der').readAsBytesSync();
  final certificate = _Certificate();
  when(() => certificate.der).thenReturn(der);

  test('the public key is found, as openssl finds it', () {
    expect(base64.encode(sha256.convert(spki(der)!).bytes), pin);
  });
  test('trust follows the pins, and the remote switch', () {
    final p = Pinning();
    expect(p.trusts(certificate), isTrue, reason: 'off');
    p
      ..enabled = true
      ..pins = {pin};
    expect(p.trusts(certificate), isTrue, reason: 'one pin alone is never enforced');
    p.pins = {pin, other};
    expect(p.trusts(certificate), isTrue);
    p.pins = {other, 'BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='};
    expect(p.trusts(certificate), isFalse);
    expect(p.trusts(null), isFalse);
    p.enabled = false;
    expect(p.trusts(certificate), isTrue);
  });
  test('damaged certificates are refused, not thrown', () {
    expect(spki(Uint8List(0)), isNull);
    expect(spki(Uint8List.fromList([0x30, 0x84])), isNull);
    expect(spki(Uint8List.sublistView(der, 0, 60)), isNull);
  });
}
