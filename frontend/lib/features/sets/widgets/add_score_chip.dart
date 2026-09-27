import 'package:flutter/material.dart';

/// One score that can be put into the set.
///
/// The same score can be played more than once in a gig, each time with its own
/// key and its own note next to it, so this adds rather than toggles.
class AddScoreChip extends StatelessWidget {
  const AddScoreChip({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(title), onPressed: onPressed);
  }
}
