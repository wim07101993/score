import 'package:flutter/material.dart' hide CloseButton;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/new_score/bloc/create_score_bloc.dart';
import 'package:score/features/new_score/widgets/close_button.dart';
import 'package:score/features/new_score/widgets/new_score_form.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/globals.dart';

class CreateNewScorePage extends StatelessWidget {
  const CreateNewScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateScoreBloc>(
      create: (_) => context.read<GetIt>()(),
      child: BlocListener<CreateScoreBloc, CreateScoreState>(
        listener: onStateChange,
        child: Stack(children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  PageTitle(),
                  NewScoreForm(),
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

  void onStateChange(BuildContext context, CreateScoreState state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context)!.genericErrorMessage),
      ));
    }
  }
}