import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/features/scores/widgets/search_results_screen/score_list.dart';

@RoutePage()
class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    required this.scores,
  });

  final List<Score> scores;

  @override
  Widget build(BuildContext context) {
    return ScoreList(scores: scores);
  }
}
