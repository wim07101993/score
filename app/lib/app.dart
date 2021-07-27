import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/dc.dart';

import 'features/user/widgets/log_in_screen.dart';

class App extends StatelessWidget {
  const App({
    required this.getIt,
  });

  final GetIt getIt;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score',
      theme: ThemeData(),
      home: ScoreAppProvider(
        getIt: getIt,
        child: const LogInScreen(),
      ),
    );
  }
}
