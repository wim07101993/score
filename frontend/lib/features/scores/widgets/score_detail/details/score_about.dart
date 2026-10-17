import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/widgets/score_detail/details/download_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_facts.dart';
import 'package:score/features/scores/widgets/score_detail/details/upload_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/part_selector.dart';
import 'package:score/features/scores/widgets/score_detail/perform_button.dart';
import 'package:score/features/scores/widgets/score_detail/reading/show_as_written_button.dart';
import 'package:score/features/scores/widgets/score_detail/transpose_buttons.dart';
import 'package:score/router.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';
import 'package:songbird_score/songbird_score.dart' as mxml;

class ScoreViewController(
  final ValueNotifier<int> transposition,
  final ValueNotifier<Map<String, bool>> partVisibilities,
  final ValueNotifier<double> zoom,
  final ValueNotifier<bool> isPerforming,
  final ScoreController scoreController,
) {
  ScoreViewController.fromSettings(ScoreViewSettings settings)
    : this(
        ValueNotifier(settings.transposition),
        ValueNotifier(settings.partVisibilities),
        ValueNotifier(settings.zoom),
        ValueNotifier(false),
        ScoreController(score: score),
      );

  ScoreViewSettings get scoreViewSettings {
    return ScoreViewSettings(
      transposition: transposition.value,
      partVisibilities: partVisibilities.value,
      zoom: zoom.value,
    );
  }
}

class const ScoreAbout({
  super.key,
  required final Score scoreProperties,
  required final mxml.Score scoreData,
  required final UserInfo user,
  required final ScoreViewController viewController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerformButton(
          onPressed: () => viewController.isPerforming.value = true,
        ),
        const SizedBox(height: 16),
        ScoreFacts(score: scoreProperties),
        const SizedBox(height: 16),
        Text('How you read it', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransposeControls(
              controller: controller,
              compact: true,
            ),
            if (scoreData.parts.length > 1) ...[
              const SizedBox(height: 8),
              const Text('Instruments on screen'),
              const SizedBox(height: 4),
              PartSelector(
                controller: viewController.partVisibilities,
                score: scoreData,
              ),
            ],
            const SizedBox(height: 8),
            ShowAsWrittenButton(controller: viewController),
          ],
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
                scoreData: scoreData,
                scoreProperties: scoreProperties,
                viewController: viewController,
              ),
              UploadScoreButton(
                scoreId: scoreProperties.id == Score.paperId
                    ? null
                    : scoreProperties.id,
                onUploaded: (scoreId) {
                  context.router.replace(ScoreRoute(scoreId: scoreId));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
