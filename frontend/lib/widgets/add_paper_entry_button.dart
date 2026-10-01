import 'package:flutter/material.dart';

/// Puts a piece that is played from paper into a collection or a set.
///
/// In a collection it is off until there is a name to add: a book has nowhere
/// for a piece to come, so an unnamed one could never be found again. A set has
/// a running order, and a song with no name still has its place in it.
class AddPaperEntryButton extends StatelessWidget {
  const AddPaperEntryButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onPressed, child: const Text('Add'));
  }
}
