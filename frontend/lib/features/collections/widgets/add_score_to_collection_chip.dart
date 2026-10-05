import 'package:flutter/material.dart';

/// One score that can be put into the collection.
///
/// A collection holds a piece once, so a score that is already in it says so
/// rather than being offered again. It stays pressable: what it does then is
/// take the player to the piece, which is what they were asking for.
class const AddScoreToCollectionChip({
  super.key,
  required final String title,
  required final bool alreadyIn,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
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
