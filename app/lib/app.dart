import 'package:flutter/material.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:score/features/developer_options/widgets/logs_page.dart';
import 'package:score/features/user/widgets/logged_in.dart';
import 'package:score/globals.dart';

class ScoreApp extends StatelessWidget {
  const ScoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score',
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterFireUILocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: LoggedIn(
        builder: (context, user) => Navigator(
          pages: const [
            LogsPage(),
          ],
          onPopPage: (route, result) => route.didPop(result),
        ),
      ),
    );
  }
}
