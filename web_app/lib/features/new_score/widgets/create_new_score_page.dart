import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide CloseButton;
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/features/new_score/widgets/close_button.dart';
import 'package:score/shared/models/score.dart';

class CreateNewScorePage extends StatelessWidget {
  const CreateNewScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final getIt = context.read<GetIt>();
    return MultiProvider(
      providers: [
        Provider(create: (_) => getIt<EditableScore>()),
        Provider(create: (_) => getIt<SaveNewScore>()),
      ],
      child: Stack(children: const [
        AutoRouter(),
        Align(
          alignment: Alignment.topRight,
          child: CloseButton(),
        ),
      ]),
    );
  }

  // TODO move this
  // void onStateChange(BuildContext context, CreateScoreWizardState state) {
  //   final error = state.error;
  //   if (error != null) {
  //     late final String errorMessage;
  //     if (error is PermissionDeniedException) {
  //       errorMessage = error.errorMessage(context);
  //     } else if (state.error != null) {
  //       errorMessage = S.of(context)!.genericErrorMessage;
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text(errorMessage),
  //     ));
  //   }
  //
  //   if (state.created) {
  //     Navigator.of(context).pop();
  //   }
  // }
}
