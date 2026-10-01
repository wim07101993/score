import 'package:flutter/material.dart';
import 'package:score/routes.dart';

/// The way to the collections from wherever the user is.
class CollectionsButton extends StatelessWidget {
  const CollectionsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Collections',
      icon: const Icon(Icons.library_music_outlined),
      onPressed: () =>
          Navigator.of(context).pushNamed(AppRoute.collections()),
    );
  }
}
