import 'package:flutter/material.dart';

/// Writes the score this device is holding back out to the device.
class DownloadScoreButton extends StatelessWidget {
  const DownloadScoreButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Download the score file',
      icon: const Icon(Icons.download),
      onPressed: onPressed,
    );
  }
}
