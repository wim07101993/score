import 'package:flutter/material.dart';

/// The set this score is being played from, which opens it.
class OpenSetButton extends StatelessWidget {
  const OpenSetButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // A set is called whatever the band called the gig, which can be long, and
    // the bar it sits in also has to fit the way to the next song.
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
