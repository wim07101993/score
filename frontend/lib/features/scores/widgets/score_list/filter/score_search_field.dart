import 'package:flutter/material.dart';

/// What is typed to narrow a list of scores down.
///
/// The same field wherever scores are picked from, so that what may be typed
/// into one of them is what may be typed into all of them.
class const ScoreSearchField({
  super.key,
  required final TextEditingController controller,
}) extends StatelessWidget {
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
    );
  }
}
