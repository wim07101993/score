import 'package:flutter/material.dart';

/// What the gig is called.
class const SetTitleField({
  super.key,
  required final TextEditingController controller,
  required final bool enabled,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
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
