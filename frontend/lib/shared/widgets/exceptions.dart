import 'package:flutter/material.dart';
import 'package:score/l10n/app_localizations.dart';

Future<void> showUnknownErrorDialog(BuildContext context) {
  final s = AppLocalizations.of(context)!;
  return showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(s.unknownErrorDialogTitle),
      children: [Text(s.unknownErrorDialogMessage)],
    ),
  );
}

extension ExceptionDialogStateExtensions<T extends StatefulWidget> on State<T> {
  Future<void> showUnknownError() => showUnknownErrorDialog(context);
}
