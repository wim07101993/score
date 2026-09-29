import 'package:flutter/material.dart';

/// Sends what has been typed about the collection.
class SaveCollectionButton extends StatelessWidget {
  const SaveCollectionButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Save'));
  }
}
