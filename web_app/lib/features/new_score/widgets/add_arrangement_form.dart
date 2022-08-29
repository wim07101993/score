import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_name.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_part_form_fields.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/features/new_score/widgets/previous_button.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart' as routes;
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';
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
  bool hasAddedArrangement = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final arrangements = context.read<EditableScore>().editableArrangements;
    final arrangement = arrangements[widget.arrangementIndex];

    return Provider<EditableArrangement>.value(
      value: arrangement,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: ValueListenableBuilder<List<EditableArrangement>>(
                valueListenable: arrangements,
                builder: (context, value, _) {
                  print('notify ${widget.arrangementIndex}');
                  return Column(
                    children: [
                      const PageTitle(),
                      const ArrangementName(),
                      const SizedBox(height: 8),
                      _arrangementName(s, arrangement),
                      const SizedBox(height: 8),
                      _arrangementDescription(s, arrangement),
                      const SizedBox(height: 8),
                      _arrangers(s, arrangement),
                      const SizedBox(height: 8),
                      _lyricists(s, arrangement),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      _parts(s, arrangement),
                      Row(children: [
                        PreviousButton(
                          onPressed: () => AutoRouter.of(context).pop(),
                        ),
                        const Spacer(),
                        if (widget.arrangementIndex ==
                                arrangements.length - 1 &&
                            arrangements.length <
                                Score.maxNumberOfArrangements) ...[
                          _addAnotherArrangementButton(s, arrangements.length),
                          const SizedBox(width: 8),
                        ],
                        if (widget.arrangementIndex < arrangements.length - 2)
                          NextButton(onPressed: _navigateToNextArrangement)
                        else
                          _saveButton(s),
                      ]),
                    ],
                  );
                }),
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

  Widget _arrangers(S s, EditableArrangement arrangement) {
    return EditableTextList(
      items: arrangement.editableArrangers,
      maxNumberOfItems: Arrangement.maxNumberOfArrangers,
      addButtonText: s.addArranger,
      tooManyItemsText:
          s.tooManyArrangersErrorMessage(Arrangement.maxNumberOfArrangers),
      itemLabel: s.arrangerFieldLabel,
      label: s.arrangersLabel,
      validator: Arrangement.validateArranger,
    );
  }

  Widget _lyricists(S s, EditableArrangement arrangement) {
    return EditableTextList(
      items: arrangement.editableLyricists,
      maxNumberOfItems: Arrangement.maxNumberOfLyricists,
      addButtonText: s.addLyricist,
      tooManyItemsText:
          s.tooManyLyricistsErrorMessage(Arrangement.maxNumberOfLyricists),
      itemLabel: s.lyricistFieldLabel,
      label: s.lyricistsLabel,
      validator: Arrangement.validateLyricist,
    );
  }

  Widget _parts(S s, EditableArrangement arrangement) {
    return EditableList<EditableArrangementPart>(
      items: arrangement.editableParts,
      itemFactory: () => EditableArrangementPart.empty(),
      itemBuilder: (context, parts, i) => ArrangementPartFormFields(
        part: parts[i],
      ),
      maxNumberOfItems: Arrangement.maxNumberOfParts,
      addButtonText: s.addArrangementPart,
      tooManyItemsText:
          s.tooManyArrangementsErrorMessage(Arrangement.maxNumberOfParts),
      label: s.partsLabel,
    );
  }

  Widget _saveButton(S s) {
    final s = S.of(context)!;
    return ElevatedButton(
      onPressed: _save,
      child: Text(s.save),
    );
  }

  Widget _addAnotherArrangementButton(S s, int arrangementsLength) {
    return TextButton(
      onPressed: () {
        AutoRouter.of(context).push(routes.AddArrangementForm(
          arrangementIndex: arrangementsLength,
        ));
      },
      // TODO translations
      child: const Text('s.addAnotherArrangementButtonLabel'),
    );
  }

  void _navigateToNextArrangement() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    AutoRouter.of(context).push(routes.AddArrangementForm(
      arrangementIndex: widget.arrangementIndex + 1,
    ));
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    // TODO
    // AutoRouter.of(context).push()
  }
}
