import 'package:flutter/material.dart';

/// What is typed to narrow a list of scores down.
///
/// The same field wherever scores are picked from, so that what may be typed
/// into one of them is what may be typed into all of them.
class ScoreSearchField extends StatelessWidget {
  const ScoreSearchField({
    super.key,
    this.controller,
    required this.onChanged,
  });

  final TextEditingController? controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'title, creator or tag',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
