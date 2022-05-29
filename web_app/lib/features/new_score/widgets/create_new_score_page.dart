import 'package:flutter/material.dart' hide CloseButton;
import 'package:score/features/new_score/widgets/close_button.dart';
import 'package:score/features/new_score/widgets/new_score_form.dart';
import 'package:score/features/new_score/widgets/page_title.dart';

class CreateNewScorePage extends StatelessWidget {
  const CreateNewScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PageTitle(),
          NewScoreForm(),
        ],
      ),
      const Align(
        alignment: Alignment.topRight,
        child: CloseButton(),
      ),
    ]);
  }
}
