import 'package:flutter/material.dart';

/// What there is to say about the collection as a whole.
class CollectionDescriptionField extends StatelessWidget {
  const CollectionDescriptionField({
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
        labelText: 'About the collection',
        hintText: 'what the band can be asked for',
      ),
      onChanged: onChanged,
    );
  }
}
