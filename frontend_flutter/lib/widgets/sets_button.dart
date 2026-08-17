import 'package:flutter/material.dart';

/// The way to the sets from wherever the user is.
class SetsButton extends StatelessWidget {
  const SetsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sets',
      icon: const Icon(Icons.queue_music),
      onPressed: () => Navigator.of(context).pushNamed('/sets'),
    );
  }
}
