import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score/features/new_score/bloc/create_score_wizard_bloc.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class PageTitle extends StatefulWidget {
  const PageTitle({super.key});

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  late EditableScore score = context.read<CreateScoreWizardBloc>().state.score;
  String title = '';

  @override
  void initState() {
    super.initState();
    score.editableTitle.addListener(onTitleChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onTitleChanged();
  }

  @override
  void dispose() {
    super.dispose();
    score.editableTitle.removeListener(onTitleChanged);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<CreateScoreWizardBloc, CreateScoreWizardState>(
      listener: onStateChanged,
      child: Text(
        title,
        style: theme.textTheme.headline4,
        textAlign: TextAlign.center,
      ),
    );
  }

  void onTitleChanged() {
    var newTitle = score.title;
    if (newTitle.isEmpty) {
      newTitle = S.of(context)!.newScoreTitle;
    }
    if (newTitle != title) {
      setState(() => title = newTitle);
    }
  }

  void onStateChanged(BuildContext context, CreateScoreWizardState state) {
    score.editableTitle.removeListener(onTitleChanged);
    score = state.score;
    score.editableTitle.addListener(onTitleChanged);
  }
}
