import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rules the analyser cannot know.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart') && !f.path.contains('l10n'),
      );

  test('colours come from the theme: none is written outside lib/ui/tokens', () {
    final found = <String>[];
    final color = RegExp(r'Color\(0x|Color\.from|(?<!News)Colors\.|CupertinoColors');
    for (final f in files.where((f) => !f.path.startsWith('lib/ui/tokens'))) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (color.hasMatch(line)) found.add('${f.path}:${i + 1} $line');
      }
    }
    expect(found, isEmpty);
  });
  test('content never waits behind a spinner', () {
    final found = [
      for (final f in files)
        for (final (i, line) in f.readAsLinesSync().indexed)
          if (RegExp(r'(Circular|Linear)ProgressIndicator\(').hasMatch(line)) '${f.path}:${i + 1}',
    ];
    // Pending states of buttons: the play button, and the sign-in step's button.
    expect(found.map((f) => f.split(':').first).toList()..sort(), [
      'lib/features/account/sign_in.dart',
      'lib/ui/components/player.dart',
    ]);
  });
  test('no text is written in the code', () {
    final found = <String>[];
    final text = RegExp(r'''Text\(\s*['"][A-Za-z]{4,}''');
    for (final f in files) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (text.hasMatch(line)) found.add('${f.path}:${i + 1} $line');
      }
    }
    expect(found, isEmpty);
  });
  test('web views open one address only', () {
    final users = files.where((f) => f.readAsStringSync().contains('webview_flutter'));
    expect(users.map((f) => f.path), ['lib/ui/components/youtube.dart']);
  });
  test('layers: data and core never import a screen', () {
    final found = [
      for (final f in files.where((f) => f.path.startsWith('lib/core')))
        for (final line in f.readAsLinesSync())
          if (line.startsWith('import') && (line.contains('features/') || line.contains('/ui/')))
            '${f.path} $line',
      for (final f in files.where((f) => f.path.startsWith('lib/ui')))
        for (final line in f.readAsLinesSync())
          if (line.startsWith('import') && line.contains('features/')) '${f.path} $line',
    ];
    expect(found, isEmpty);
  });
  test('one place asks which platform it is', () {
    final found = <String>[];
    for (final f in files.where(
      (f) => !f.path.startsWith('lib/ui/adaptive') && !f.path.startsWith('lib/ui/tokens'),
    )) {
      // What the server is told, and what Android is told, are not how things look.
      if (f.path.startsWith('lib/core')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (RegExp(r'isApple|TargetPlatform|Platform\.is|Cupertino').hasMatch(line)) {
          found.add('${f.path}:${i + 1} $line');
        }
      }
    }
    expect(found, isEmpty);
  });
}
