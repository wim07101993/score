import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score/features/new_score/bloc/create_score_bloc.dart';
import 'package:score/features/new_score/widgets/composers_field.dart';
import 'package:score/features/new_score/widgets/dedication_field.dart';
import 'package:score/features/new_score/widgets/save_button.dart';
import 'package:score/features/new_score/widgets/score_title_field.dart';
import 'package:score/features/new_score/widgets/subtitle_field.dart';
import 'package:score/features/new_score/widgets/tags_field.dart';
import 'package:score/shared/models/score.dart';

class NewScoreForm extends StatefulWidget {
  const NewScoreForm({super.key});

  @override
  State<NewScoreForm> createState() => _NewScoreFormState();
}

class _NewScoreFormState extends State<NewScoreForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _score = EditableScore.empty();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScoreTitleField(value: _score.editableTitle),
          const SizedBox(height: 8),
          SubtitleField(value: _score.editableSubtitle),
          const SizedBox(height: 8),
          DedicationField(value: _score.editableDedication),
          const SizedBox(height: 8),
          ComposersField(values: _score.editableComposers),
          TagsField(values: _score.editableTags),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SaveButton(onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    BlocProvider.of<CreateScoreBloc>(context)
        .add(CreateScoreEvent.save(_score));
  }
}
