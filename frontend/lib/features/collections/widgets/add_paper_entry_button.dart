import 'package:flutter/material.dart';

/// Puts a piece that has yet to be scanned into the collection.
///
/// Off until there is a name to add: a book has nowhere for a piece to come, so
/// an unnamed one could never be found again.
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
