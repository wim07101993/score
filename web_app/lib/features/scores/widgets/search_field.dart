import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/change_notifiers/search_string_notifier.dart';
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
      controller: context.read<SearchStringNotifier>(),
      style: const TextStyle(fontSize: 20),
      decoration: InputDecoration(
        fillColor: theme.appBarTheme.foregroundColor,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(32),
        ),
        hintText: s.search,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
