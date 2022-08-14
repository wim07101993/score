import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/instrument.dart';
import 'package:score/shared/widgets/editable_list/editable_list_autocomplete.dart';

class InstrumentSelector extends StatelessWidget {
  const InstrumentSelector({
    super.key,
    required this.instrument,
    required this.onRemove,
  });

  final ValueNotifier<Instrument> instrument;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return EditableListAutocomplete<Instrument>(
      possibleOptions: {
        for (final instrument in Instrument.values)
          instrument: s.getInstrumentName(instrument)
      },
      controller: instrument,
      label: s.instrumentLabel,
      onRemove: onRemove,
      validator: (value) => _validate(s, value),
    );
  }

  Iterable _validate(S s, Instrument? value) sync* {
    if (value == null) {
      yield s.noInstrumentSelectedErrorMessage;
    }
  }
}
