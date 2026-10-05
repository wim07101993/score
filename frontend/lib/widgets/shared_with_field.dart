import 'package:flutter/material.dart';

/// Who may read a set or a collection: one address per line.
class const SharedWithField({
  super.key,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
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
