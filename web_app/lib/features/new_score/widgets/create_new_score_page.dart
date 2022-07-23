import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide CloseButton;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/new_score/bloc/create_score_wizard_bloc.dart';
import 'package:score/features/new_score/widgets/close_button.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/globals.dart';
import 'package:score/shared/data/firebase/exceptions/permission_denied_exception.dart';

class CreateNewScorePage extends StatelessWidget {
  const CreateNewScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateScoreWizardBloc>(
      create: (_) => context.read<GetIt>()(),
      child: BlocListener<CreateScoreWizardBloc, CreateScoreWizardState>(
        listener: onStateChange,
        child: Stack(children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  PageTitle(),
                  IntrinsicHeight(child: AutoRouter()),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topRight,
            child: CloseButton(),
          ),
        ]),
      ),
    );
  }

  void onStateChange(BuildContext context, CreateScoreWizardState state) {
    final error = state.error;
    if (error != null) {
      late final String errorMessage;
      if (error is PermissionDeniedException) {
        errorMessage = error.errorMessage(context);
      } else if (state.error != null) {
        errorMessage = S.of(context)!.genericErrorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    }

    if (state.created) {
      Navigator.of(context).pop();
    }
  }
}
