import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_name.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/features/new_score/widgets/previous_button.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart' as routes;
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_text_list.dart';
import 'package:score/shared/widgets/editable_list/text_form_field_wrapper.dart';

class AddArrangementForm extends StatefulWidget {
  const AddArrangementForm({
    Key? key,
    required this.arrangementIndex,
  }) : super(key: key);

  final int arrangementIndex;

  @override
  State<AddArrangementForm> createState() => _AddArrangementFormState();
}

class _AddArrangementFormState extends State<AddArrangementForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final arrangements = context.read<EditableScore>().editableArrangements;
    final arrangement = arrangements[widget.arrangementIndex];

    return Provider<EditableArrangement>.value(
      value: arrangement,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const PageTitle(),
                const ArrangementName(),
                const SizedBox(height: 8),
                _arrangementName(s, arrangement),
                const SizedBox(height: 8),
                _arrangementDescription(s, arrangement),
                const SizedBox(height: 8),
                _arrangers(s, theme, arrangement),
                const SizedBox(height: 8),
                _lyricists(s, theme, arrangement),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [
                  PreviousButton(
                    onPressed: () => AutoRouter.of(context).pop(),
                  ),
                  const Spacer(),
                  NextButton(onPressed: _navigateToParts),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrangementName(S s, EditableArrangement arrangement) {
    return TextFormFieldWrapper(
      controller: arrangement.editableName,
      label: s.arrangementNameFieldName,
      validator: Arrangement.validateName,
    );
  }

  Widget _arrangementDescription(S s, EditableArrangement arrangement) {
    return TextFormFieldWrapper(
      controller: arrangement.editableDescription,
      label: s.arrangementDescriptionFieldName,
      validator: Arrangement.validateDescription,
    );
  }

  Widget _arrangers(S s, ThemeData theme, EditableArrangement arrangement) {
    return EditableTextList(
      items: arrangement.editableArrangers,
      maxNumberOfItems: Arrangement.maxNumberOfArrangers,
      addButtonText: s.addArranger,
      tooManyItemsText:
          s.tooManyArrangersErrorMessage(Arrangement.maxNumberOfArrangers),
      itemLabel: s.arrangerFieldLabel,
      label: Text(s.arrangersLabel, style: theme.textTheme.headline6),
      validator: Arrangement.validateArranger,
    );
  }

  Widget _lyricists(S s, ThemeData theme, EditableArrangement arrangement) {
    return EditableTextList(
      items: arrangement.editableLyricists,
      maxNumberOfItems: Arrangement.maxNumberOfLyricists,
      addButtonText: s.addLyricist,
      tooManyItemsText:
          s.tooManyLyricistsErrorMessage(Arrangement.maxNumberOfLyricists),
      itemLabel: s.lyricistFieldLabel,
      label: Text(s.lyricistsLabel, style: theme.textTheme.headline6),
      validator: Arrangement.validateLyricist,
    );
  }

  void _navigateToParts() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    AutoRouter.of(context).push(
      routes.ArrangementPartForms(arrangementIndex: widget.arrangementIndex),
    );
  }
}
