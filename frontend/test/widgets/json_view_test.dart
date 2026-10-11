import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/widgets/json_view.dart';

void main() {
  final theme = ThemeData();
  final colors = theme.colorScheme;

  Future<List<TextSpan>> spansOf(WidgetTester tester, Object? json) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: JsonView(json: json)),
      ),
    );
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    return text.textSpan!.children!.cast<TextSpan>();
  }

  Color? colorOf(List<TextSpan> spans, String text) =>
      spans.firstWhere((span) => span.text == text).style?.color;

  testWidgets('shows the json as it is encoded', (tester) async {
    final spans = await spansOf(tester, {'a': 1, 'b': 'two'});

    expect(
      spans.map((span) => span.text).join(),
      '{\n  "a": 1,\n  "b": "two"\n}',
    );
  });

  testWidgets('colours keys, strings, numbers and literals apart', (
    tester,
  ) async {
    final spans = await spansOf(tester, {
      'key': 'value',
      'count': -1.5e3,
      'ok': true,
      'none': null,
    });

    expect(colorOf(spans, '"key"'), colors.primary);
    expect(colorOf(spans, '"value"'), colors.tertiary);
    expect(colorOf(spans, '-1500.0'), colors.secondary);
    expect(colorOf(spans, 'true'), colors.secondary);
    expect(colorOf(spans, 'null'), colors.secondary);
    expect(colorOf(spans, '{'), colors.outline);
  });

  testWidgets('keeps escaped quotes inside a string', (tester) async {
    final spans = await spansOf(tester, {'say': 'a "quote": here'});

    expect(colorOf(spans, r'"a \"quote\": here"'), colors.tertiary);
  });
}
