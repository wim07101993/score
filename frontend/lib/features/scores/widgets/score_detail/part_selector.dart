import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';

class const PartSelector({
  super.key,
  required final ScoreViewController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.scoreController,
      builder: (context, _) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: controller.parts
            .map(
              (part) => FilterChip(
                label: Text(part.name),
                selected: controller.isPartVisible(part.id),
                onSelected: (visible) =>
                    controller.setPartVisible(part.id, visible),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
