import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class ScoresListPage extends StatelessWidget {
  const ScoresListPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      return const Text('Scores list');
    });
  }
}
