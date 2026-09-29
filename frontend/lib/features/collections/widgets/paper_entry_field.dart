import 'package:flutter/material.dart';

/// The name of a piece that is in the book but not in here — one that has yet
/// to be scanned.
///
/// What is typed is what it is called, and it is all it will ever be called
/// until somebody scans it. Pressing enter adds it, because typing one line
/// after another is how a list like this is filled in.
class PaperEntryField extends StatelessWidget {
  const PaperEntryField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Blue Bossa — page 62',
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
