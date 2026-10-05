import 'package:flutter/material.dart';

/// What the book, or the repertoire, is called.
class const CollectionTitleField({
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
        hintText: 'The Real Book, vol. 1',
      ),
      onChanged: onChanged,
    );
  }
}
