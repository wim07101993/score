import 'package:flutter/material.dart';

/// What the gig is called.
class SetTitleField extends StatelessWidget {
  const SetTitleField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Zomerbar 12 juli',
      ),
      onChanged: onChanged,
    );
  }
}
