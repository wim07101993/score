import 'package:flutter/material.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_list/add_score_to_collection_button.dart';
import 'package:score/features/scores/widgets/score_list/add_score_to_set_button.dart';

class const ScoreCard({
  super.key,
  required final Score score,
  required final VoidCallback onTap,
  final String? note,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Expanded(
                child: body(theme),
              ),
              AddScoreToCollectionButton(scoreId: score.id),
              AddScoreToSetButton(scoreId: score.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget body(ThemeData theme) {
    final creators = score.creatorNames.join(', ');
    final playedBy = score.instruments.map(instrumentName).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(score.title, style: theme.textTheme.titleMedium),
        if (creators.isNotEmpty) ...[
          const SizedBox(height: 2),
          _Line(icon: Icons.person_outline, text: creators),
        ],
        if (playedBy.isNotEmpty)
          _Line(icon: Icons.piano_outlined, text: playedBy),
        if ((note ?? '').isNotEmpty)
          _Line(icon: Icons.sticky_note_2_outlined, text: note!),
        if (score.tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in score.tags)
                Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class const _Line({
  required final IconData icon,
  required final String text,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}
