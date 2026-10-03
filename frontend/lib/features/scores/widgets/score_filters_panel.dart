import 'package:flutter/material.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models.dart';

/// The other way of looking: the words the library is actually made of.
///
/// A search box needs you to know what you are looking for, and a player who
/// wants "something for two voices in dutch" does not. The counts are what it
/// is for: a list of composers says who is in the library, and a list of
/// composers with numbers beside them says which of them the library is
/// actually made of.
class ScoreFiltersPanel extends StatefulWidget {
  const ScoreFiltersPanel({
    super.key,
    required this.filters,
    required this.scores,
    required this.onChanged,
  });

  final ScoreFilters filters;

  /// What the values are counted in: the scores the search leaves, before
  /// anything is ticked.
  final List<Score> scores;

  /// Called after a box was ticked, unticked or cleared.
  final VoidCallback onChanged;

  @override
  State<ScoreFiltersPanel> createState() => _ScoreFiltersPanelState();
}

class _ScoreFiltersPanelState extends State<ScoreFiltersPanel> {
  /// How many of a field's values are offered before the rest are folded
  /// away. A library of a few hundred scores has more composers than a sidebar
  /// has room for, and the ones worth ticking are the ones that keep coming up.
  static const _shownAtFirst = 8;

  /// The fields whose values are all being offered, rather than the first few.
  final Set<ScoreField> _unfolded = {};

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final fields = [
      for (final field in ScoreField.all)
        if (filters.valuesOf(field, widget.scores) case final values
            when values.isNotEmpty)
          (field: field, values: values),
    ];

    if (fields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('The scores here say nothing to narrow them down by.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (filters.count > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                filters.clear();
                widget.onChanged();
              },
              child: const Text('Clear all'),
            ),
          ),
        for (final (:field, :values) in fields) ..._field(field, values),
      ],
    );
  }

  List<Widget> _field(ScoreField field, List<FieldValue> values) {
    final theme = Theme.of(context);
    final unfolded = _unfolded.contains(field);
    final showing = unfolded ? values : values.take(_shownAtFirst).toList();
    final folded = values.length - showing.length;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(field.title, style: theme.textTheme.labelLarge),
      ),
      for (final one in showing)
        CheckboxListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
          value: widget.filters.isTicked(field, one.value),
          onChanged: (wanted) {
            widget.filters.tick(field, one.value, wanted: wanted ?? false);
            widget.onChanged();
          },
          title: Text(
            one.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          secondary: Text(
            '${one.count}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      if (folded > 0)
        _foldButton('$folded more', () => _unfolded.add(field))
      else if (unfolded && values.length > _shownAtFirst)
        _foldButton('Fewer', () => _unfolded.remove(field)),
    ];
  }

  Widget _foldButton(String label, VoidCallback change) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(change),
            child: Text(label),
          ),
        ),
      );
}
