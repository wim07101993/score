import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score/features/new_score/bloc/create_score_bloc.dart';
import 'package:score/features/new_score/widgets/composers_field.dart';
import 'package:score/features/new_score/widgets/dedication_field.dart';
import 'package:score/features/new_score/widgets/save_button.dart';
import 'package:score/features/new_score/widgets/score_title_field.dart';
import 'package:score/features/new_score/widgets/subtitle_field.dart';

class NewScoreForm extends StatefulWidget {
  const NewScoreForm({super.key});

  @override
  State<NewScoreForm> createState() => _NewScoreFormState();
}

class _NewScoreFormState extends State<NewScoreForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _scoreTitle = TextEditingController();
  final TextEditingController _subtitle = TextEditingController();
  final TextEditingController _dedication = TextEditingController();
  final List<TextEditingController> _composers = List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScoreTitleField(value: _scoreTitle),
          SubtitleField(value: _subtitle),
          DedicationField(value: _dedication),
          _composersField(),
          SaveButton(onPressed: _save),
        ],
      ),
    );
  }

  Widget _composersField() {
    return ComposersField(
      values: _composers,
      addComposer: () {
        setState(() => _composers.add(TextEditingController()));
      },
      removeComposer: (index) {
        setState(() => _composers.removeAt(index));
      },
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    BlocProvider.of<CreateScoreBloc>(context).add(CreateScoreEvent.save(
      title: _scoreTitle.text,
      dedication: _dedication.text,
      subtitle: _subtitle.text,
      composers: _composers.map((c) => c.text).toList(growable: false),
    ));
  }
}
