import 'package:flutter/material.dart';

/// What there is to say about the collection as a whole.
class const CollectionDescriptionField({
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
        labelText: 'About the collection',
        hintText: 'what the band can be asked for',
      ),
      onChanged: onChanged,
    );
  }
}
