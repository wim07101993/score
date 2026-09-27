import 'package:flutter/material.dart';

/// What there is to say about the gig.
class SetDescriptionField extends StatelessWidget {
  const SetDescriptionField({
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
