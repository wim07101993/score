import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router.dart';

/// The way to the sets from wherever the user is.
class const SetsButton({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sets',
      icon: const Icon(Icons.queue_music),
      onPressed: () => context.router.push(const SetsRoute()),
    );
  }
}
