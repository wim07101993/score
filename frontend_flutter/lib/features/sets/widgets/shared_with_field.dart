import 'package:flutter/material.dart';

/// Who may read the set: one address per line.
class SharedWithField extends StatelessWidget {
  const SharedWithField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      decoration: const InputDecoration(
        hintText: 'bas@example.com',
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
