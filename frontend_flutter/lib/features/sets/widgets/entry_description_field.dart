import 'package:flutter/material.dart';

/// The note next to one song of the set.
class EntryDescriptionField extends StatelessWidget {
  const EntryDescriptionField({
    super.key,
    required this.initialValue,
    required this.enabled,
    required this.onSubmitted,
  });

  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'capo 2, second verse only, straight into the next',
      ),
      // On submitted rather than on changed: every one of these is a write of
      // that song, and a write per keystroke is a write per keystroke.
      onFieldSubmitted: onSubmitted,
    );
  }
}
