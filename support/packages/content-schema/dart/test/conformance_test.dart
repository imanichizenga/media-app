import 'dart:convert';
import 'dart:io';

import 'package:news_content/news_content.dart';
import 'package:test/test.dart';

Iterable<(String, Object?)> load(String kind) =>
    Directory('../../../docs/content-fixtures/$kind')
        .listSync()
        .whereType<File>()
        .map(
          (f) => (f.uri.pathSegments.last, jsonDecode(f.readAsStringSync())),
        );

void main() {
  group('valid', () {
    for (final (name, json) in load('valid')) {
      test('$name round-trips without loss', () {
        final doc = ContentDocument.fromJson(json! as Map<String, dynamic>);
        expect(doc.toJson(), json);
        expect(doc.blocks.whereType<UnknownBlock>(), isEmpty);
      });
    }
  });
  group('invalid', () {
    for (final (name, json) in load('invalid')) {
      test('$name never crashes the reader', () {
        ContentDocument.read(json);
      });
    }
  });
  test('an unknown block keeps the rest of the article', () {
    final doc = ContentDocument.read({
      'version': 1,
      'blocks': [
        {'type': 'hologram', 'id': 'block-1'},
        {'type': 'pull_quote', 'id': 'block-2', 'text': 'a'},
      ],
    });
    expect(doc.blocks.first, isA<UnknownBlock>());
    expect(doc.blocks.last, isA<PullQuoteBlock>());
  });
  test('an unknown enum value is kept apart, not guessed', () {
    final doc = ContentDocument.read({
      'version': 1,
      'blocks': [
        {
          'type': 'callout',
          'id': 'block-1',
          'tone': 'sarcastic',
          'content': <Object>[],
        },
      ],
    });
    expect((doc.blocks.single as CalloutBlock).tone, CalloutTone.unknown);
  });
}
