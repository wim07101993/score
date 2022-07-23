import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(s.next),
    );
  }
}
