import 'dart:convert';

import 'package:flutter/material.dart';

class const JsonView({
  super.key,
  required final Object? json,
  final double fontSize = 12,
}) extends StatelessWidget {
  static final _token = RegExp(
    r'("(?:\\.|[^"\\])*")(\s*:)?'
    r'|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    '|(true|false|null)'
    r'|([{}\[\],:])',
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SelectableText.rich(
      TextSpan(children: _spans(colors)),
      style: TextStyle(
        fontFamily: 'RobotoMono',
        fontFamilyFallback: const ['Roboto'],
        fontSize: fontSize,
      ),
    );
  }

  List<TextSpan> _spans(ColorScheme colors) {
    final text = const JsonEncoder.withIndent('  ').convert(json);
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in _token.allMatches(text)) {
      if (match.start > end) {
        spans.add(TextSpan(text: text.substring(end, match.start)));
      }
      if (match.group(1) case final string?) {
        final colon = match.group(2);
        spans.add(
          TextSpan(
            text: string,
            style: TextStyle(
              color: colon == null ? colors.tertiary : colors.primary,
            ),
          ),
        );
        if (colon != null) {
          spans.add(
            TextSpan(
              text: colon,
              style: TextStyle(color: colors.outline),
            ),
          );
        }
      } else if (match.group(3) case final number?) {
        spans.add(
          TextSpan(
            text: number,
            style: TextStyle(color: colors.secondary),
          ),
        );
      } else if (match.group(4) case final literal?) {
        spans.add(
          TextSpan(
            text: literal,
            style: TextStyle(
              color: colors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match[0],
            style: TextStyle(color: colors.outline),
          ),
        );
      }
      end = match.end;
    }
    if (end < text.length) {
      spans.add(TextSpan(text: text.substring(end)));
    }
    return spans;
  }
}
