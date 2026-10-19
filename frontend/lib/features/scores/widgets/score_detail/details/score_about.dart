import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/details/download_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_facts.dart';
import 'package:score/features/scores/widgets/score_detail/details/upload_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/perform_button.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_settings_editor.dart';

class const ScoreAbout({
  super.key,
  required final Score score,
  required final String musicXml,
  required final ScoreViewController controller,
  required final UserInfo user,
  required final VoidCallback? onPerform,
  required final void Function(String scoreId) onUploaded,
  final bool keptAsYourReading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerformButton(onPressed: onPerform),
        const SizedBox(height: 16),
        ScoreFacts(score: score),
        const SizedBox(height: 16),
        Text('How you read it', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        ScoreViewSettingsEditor(
          controller: controller,
          keptAsYourReading: keptAsYourReading,
        ),
        const SizedBox(height: 16),
        Text('The score file', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DownloadScoreButton(
                score: score,
                musicXml: musicXml,
                controller: controller,
              ),
              if (user.isScoreEditor)
                UploadScoreButton(
                  scoreId: score.id,
                  onUploaded: onUploaded,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
