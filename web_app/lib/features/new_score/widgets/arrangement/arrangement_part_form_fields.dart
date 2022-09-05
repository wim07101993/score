import 'package:flutter/material.dart';
import 'package:score/features/new_score/widgets/arrangement/instrument_selector.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/instrument.dart';
import 'package:score/shared/widgets/editable_list/editable_list.dart';
import 'package:score/shared/widgets/editable_list/editable_list_text_item.dart';
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
        _title(s, part),
        _description(s, part),
        _instruments(s, part),
        _link(s, part),
      ],
    );
  }

  Widget _title(S s, EditableArrangementPart part) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: part.editableDescription,
      builder: (context, description, _) => Text(description.text),
    );
  }

  Widget _description(S s, EditableArrangementPart part) {
    return TextFormFieldWrapper(
      controller: part.editableDescription,
      label: s.descriptionLabel,
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
      label: s.instrumentLabel,
    );
  }

  Widget _link(S s, EditableArrangementPart part) {
    return EditableList<TextEditingController>(
      addButtonText: s.addLink,
      label: s.partLinksLabel,
      maxNumberOfItems: ArrangementPart.maxNumberOfLinks,
      tooManyItemsText:
          s.tooManyLinksErrorMessage(ArrangementPart.maxNumberOfLinks),
      itemFactory: () => TextEditingController(),
      items: part.editableLinks,
      itemBuilder: (context, notifier, index) => EditableListTextItem(
        controller: notifier.value[index],
        label: s.linkToPartLabel,
        validator: ArrangementPart.validateLink,
        onRemove: () => part.editableLinks.removeAt(index),
      ),
    );
  }
}
