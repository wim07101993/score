import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_part_form_fields.dart';
import 'package:score/features/new_score/widgets/next_button.dart';
import 'package:score/features/new_score/widgets/previous_button.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart' as routes;
import 'package:score/shared/list_notifier.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';

class ArrangementPartForms extends StatefulWidget {
  const ArrangementPartForms({
    super.key,
    required this.arrangementIndex,
  });

  final int arrangementIndex;

  @override
  State<ArrangementPartForms> createState() => _ArrangementPartFormsState();
}

class _ArrangementPartFormsState extends State<ArrangementPartForms> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final arrangements = context.read<EditableScore>().editableArrangements;
    final parts = arrangements[widget.arrangementIndex].editableParts;

    return ValueListenableBuilder<List<EditableArrangement>>(
      valueListenable: arrangements,
      builder: (context, arrangements, _) {
        final canAddAnotherArrangement =
            widget.arrangementIndex >= arrangements.length - 1 &&
                arrangements.length < Score.maxNumberOfArrangements;
        final isLastArrangement =
            widget.arrangementIndex >= arrangements.length - 1;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _parts(s, parts),
                  Row(children: [
                    PreviousButton(
                      onPressed: () => AutoRouter.of(context).pop(),
                    ),
                    const Spacer(),
                    if (canAddAnotherArrangement) ...[
                      _addAnotherArrangementButton(s, arrangements.length),
                      const SizedBox(width: 8),
                    ],
                    if (!isLastArrangement)
                      NextButton(onPressed: _navigateToNextArrangement)
                    else
                      _saveButton(s),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _parts(S s, ListNotifier<EditableArrangementPart> parts) {
    return EditableList<EditableArrangementPart>(
      items: parts,
      itemFactory: () => EditableArrangementPart.empty(),
      maxNumberOfItems: Arrangement.maxNumberOfParts,
      addButtonText: s.addArrangementPart,
      tooManyItemsText:
          s.tooManyArrangementsErrorMessage(Arrangement.maxNumberOfParts),
      label: s.partsLabel,
      itemBuilder: (context, parts, i) => ArrangementPartFormFields(
        part: parts[i],
      ),
    );
  }

  Widget _saveButton(S s) {
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
