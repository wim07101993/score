import 'package:flutter/material.dart';

import 'features/user/widgets/log_in_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LogInScreen(),
    );
  }
}
