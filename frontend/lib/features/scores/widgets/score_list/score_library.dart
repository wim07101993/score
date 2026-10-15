import 'package:flutter/material.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_list/filter/score_filters_panel.dart';
import 'package:score/features/scores/widgets/score_list/filter/score_search_field.dart';
import 'package:score/features/scores/widgets/score_list/score_list.dart';

class const ScoreLibrary({
  super.key,
  required final List<Score> scores,
  required final void Function(Score score) onScoreTapped,
  final String empty = 'No scores on this device yet.',
  final String? Function(Score score)? noteOf,
  final List<Widget> header = const [],
  final List<Widget> footer = const [],
}) extends StatefulWidget {
  @override
  State<ScoreLibrary> createState() => _ScoreLibraryState();
}

class _ScoreLibraryState extends State<ScoreLibrary> {
  final filter = ScoreFilter();

  @override
  void dispose() {
    filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasRoomForFilterSidePanel) {
          return _layoutWithFilterSidePanel(theme);
        }
        return _layoutWithExpandableFilter(constraints);
      },
    );
  }

  Widget _layoutWithFilterSidePanel(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
            child: _filterCard(theme),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _searchField(),
              Expanded(child: _list()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _FilterTitle(
              filter: filter,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ScoreFiltersPanel(filter: filter, scores: widget.scores),
          ),
        ],
      ),
    );
  }

  Widget _layoutWithExpandableFilter(BoxConstraints constraints) {
    return Column(
      children: [
        _searchField(),
        ExpansionTile(
          title: _FilterTitle(filter: filter),
          children: [
            SizedBox(
              height: constraints.maxHeight / 2,
              child: ScoreFiltersPanel(
                filter: filter,
                scores: widget.scores,
              ),
            ),
          ],
        ),
        Expanded(child: _list()),
      ],
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ScoreSearchField(controller: filter.query),
    );
  }

  Widget _list() {
    return ScoreList(
      filter: filter,
      scores: widget.scores,
      onScoreTapped: widget.onScoreTapped,
      empty: widget.empty,
      noteOf: widget.noteOf,
      header: widget.header,
      footer: widget.footer,
    );
  }
}

class const _FilterTitle({
  required final ScoreFilter filter,
  final TextStyle? style,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: filter,
      builder: (context, _) {
        final count = filter.count;
        return Text(
          count > 0 ? 'Filters ($count)' : 'Filters',
          style: style,
        );
      },
    );
  }
}

extension on BoxConstraints {
  bool get hasRoomForFilterSidePanel {
    return maxWidth >= 832.0;
  }
}
