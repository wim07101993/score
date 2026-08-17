import 'package:flutter/material.dart';

/// The set this score is being played from, which opens it.
class OpenSetButton extends StatelessWidget {
  const OpenSetButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(title));
  }
}
