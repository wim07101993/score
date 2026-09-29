import 'package:flutter/material.dart';

/// One score that can be put into the collection.
///
/// A collection holds a piece once, so a score that is already in it says so
/// rather than being offered again. It stays pressable: what it does then is
/// take the player to the piece, which is what they were asking for.
class AddScoreToCollectionChip extends StatelessWidget {
  const AddScoreToCollectionChip({
    super.key,
    required this.title,
    required this.alreadyIn,
    required this.onPressed,
  });

  final String title;
  final bool alreadyIn;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: alreadyIn ? const Icon(Icons.check, size: 18) : null,
      label: Text(title),
      tooltip: alreadyIn ? 'Already in this collection' : null,
      onPressed: onPressed,
    );
  }
}
