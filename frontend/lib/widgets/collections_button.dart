import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router.dart';

/// The way to the collections from wherever the user is.
class const CollectionsButton({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Collections',
      icon: const Icon(Icons.library_music_outlined),
      onPressed: () => context.router.push(const CollectionsRoute()),
    );
  }
}
