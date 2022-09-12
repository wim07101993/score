import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_text_list.dart';
import 'package:score/shared/widgets/editable_list/text_form_field_wrapper.dart';

class NewScoreForm extends StatefulWidget {
  const NewScoreForm({super.key});

  @override
  State<NewScoreForm> createState() => _NewScoreFormState();
}

class _NewScoreFormState extends State<NewScoreForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final score = context.read<EditableScore>();
    if (score.editableArrangements.isEmpty) {
      score.editableArrangements.add(EditableArrangement.empty());
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(),
              _titleField(s, score),
              const SizedBox(height: 8),
              _subtitle(s, score),
              const SizedBox(height: 8),
              _dedication(s, score),
              const SizedBox(height: 16),
              _composers(s, theme, score),
              const SizedBox(height: 8),
              _tags(s, theme, score),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NextButton(onPressed: () => _next(score)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleField(S s, EditableScore score) {
    return TextFormFieldWrapper(
      controller: score.editableTitle,
      label: s.titleFieldLabel,
      validator: Score.validateTitle,
    );
  }

  Widget _subtitle(S s, EditableScore score) {
    return TextFormFieldWrapper(
      controller: score.editableSubtitle,
      label: s.subtitleFieldLabel,
      validator: Score.validateSubtitle,
    );
  }

  Widget _dedication(S s, EditableScore score) {
    return TextFormFieldWrapper(
      controller: score.editableDedication,
      label: s.dedicationFieldLabel,
      validator: Score.validateDedication,
    );
  }

  Widget _composers(S s, ThemeData theme, EditableScore score) {
    return EditableTextList(
      items: score.editableComposers,
      maxNumberOfItems: Score.maxNumberOfComposers,
      addButtonText: s.addComposer,
      tooManyItemsText:
          s.tooManyComposersErrorMessage(Score.maxNumberOfComposers),
      itemLabel: s.composerFieldLabel,
      label: Text(s.composersLabel, style: theme.textTheme.headline6),
      validator: Score.validateComposer,
    );
  }

  Widget _tags(S s, ThemeData theme, EditableScore score) {
    return EditableTextList(
      items: score.editableTags,
      maxNumberOfItems: Score.maxNumberOfTags,
      addButtonText: s.addTag,
      tooManyItemsText: s.tooManyTagsErrorMessage(Score.maxNumberOfTags),
      itemLabel: s.tagFieldLabel,
      label: Text(s.tagsLabel, style: theme.textTheme.headline6),
      validator: Score.validateTag,
    );
  }

  void _next(EditableScore score) {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    AutoRouter.of(context).push(AddArrangementForm(arrangementIndex: 0));
  }
}
