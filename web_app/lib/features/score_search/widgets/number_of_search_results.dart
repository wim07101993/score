import 'package:flutter/material.dart';
import 'package:score/features/score_search/models/search_result.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';
import 'package:score/shared/dependency_management/global_value.dart';

class NumberOfSearchResults extends StatelessWidget {
  const NumberOfSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SearchResult?>(
      valueListenable: GlobalValueListenable(
        globalValue: context.getIt<SearchResultValue>(),
      ),
      builder: (context, value, _) => value == null
          ? const SizedBox()
          : Text(
              'Found ${value.numberOfHits} scores',
              textAlign: TextAlign.right,
            ),
    );
  }
}
