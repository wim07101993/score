import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/dedication_field.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/features/new_score/widgets/score_title_field.dart';
import 'package:score/features/new_score/widgets/subtitle_field.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_text_list.dart';

class NewScoreForm extends StatefulWidget {
  const NewScoreForm({super.key});

  @override
  State<NewScoreForm> createState() => _NewScoreFormState();
}

class _NewScoreFormState extends State<NewScoreForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool hasAddedArrangement = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final score = context.read<EditableScore>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(),
              const ScoreTitleField(),
              const SizedBox(height: 8),
              const SubtitleField(),
              const SizedBox(height: 8),
              const DedicationField(),
              const SizedBox(height: 16),
              _composers(s, score),
              const SizedBox(height: 8),
              _tags(s, score),
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

  Widget _composers(S s, EditableScore score) {
    return EditableTextList(
      items: score.editableComposers,
      maxNumberOfItems: Score.maxNumberOfComposers,
      addButtonText: s.addComposer,
      tooManyItemsText:
          s.tooManyComposersErrorMessage(Score.maxNumberOfComposers),
      itemLabel: s.composerFieldLabel,
      label: s.composersLabel,
      validator: Score.validateComposer,
    );
  }

  Widget _tags(S s, EditableScore score) {
    return EditableTextList(
      items: score.editableTags,
      maxNumberOfItems: Score.maxNumberOfTags,
      addButtonText: s.addTag,
      tooManyItemsText: s.tooManyTagsErrorMessage(Score.maxNumberOfTags),
      itemLabel: s.tagFieldLabel,
      label: s.tagsLabel,
      validator: Score.validateTag,
    );
  }

  void _next(EditableScore score) {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (!hasAddedArrangement) {
      score.arrangements.add(EditableArrangement.empty());
      hasAddedArrangement = true;
    }
    AutoRouter.of(context).push(AddArrangementForm(arrangementIndex: 0));
  }
}
