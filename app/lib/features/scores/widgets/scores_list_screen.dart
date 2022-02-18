import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/widgets/large/app_bar.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class ScoresListScreen extends StatelessWidget {
  const ScoresListScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      return const Scaffold(
        appBar: SearchAppBar(),
        body: Text('Scores list'),
      );
    });
  }
}
