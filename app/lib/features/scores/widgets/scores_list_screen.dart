import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/large/search_app_bar.dart';

class ScoresListScreen extends StatelessWidget {
  const ScoresListScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SearchAppBar(),
      body: Text('Scores list'),
    );
  }
}
