import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_settings_editor.dart';

/// The key and the parts, over the stand: the score stays where it is under
/// it, and changes as they are changed.
class const ReadingDialog({
  super.key,
  required final ScoreViewController controller,
  final bool keptAsYourReading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How you read it'),
      content: SingleChildScrollView(
        child: ScoreViewSettingsEditor(
          controller: controller,
          keptAsYourReading: keptAsYourReading,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
