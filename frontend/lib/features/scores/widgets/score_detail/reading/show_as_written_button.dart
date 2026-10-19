import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';

class const ShowAsWrittenButton({
  super.key,
  required final ScoreViewController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.scoreController,
      builder: (context, _) {
        final settings = controller.settings;
        final isAsWritten =
            settings.transposition == 0 && settings.hiddenParts.isEmpty;
        return TextButton(
          onPressed: isAsWritten ? null : controller.showAsWritten,
          child: const Text('Show as written'),
        );
      },
    );
  }
}
