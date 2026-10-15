import 'package:flutter/material.dart';
import 'package:score/features/scores/filters.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_list/score_card.dart';

class const ScoreList({
  super.key,
  required final ScoreFilter filter,
  required final List<Score> scores,
  required final void Function(Score score) onScoreTapped,
  required final String empty,
  final String? Function(Score score)? noteOf,
  final List<Widget> header = const [],
  final List<Widget> footer = const [],
}) extends StatefulWidget {
  @override
  State<ScoreList> createState() => _ScoreListState();
}

class _ScoreListState extends State<ScoreList> {
  List<Score> filteredScores = [];

  @override
  void initState() {
    super.initState();
    widget.filter.addListener(_onFilterChanged);
    filteredScores = _filter();
  }

  @override
  void didUpdateWidget(covariant ScoreList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      oldWidget.filter.removeListener(_onFilterChanged);
      widget.filter.addListener(_onFilterChanged);
    }
    filteredScores = _filter();
  }

  @override
  void dispose() {
    widget.filter.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() => setState(() => filteredScores = _filter());

  List<Score> _filter() {
    return widget.scores.where(widget.filter.call).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    final footer = widget.footer;
    final body = filteredScores.isEmpty ? 1 : filteredScores.length;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: header.length + body + footer.length,
      itemBuilder: (context, index) {
        if (index < header.length) {
          return header[index];
        }
        final inBody = index - header.length;
        if (inBody >= body) {
          return footer[inBody - body];
        }
        if (filteredScores.isEmpty) {
          return _nothing(context);
        }
        final score = filteredScores[inBody];
        return ScoreCard(
          score: score,
          note: widget.noteOf?.call(score),
          onTap: () => widget.onScoreTapped(score),
        );
      },
    );
  }

  Widget _nothing(BuildContext context) {
    if (widget.scores.isEmpty && widget.empty.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Text(
        widget.scores.isEmpty ? widget.empty : 'Nothing here matches that.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
