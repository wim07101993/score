import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement.dart';

class ArrangementName extends StatelessWidget {
  const ArrangementName({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    final editableName = context.read<EditableArrangement>().editableName;
    return ValueListenableBuilder(
      valueListenable: editableName,
      builder: (context, value, widget) => Text(
        s.arrangementTitle(editableName.text),
        style: theme.textTheme.headline6,
        textAlign: TextAlign.center,
      ),
    );
  }
}
