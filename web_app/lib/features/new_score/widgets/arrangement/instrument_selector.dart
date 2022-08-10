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
    return EditableListAutocomplete(
      possibleItems: {
        for (final instrument in Instrument.values)
          instrument: instrument.toString()
      },
      controller: instrument,
      // TODO translate
      label: 's.instrumentLabel',
      onRemove: onRemove,
    );
  }
}
