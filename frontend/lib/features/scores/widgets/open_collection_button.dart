import 'package:flutter/material.dart';

/// The collection this score is being played from, which opens it.
class OpenCollectionButton extends StatelessWidget {
  const OpenCollectionButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // A collection can be called something long, and the bar it sits in also
    // has to fit the way to the next piece.
    return TextButton(
      onPressed: onPressed,
      child: Text(
        title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
