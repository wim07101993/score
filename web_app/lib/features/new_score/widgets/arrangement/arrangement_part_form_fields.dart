import 'package:flutter/material.dart';
import 'package:score/features/new_score/widgets/arrangement/instrument_selector.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/instrument.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';
import 'package:score/shared/widgets/editable_list/text_form_field_wrapper.dart';

class ArrangementPartFormFields extends StatelessWidget {
  const ArrangementPartFormFields({
    Key? key,
    required this.part,
  }) : super(key: key);

  final EditableArrangementPart part;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Column(
      children: [
        _description(s, part),
        _instruments(s, part),
      ],
    );
  }

  Widget _description(S s, EditableArrangementPart part) {
    return TextFormFieldWrapper(
      controller: part.editableDescription,
      // TODO translations
      label: 's.descriptionLabel',
      validator: ArrangementPart.validateDescription,
    );
  }

  Widget _instruments(S s, EditableArrangementPart part) {
    return EditableList<ValueNotifier<Instrument>>(
      items: part.editableInstruments,
      itemFactory: () => ValueNotifier(Instrument.singer),
      itemBuilder: (context, instrument, index) => InstrumentSelector(
        instrument: part.editableInstruments[index],
        onRemove: () => part.editableInstruments.removeAt(index),
      ),
      maxNumberOfItems: ArrangementPart.maxNumberOfInstruments,
      addButtonText: s.addInstrument,
      tooManyItemsText: s.tooManyInstrumentsErrorMessage(
        ArrangementPart.maxNumberOfInstruments,
      ),
      label: 's.instrumentLabel',
    );
  }
}
