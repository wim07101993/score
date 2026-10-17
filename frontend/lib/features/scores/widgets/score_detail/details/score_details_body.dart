import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';
import 'package:songbird_score/songbird_score.dart' as mxml;

class const ScoreDetailsBody({
  super.key,
  required final Score scoreProperties,
  required final mxml.Score scoreData,
  required final UserInfo user,
  required final ScoreViewController viewController,
}) extends StatelessWidget {
  static const double minAboutWidth = 280;
  static const double maxAboutWidth = 440;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          // TODO: verify this
          constraints.maxWidth > maxAboutWidth * 2
          ? _sideBySide(constraints)
          : _stacked(constraints),
    );
  }

  Widget _sideBySide(BoxConstraints constraints) {
    final panel = (constraints.maxWidth * 0.38).clamp(
      minAboutWidth,
      maxAboutWidth,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: panel,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScoreAbout(
                scoreProperties: scoreProperties,
                scoreData: scoreData,
                user: user,
                viewController: viewController,
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: MusicScoreView(controller: controller),
        ),
      ],
    );
  }

  // Upright, the score is at the bottom, and the facts above it give way to
  // it rather than pushing it off the screen: they scroll, in at most a
  // little over half of it.
  Widget _stacked(BoxConstraints constraints) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.55),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [about],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: sheet),
      ],
    );
  }
}
