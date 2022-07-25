import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_description_field.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_name.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_name_field.dart';
import 'package:score/features/new_score/widgets/arrangement/arrangement_part_form_fields.dart';
import 'package:score/features/new_score/widgets/page_title.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/score.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';
import 'package:score/shared/widgets/editable_list/editable_text_list.dart';

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
    final arrangement = context
        .read<EditableScore>()
        .editableArrangements[widget.arrangementIndex];

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
                const ArrangementNameField(),
                const SizedBox(height: 8),
                const ArrangementDescriptionField(),
                const SizedBox(height: 8),
                _arrangers(s, arrangement),
                const SizedBox(height: 8),
                _lyricists(s, arrangement),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _parts(s, arrangement),
              ],
            ),
          ),
        ),
      ),
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
      itemBuilder: (context, arrangements, i) => ArrangementPartFormFields(
        part: arrangements[i],
      ),
      maxNumberOfItems: Arrangement.maxNumberOfParts,
      addButtonText: s.addArrangementPart,
      tooManyItemsText:
          s.tooManyArrangementsErrorMessage(Arrangement.maxNumberOfParts),
      label: s.partsLabel,
    );
  }
}
