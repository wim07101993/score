import 'dart:io';

import 'package:score_backend/src/musicxml/parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseMusicXml', () {
    test('should parse music xml', () async {
      // arrange
      final file = File('test_data/musicxml/Irish Blessing.musicxml');
      final xml = await file.readAsString();

      // act
      await parseMusicXml(xml);
    });
  });
}
