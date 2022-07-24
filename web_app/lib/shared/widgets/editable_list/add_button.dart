import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.onPressed,
    required this.canPress,
    required this.text,
    required this.tooManyItemsText,
  });

  final VoidCallback onPressed;
  final bool canPress;
  final String text;
  final String tooManyItemsText;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: canPress ? onPressed : null,
      child: Text(text),
    );

    if (canPress) {
      return button;
    } else {
      return Tooltip(
        message: tooManyItemsText,
        child: button,
      );
    }
  }
}
