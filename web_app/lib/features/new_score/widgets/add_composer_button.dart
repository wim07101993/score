import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class AddComposerButton extends StatelessWidget {
  const AddComposerButton({
    super.key,
    required this.addComposer,
    required this.canAddComposers,
  });

  final VoidCallback addComposer;
  final bool canAddComposers;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final button = TextButton(
      onPressed: canAddComposers ? addComposer : null,
      child: Text(s.addComposer),
    );

    if (canAddComposers) {
      return button;
    } else {
      return Tooltip(
        message: s.tooManyComposersErrorMessage(Score.maxNumberOfComposers),
        child: button,
      );
    }
  }
}
