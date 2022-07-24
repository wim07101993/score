import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editableTitle = context.read<EditableScore>().editableTitle;
    return ValueListenableBuilder(
      valueListenable: editableTitle,
      builder: (context, value, widget) {
        final title = editableTitle.text.isEmpty
            ? S.of(context)!.newScoreTitle
            : editableTitle.text;
        return Text(
          title,
          style: theme.textTheme.headline4,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
