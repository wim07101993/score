import 'package:flutter/material.dart';
import 'package:score/notifiers/set_notifier.dart';

class const _ValueCount(final String name, final int count);

class const FieldFilter({
  super.key,
  required final String title,
  required final Iterable<String> possibleValues,
  required final SetNotifier<String> selectedValues,
}) extends StatefulWidget {
  @override
  State<FieldFilter> createState() => _FieldFilterState();
}

class _FieldFilterState extends State<FieldFilter> {
  final showAll = ValueNotifier<bool>(false);

  @override
  void dispose() {
    showAll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const foldedCount = 8;

    final valueCounts = widget.possibleValues.countedUniqueValues().toList(
      growable: false,
    );

    return ListenableBuilder(
      listenable: Listenable.merge([widget.selectedValues, showAll]),
      builder: (context, _) {
        final shownPossibilities = showAll.value
            ? valueCounts
            : valueCounts.take(foldedCount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(widget.title, style: theme.textTheme.labelLarge),
            ),
            ...checkBoxes(theme, shownPossibilities),
            if (valueCounts.length > foldedCount)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: showAll.value
                      ? showLessButton()
                      : showAllButton(valueCounts.length - foldedCount),
                ),
              ),
          ],
        );
      },
    );
  }

  Iterable<Widget> checkBoxes(
    ThemeData theme,
    Iterable<_ValueCount> possibleValues,
  ) sync* {
    for (final value in possibleValues) {
      yield CheckboxListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        controlAffinity: ListTileControlAffinity.leading,
        value: widget.selectedValues.value.contains(value.name),
        onChanged: (newValue) {
          if (newValue == true) {
            widget.selectedValues.add(value.name);
          } else {
            widget.selectedValues.remove(value.name);
          }
        },
        title: Text(
          value.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Text(
          value.count.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }
  }

  Widget showLessButton() {
    return TextButton(
      onPressed: () => showAll.value = false,
      child: const Text('Show less'),
    );
  }

  Widget showAllButton(int howMuchMore) {
    return TextButton(
      onPressed: () => showAll.value = true,
      child: Text('Show $howMuchMore more'),
    );
  }
}

extension on Iterable<String> {
  List<_ValueCount> countedUniqueValues() {
    final counts = <String, int>{};
    for (final element in this) {
      if (element.trim().isEmpty) {
        continue;
      }
      counts[element] = (counts[element] ?? 0) + 1;
    }
    return counts.entries
        .map((entry) => _ValueCount(entry.key, entry.value))
        .toList(growable: false)
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
  }
}
