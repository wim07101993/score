import 'package:flutter/material.dart';
import 'package:songbird_score/songbird_score.dart';

class const PartSelector({
  super.key,
  required final ValueNotifier<Map<String, dynamic>> controller,
  required final Score score,
}) extends StatelessWidget {
  void setPartVisibility(String partId, bool? shouldBeVisible) {
    if (shouldBeVisible == true) {
      controller.value = {
        for (final entry in controller.value.entries) entry.key: entry.value,
        partId: shouldBeVisible ?? false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, partVisibilities, _) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final part in score.parts)
            FilterChip(
              label: Text(part.name),
              selected: partVisibilities[part.id] != false,
              onSelected: (value) => setPartVisibility(part.id, value),
            ),
        ],
      ),
    );
  }
}
