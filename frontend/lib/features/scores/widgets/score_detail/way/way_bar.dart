import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/way/next_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/open_collection_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/open_set_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/previous_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/way_through.dart';

/// The way through the set or the collection, as a bar of its own under the
/// details of a score.
class const WayBar({
  super.key,
  required final WayThrough way,

  /// Opens the page at a route in place of this one.
  required final void Function(PageRouteInfo route) go,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = way.previous;
    final next = way.next;
    void open() => context.router.push(way.route);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            PreviousScoreButton(
              onPressed: previous == null ? null : () => go(previous),
            ),
            // Flexible, so that a long title gives way rather than pushing the
            // way to the next one off the edge of a phone.
            Flexible(
              child: way.isSet
                  ? OpenSetButton(title: way.title, onPressed: open)
                  : OpenCollectionButton(title: way.title, onPressed: open),
            ),
            Text(
              '${way.position} of ${way.count}',
              style: theme.textTheme.labelMedium,
            ),
            NextScoreButton(
              onPressed: next == null ? null : () => go(next),
            ),
            if (way.note.isNotEmpty)
              Expanded(
                child: Text(
                  way.note,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
