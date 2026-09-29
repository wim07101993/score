import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/notation/parts.dart';

/// A document with the parts it is given, each one measure of rest.
String _withParts(List<String> ids) => '''
<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <part-list>
${[for (final id in ids) '    <score-part id="$id"><part-name>$id</part-name></score-part>'].join('\n')}
  </part-list>
${[for (final id in ids) '  <part id="$id"><measure number="1"><attributes><divisions>1</divisions></attributes><note><rest/><duration>4</duration><type>whole</type></note></measure></part>'].join('\n')}
</score-partwise>''';

void main() {
  test('a part with no id does not take the id of one that has it', () {
    final parts = readParts(parseMusicXml(_withParts(['part-1', '']).trim()));

    expect(parts, hasLength(2));
    expect(parts.map((part) => part.id).toSet(), hasLength(2));
    expect(parts.first.id, 'part-1');
  });
}
