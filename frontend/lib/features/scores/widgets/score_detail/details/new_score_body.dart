import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/details/upload_score_button.dart';

/// A score that is about to be uploaded has nothing to say about itself yet,
/// and nothing to play: there is only the file to choose.
class const NewScoreBody({
  super.key,
  required final bool mayUpload,
  required final VoidCallback onUpload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose a MusicXML file to upload.'),
          if (mayUpload) ...[
            const SizedBox(height: 16),
            UploadScoreButton(replacing: false, onPressed: onUpload),
          ],
        ],
      ),
    );
  }
}
