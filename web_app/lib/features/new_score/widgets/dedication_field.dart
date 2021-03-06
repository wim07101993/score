import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class DedicationField extends StatelessWidget {
  const DedicationField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: context.read<EditableScore>().editableDedication,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: s.dedicationFieldLabel,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  static String? _validate(S s, String? value) {
    final errors = Score.validateDedication(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
