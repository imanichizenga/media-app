import 'dart:math' as math;
import 'dart:typed_data';

const _digits =
    r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

/// A blurhash as RGBA pixels. Null for anything that is not one: a damaged hash is not worth an error.
Uint8List? decodeBlurhash(String hash, int width, int height) {
  int at(int from, int to) {
    var v = 0;
    for (var i = from; i < to; i++) {
      v = v * 83 + _digits.indexOf(hash[i]);
    }
    return v;
  }

  if (hash.length < 6 || hash.split('').any((c) => !_digits.contains(c))) return null;
  final size = at(0, 1);
  final nx = size % 9 + 1;
  final ny = size ~/ 9 + 1;
  if (hash.length != 4 + 2 * nx * ny) return null;
  final most = (at(1, 2) + 1) / 166;
  double linear(int v) {
    final c = v / 255;
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  double signed(int v) {
    final q = (v - 9) / 9;
    return q.sign * q * q * most;
  }

  final colors = <(double, double, double)>[];
  final dc = at(2, 6);
  colors.add((linear(dc >> 16), linear((dc >> 8) & 255), linear(dc & 255)));
  for (var i = 1; i < nx * ny; i++) {
    final v = at(4 + i * 2, 6 + i * 2);
    colors.add((signed(v ~/ 361), signed(v ~/ 19 % 19), signed(v % 19)));
  }
  int srgb(double v) {
    final c = v.clamp(0.0, 1.0);
    final e = c <= 0.0031308 ? c * 12.92 : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
    return (e * 255 + 0.5).floor();
  }

  final out = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var (r, g, b) = (0.0, 0.0, 0.0);
      for (var j = 0; j < ny; j++) {
        for (var i = 0; i < nx; i++) {
          final basis = math.cos(math.pi * x * i / width) * math.cos(math.pi * y * j / height);
          final (cr, cg, cb) = colors[i + j * nx];
          r += cr * basis;
          g += cg * basis;
          b += cb * basis;
        }
      }
      final p = (y * width + x) * 4;
      out[p] = srgb(r);
      out[p + 1] = srgb(g);
      out[p + 2] = srgb(b);
      out[p + 3] = 255;
    }
  }
  return out;
}
