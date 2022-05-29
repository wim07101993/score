import 'package:flutter/material.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:score/features/user/widgets/signed_in.dart';
import 'package:score/globals.dart';
import 'package:score/home/widgets/home.dart';
import 'package:score/theme.dart';

class ScoreApp extends StatelessWidget {
  const ScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score',
      theme: lightTheme,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterFireUILocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: const SignedIn(child: Home()),
    );
  }
}
