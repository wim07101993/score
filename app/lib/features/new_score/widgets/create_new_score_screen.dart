import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class CreateNewScoreScreen extends StatelessWidget {
  const CreateNewScoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.createNewScore),
      ),
      body: Container(),
    );
  }
}
