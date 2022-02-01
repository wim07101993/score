import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/large/search_app_bar.dart';

class ScoresListPage extends Page {
  const ScoresListPage({
    LocalKey? key,
  }) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) => const Scaffold(
        appBar: SearchAppBar(),
        body: Text('Scores list'),
      ),
    );
  }
}
