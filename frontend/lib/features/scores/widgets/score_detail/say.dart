import 'package:flutter/material.dart';

void say(BuildContext context, String message, {bool briefly = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: briefly
            ? const Duration(milliseconds: 2500)
            : const Duration(seconds: 4),
      ),
    );
}
