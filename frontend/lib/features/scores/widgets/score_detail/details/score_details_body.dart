import 'package:flutter/material.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';

class const ScoreDetailsBody({
  super.key,
  required final ScoreReader reader,
  required final Score? score,
  required final UserInfo user,
  required final VoidCallback onPerform,
  final bool keptAsYourReading = false,
}) extends StatelessWidget {
  static const double minAboutWidth = 280;
  static const double maxAboutWidth = 440;

  @override
  Widget build(BuildContext context) {
    final sheet = ScoreDetailSheet(reader: reader);
    final score = this.score;
    final musicXml = reader.musicXml;
    final controller = reader.view;
    if (score == null || musicXml == null || controller == null) {
      return sheet;
    }

    final about = ScoreAbout(
      score: score,
      musicXml: musicXml,
      controller: controller,
      user: user,
      keptAsYourReading: keptAsYourReading,
      onPerform: reader.isShowing ? onPerform : null,
      onUploaded: (_) => reader.reload(),
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          // TODO: verify this
          constraints.maxWidth > maxAboutWidth * 2
          ? _sideBySide(constraints, about, sheet)
          : _stacked(constraints, about, sheet),
    );
  }

  Widget _sideBySide(BoxConstraints constraints, Widget about, Widget sheet) {
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
            children: [about],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: sheet),
      ],
    );
  }

  // Upright, the score is at the bottom, and the facts above it give way to
  // it rather than pushing it off the screen: they scroll, in at most a
  // little over half of it.
  Widget _stacked(BoxConstraints constraints, Widget about, Widget sheet) {
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
