import 'package:flutter/material.dart';

/// The collection this score is being played from, which opens it.
class OpenCollectionButton extends StatelessWidget {
  const OpenCollectionButton({
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
