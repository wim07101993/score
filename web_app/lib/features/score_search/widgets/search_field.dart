import 'package:flutter/material.dart';
import 'package:score/features/score_search/behaviours/search.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final Search _search;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _search = context.getIt();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: _search,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter a search term',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
