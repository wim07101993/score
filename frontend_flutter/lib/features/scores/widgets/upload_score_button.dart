import 'package:flutter/material.dart';

/// Reads a score off the device, either as a new one or over one that is there.
class UploadScoreButton extends StatelessWidget {
  const UploadScoreButton({
    super.key,
    required this.replacing,
    required this.onPressed,
  });

  /// Whether there is already a score here for this to be written over.
  final bool replacing;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: replacing ? 'Replace this score' : 'Upload',
      icon: const Icon(Icons.upload_file),
      onPressed: onPressed,
    );
  }
}
