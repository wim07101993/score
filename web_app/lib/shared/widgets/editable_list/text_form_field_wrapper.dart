import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class TextFormFieldWrapper extends StatelessWidget {
  const TextFormFieldWrapper({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final Iterable Function(String? value) validator;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: controller,
      validator: (value) => _validate(s, value),
      decoration: InputDecoration(
        labelText: label,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  String? _validate(S s, String? value) {
    final errors = validator(value).toList(growable: false);
    if (errors.isEmpty) {
      return null;
    }

    return errors.map(s.getErrorMessage).join("\r\n");
  }
}
