import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/way/next_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/previous_score_button.dart';
import 'package:score/features/scores/widgets/score_detail/way/way_through.dart';

/// The way through the set in the middle of the stand's bar, the way it was in
/// a bar of its own: the song before, which song this is, and the song after.
///
/// Played from a set or a collection, the way through it is in the same bar
/// rather than a second one under it: a bar is a staff's worth of height,
/// and on a stand that is a staff of music not shown. The title says which
/// set it is and where this song comes in it, and opens the set.
class const StandTitle({
  super.key,
  required final String title,
  required final WayThrough way,
  required final void Function(PageRouteInfo route) onGo,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = way.previous;
    final next = way.next;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PreviousScoreButton(
          onPressed: previous == null ? null : () => onGo(previous),
        ),
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.router.push(way.route),
            child: Tooltip(
              message: way.isSet ? 'Open the set' : 'Open the collection',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, overflow: TextOverflow.ellipsis),
                    Text(
                      [
                        '${way.position} of ${way.count}',
                        way.title,
                        if (way.note.isNotEmpty) way.note,
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        NextScoreButton(
          onPressed: next == null ? null : () => onGo(next),
        ),
      ],
    );
  }
}
