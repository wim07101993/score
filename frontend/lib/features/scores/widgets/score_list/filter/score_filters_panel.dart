import 'package:flutter/material.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_list/filter/field_filter.dart';

class const ScoreFiltersPanel({
  super.key,
  required final ScoreFilter filter,
  required final List<Score> scores,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: filter.clear,
            child: const Text('Clear all'),
          ),
        ),
        FieldFilter(
          title: 'Composers',
          possibleValues: scores.expand(
            (score) => score.creators.composers.toSet(),
          ),
          selectedValues: filter.composers,
        ),
        FieldFilter(
          title: 'Lyricists',
          possibleValues: scores.expand(
            (score) => score.creators.lyricists.toSet(),
          ),
          selectedValues: filter.lyricists,
        ),
        FieldFilter(
          title: 'Instruments',
          possibleValues: scores.expand(
            (score) => score.instruments.map(instrumentName).toSet(),
          ),
          selectedValues: filter.instruments,
        ),
        FieldFilter(
          title: 'Languages',
          possibleValues: scores.expand((score) => score.languages.toSet()),
          selectedValues: filter.languages,
        ),
        FieldFilter(
          title: 'Tags',
          possibleValues: scores.expand((score) => score.tags.toSet()),
          selectedValues: filter.tags,
        ),
      ],
    );
  }
}
