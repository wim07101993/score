import 'package:flutter/material.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';

class const ShowAsWrittenButton({
  super.key,
  required final ScoreViewController controller,
}) extends StatelessWidget {
  void resetScoreView() {
    const defaults = ScoreViewSettings.defaultView();
    controller.transposition.value = defaults.transposition;
    controller.partVisibilities.value = defaults.partVisibilities;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: resetScoreView,
      child: const Text('Show as written'),
    );
  }
}
