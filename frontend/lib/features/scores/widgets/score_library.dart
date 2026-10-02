import 'package:flutter/material.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/widgets/score_filters_panel.dart';
import 'package:score/features/scores/widgets/score_search_field.dart';

/// A list of scores to look through: a search above it, and the filters
/// beside it where there is room and above it where there is not.
///
/// The same wherever scores are listed — every score there is, and the pieces
/// of a collection — so that looking through a book goes the way looking
/// through the shelf does.
///
/// What is listed does not have to be a score: a piece of a collection that
/// was never scanned is listed too. It is found by [textOf] alone, and only
/// shown while nothing is ticked, as there is nothing it could be ticked by.
class ScoreLibrary<T> extends StatefulWidget {
  const ScoreLibrary({
    super.key,
    required this.items,
    required this.scoreOf,
    required this.itemBuilder,
    required this.empty,
    this.textOf,
    this.header = const [],
    this.footer = const [],
    this.onRefresh,
  });

  /// In the order they are to be listed in.
  final List<T> items;

  /// The score an item is, when it is one.
  final Score? Function(T item) scoreOf;

  final Widget Function(BuildContext context, T item) itemBuilder;

  /// What is said when there is nothing to list at all.
  final String empty;

  /// What an item is found by besides its score: what a collection says next
  /// to a piece, say.
  final String Function(T item)? textOf;

  /// What scrolls along above and below the items.
  final List<Widget> header;
  final List<Widget> footer;

  /// What pulling the list down does, if anything.
  final Future<void> Function()? onRefresh;

  @override
  State<ScoreLibrary<T>> createState() => _ScoreLibraryState<T>();
}

class _ScoreLibraryState<T> extends State<ScoreLibrary<T>> {
  /// How wide it has to be for the filters to go beside the list rather than
  /// above it: two columns in less than this are two narrow columns.
  static const _roomForFiltersBeside = 832.0;

  String _query = '';
  final _filters = ScoreFilters();

  bool _found(T item, List<String> words) {
    if (words.isEmpty) return true;
    final text = [
      widget.scoreOf(item)?.searchText ?? '',
      forSearch(widget.textOf?.call(item) ?? ''),
    ].join(' ');
    return words.every(text.contains);
  }

  @override
  Widget build(BuildContext context) {
    final words = searchWords(_query.trim());
    final found = [
      for (final item in widget.items)
        if (_found(item, words)) item,
    ];
    final shown = [
      for (final item in found)
        if (_filters.passes(widget.scoreOf(item))) item,
    ];

    final search = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ScoreSearchField(
        onChanged: (value) => setState(() => _query = value),
      ),
    );
    final list = Expanded(child: _list(shown));
    final filters = ScoreFiltersPanel(
      filters: _filters,
      // Counted in what the search leaves, so that the numbers are what
      // ticking them would leave on the screen.
      scores: [
        for (final item in found)
          if (widget.scoreOf(item) case final score?) score,
      ],
      onChanged: () => setState(() {}),
    );
    // Said in the title because on a phone the title may be all there is to
    // see: a list narrowed by something folded away looks like a list that has
    // lost half of what is in it.
    final filtersTitle =
        _filters.count == 0 ? 'Filters' : 'Filters (${_filters.count})';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _roomForFiltersBeside) {
          return Column(
            children: [
              search,
              ExpansionTile(
                title: Text(filtersTitle),
                children: [
                  SizedBox(height: constraints.maxHeight / 2, child: filters),
                ],
              ),
              list,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 260,
              child: Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        filtersTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: filters),
                  ],
                ),
              ),
            ),
            Expanded(child: Column(children: [search, list])),
          ],
        );
      },
    );
  }

  Widget _list(List<T> shown) {
    final header = widget.header;
    final footer = widget.footer;
    final body = shown.isEmpty ? 1 : shown.length;

    final list = ListView.builder(
      // Scrollable however little is in it, or there is nothing to pull down.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: header.length + body + footer.length,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final inBody = index - header.length;
        if (inBody >= body) return footer[inBody - body];
        if (shown.isEmpty) return _nothing(context);
        return widget.itemBuilder(context, shown[inBody]);
      },
    );

    final onRefresh = widget.onRefresh;
    // Around the list alone: pulling the filters down past their top is
    // scrolling them, not asking for a sync.
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh, child: list);
  }

  Widget _nothing(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
        child: Text(
          widget.items.isEmpty ? widget.empty : 'Nothing here matches that.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
}
