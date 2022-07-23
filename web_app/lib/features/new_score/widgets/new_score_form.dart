import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score/features/new_score/bloc/create_score_wizard_bloc.dart';
import 'package:score/features/new_score/widgets/composers_field.dart';
import 'package:score/features/new_score/widgets/dedication_field.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/score_title_field.dart';
import 'package:score/features/new_score/widgets/subtitle_field.dart';
import 'package:score/features/new_score/widgets/tags_field.dart';

class NewScoreForm extends StatefulWidget {
  const NewScoreForm({super.key});

  @override
  State<NewScoreForm> createState() => _NewScoreFormState();
}

class _NewScoreFormState extends State<NewScoreForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateScoreWizardBloc, CreateScoreWizardState>(
      builder: buildWithState,
    );
  }

  Widget buildWithState(BuildContext context, CreateScoreWizardState state) {
    final score = state.score;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScoreTitleField(value: score.editableTitle),
          const SizedBox(height: 8),
          SubtitleField(value: score.editableSubtitle),
          const SizedBox(height: 8),
          DedicationField(value: score.editableDedication),
          const SizedBox(height: 8),
          ComposersField(values: score.editableComposers),
          TagsField(values: score.editableTags),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: NextButton(onPressed: _next),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    BlocProvider.of<CreateScoreWizardBloc>(context)
        .add(const CreateScoreWizardEvent.save());
  }
}
