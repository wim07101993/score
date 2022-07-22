import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class AddTagButton extends StatelessWidget {
  const AddTagButton({
    super.key,
    required this.addTag,
    required this.canAddTags,
  });

  final VoidCallback addTag;
  final bool canAddTags;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final button = TextButton(
      onPressed: canAddTags ? addTag : null,
      // TODO
      child: Text('add tag'), //s.addTag),
    );

    if (canAddTags) {
      return button;
    } else {
      return button;
      // TODO
      // return Tooltip(
      //   message: s.tooManyTagsErrorMessage(
      //     DraftScore.maxNumberOfTags,
      //   ),
      //   child: button,
      // );
    }
  }
}
