import 'package:flutter/material.dart';

/// The set this score is being played from, which opens it.
class const OpenSetButton({
  super.key,
  required final String title,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
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
