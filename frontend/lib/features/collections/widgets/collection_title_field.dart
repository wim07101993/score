import 'package:flutter/material.dart';

/// What the book, or the repertoire, is called.
class CollectionTitleField extends StatelessWidget {
  const CollectionTitleField({
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
        hintText: 'The Real Book, vol. 1',
      ),
      onChanged: onChanged,
    );
  }
}
