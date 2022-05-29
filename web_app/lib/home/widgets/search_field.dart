import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return TextField(
      decoration: InputDecoration(
        fillColor: theme.appBarTheme.foregroundColor,
        filled: true,
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        hintText: s.search,
        prefixIcon: const Icon(Icons.search),
      ),
      style: const TextStyle(fontSize: 20),
    );
  }
}
