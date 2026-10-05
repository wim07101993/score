import 'package:flutter/material.dart';

/// What there is to say about the gig.
class const SetDescriptionField({
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
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'About the gig',
        hintText: 'two sets of forty minutes, break at ten',
      ),
      onChanged: onChanged,
    );
  }
}
