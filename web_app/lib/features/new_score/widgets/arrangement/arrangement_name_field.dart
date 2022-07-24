import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/arrangement.dart';

class ArrangementNameField extends StatelessWidget {
  const ArrangementNameField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: context.read<EditableArrangement>().editableName,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: s.arrangementNameFieldName,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  static String? _validate(S s, String? value) {
    final errors = Arrangement.validateName(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
