import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class DedicationField extends StatelessWidget {
  const DedicationField({
    super.key,
    required this.value,
  });

  final TextEditingController value;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return TextFormField(
      controller: value,
      decoration: InputDecoration(
        labelText: s.dedicationFieldLabel,
      ),
    );
  }
}
