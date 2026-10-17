import 'package:flutter/material.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_settings_editor.dart';

/// The key and the parts, over the stand: the score stays where it is under
/// it, and changes as they are changed.
class const ReadingDialog({
  super.key,
  required final ScoreView? Function() view,
  required final List<ScorePartRef> parts,
  required final bool keptAsYourReading,
  required final void Function(ScoreView Function(ScoreView)) onChange,
}) extends StatefulWidget {
  @override
  State<ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends State<ReadingDialog> {
  @override
  Widget build(BuildContext context) {
    final view = widget.view();
    return AlertDialog(
      title: const Text('How you read it'),
      content: view == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              child: ScoreViewSettingsEditor(
                view: view,
                parts: widget.parts,
                keptAsYourReading: widget.keptAsYourReading,
                onChange: (change) {
                  widget.onChange(change);
                  setState(() {});
                },
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
