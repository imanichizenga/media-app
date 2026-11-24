/// Compares "1.2.10" with "1.3.0". Anything unreadable counts as no requirement.
bool isOlder(String version, String than) {
  List<int>? parse(String v) {
    final parts = v.split('+').first.split('.').map(int.tryParse).toList();
    return parts.length == 3 && !parts.contains(null) ? parts.cast<int>() : null;
  }

  final (a, b) = (parse(version), parse(than));
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}
