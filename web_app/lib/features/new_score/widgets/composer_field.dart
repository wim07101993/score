import 'package:flutter/material.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class ComposerField extends StatelessWidget {
  const ComposerField({
    super.key,
    required this.value,
  });

  final TextEditingController value;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: value,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: s.composerFieldLabel,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  static String? _validate(S s, String? value) {
    final errors = Score.validateComposer(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
