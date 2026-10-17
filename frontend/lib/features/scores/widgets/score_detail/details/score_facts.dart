import 'package:flutter/material.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/score.dart';

class const ScoreFacts({
  super.key,
  required final Score score,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final work = score.work;
    final movement = score.movement;
    final rows = <(String, String)>[
      if (score.creators.composers.isNotEmpty)
        ('Composed by', score.creators.composers.join(', ')),
      if (score.creators.lyricists.isNotEmpty)
        ('Words by', score.creators.lyricists.join(', ')),
      if ((work?.number ?? '').trim().isNotEmpty) ('Number', work!.number!),
      // A movement is only worth saying when it is not already the title.
      if ((movement?.title ?? '').trim().isNotEmpty &&
          movement!.title!.trim() != score.title)
        ('Movement', movement.title!.trim()),
      if (score.instruments.isNotEmpty)
        ('Played by', score.instruments.map(instrumentName).join(', ')),
      if (score.languages.isNotEmpty) ('Sung in', score.languages.join(', ')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        if (score.tags.isNotEmpty)
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
    );
  }
}
