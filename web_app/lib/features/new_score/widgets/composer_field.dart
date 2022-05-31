import 'package:flutter/material.dart';
import 'package:score/features/new_score/models/draft_score.dart';
import 'package:score/globals.dart';

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

  String? _validate(S s, String? value) {
    final errors = DraftScore.validateComposer(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map((e) => e.getMessage(s)).join("\r\n");
  }
}
