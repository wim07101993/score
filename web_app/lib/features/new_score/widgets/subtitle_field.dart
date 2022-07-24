import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/globals.dart';
import 'package:score/shared/models/score.dart';

class SubtitleField extends StatelessWidget {
  const SubtitleField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: context.read<EditableScore>().editableSubtitle,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: s.subtitleFieldLabel,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  String? _validate(S s, String? value) {
    final errors = Score.validateSubtitle(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
