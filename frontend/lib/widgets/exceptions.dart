import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showExceptionDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExceptionDialog(
      title: title,
      message: message,
    ),
  );
}

class const ExceptionDialog({
  super.key,
  required final String title,
  required final String message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: [Text(message)],
    );
  }
}

Future<void> showExceptionSnackbar(BuildContext context, Exception e) async {
  // TODO implement
}
