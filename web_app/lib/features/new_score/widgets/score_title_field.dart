import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class ScoreTitleField extends StatelessWidget {
  const ScoreTitleField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: context.read<EditableScore>().editableTitle,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: s.titleFieldLabel,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  static String? _validate(S s, String? value) {
    final errors = Score.validateTitle(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
