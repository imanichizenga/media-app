import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning by public key (SPKI), so a renewed certificate with the same key keeps working. The pins come
/// with the app config and can be switched off remotely; a wrong pin must never lock readers out for good, so the
/// app config itself is fetched without pins.
class Pinning {
  Set<String> pins = const {};
  bool enabled = false;

  bool trusts(X509Certificate? certificate) {
    if (!enabled || pins.length < 2) return true;
    if (certificate == null) return false;
    final key = spki(certificate.der);
    return key != null && pins.contains(base64.encode(sha256.convert(key).bytes));
  }

  void install(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..connectionTimeout = const Duration(seconds: 8),
      validateCertificate: (certificate, host, port) => trusts(certificate),
    );
  }
}

/// The subjectPublicKeyInfo of a DER certificate: Certificate → tbsCertificate → seventh field (sixth without a
/// version). Null when it is not what it claims.
@visibleForTesting
Uint8List? spki(Uint8List der) {
  try {
    final certificate = _Der(der, 0);
    final tbs = _Der(der, certificate.start);
    var at = tbs.start;
    if (der[at] == 0xA0) at = _Der(der, at).end; // version
    for (var i = 0; i < 5; i++) {
      at = _Der(der, at).end; // serial, signature, issuer, validity, subject
    }
    final key = _Der(der, at);
    if (der[at] != 0x30 || key.end > tbs.end) return null;
    return Uint8List.sublistView(der, at, key.end);
  } on RangeError {
    return null;
  }
}

class _Der {
  _Der(Uint8List bytes, int at) {
    var length = bytes[at + 1];
    start = at + 2;
    if (length & 0x80 != 0) {
      final count = length & 0x7F;
      length = 0;
      for (var i = 0; i < count; i++) {
        length = (length << 8) | bytes[start++];
      }
    }
    end = start + length;
  }

  late int start;
  late final int end;
}
