import 'package:flutter/material.dart';

/// Takes the piece out of the collection.
///
/// It is the only thing there is to do to where a piece is: a collection has
/// no order, so there is nowhere to move one to.
class RemoveCollectionEntryButton extends StatelessWidget {
  const RemoveCollectionEntryButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Take out of the collection',
      icon: const Icon(Icons.close),
      onPressed: onPressed,
    );
  }
}
