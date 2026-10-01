import 'package:flutter/material.dart';

/// The name of a piece that is played from paper: in a book, one that has yet
/// to be scanned; in a set, one the band has on paper and nowhere else.
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
    this.hintText = 'Blue Bossa — page 62',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
