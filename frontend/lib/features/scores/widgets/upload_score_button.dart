import 'package:flutter/material.dart';

/// Reads a score off the device, either as a new one or over one that is there.
class const UploadScoreButton({
  super.key,

  /// Whether there is already a score here for this to be written over.
  required final bool replacing,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: Text(replacing ? 'Replace this score' : 'Upload a score'),
      onPressed: onPressed,
    );
  }
}
