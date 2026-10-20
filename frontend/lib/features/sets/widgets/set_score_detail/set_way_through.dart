import 'package:auto_route/auto_route.dart';
import 'package:score/features/sets/widgets/set_score_detail/set_context.dart';
import 'package:score/features/sets/widgets/set_score_detail/way_through.dart';
import 'package:score/router.dart';

/// The way through a set, in its running order.
///
/// The next song either way, one played from paper included. That is not
/// stepped over: it is what the band is playing, and a player looking at the
/// song after it is lost when the band starts that one.
WayThrough setWayThrough({
  required SetContext context,
  required bool performing,
}) {
  final set = context.set;
  PageRouteInfo? nearest(int step) {
    final index = context.index + step;
    if (index < 0 || index >= set.entries.length) return null;
    return SetEntryRoute(
      setId: set.id,
      entryId: set.entries[index].id,
      isPerforming: performing ? true : null,
    );
  }

  return WayThrough(
    title: set.displayTitle,
    route: SetDetailRoute(setId: set.id),
    position: context.index + 1,
    count: set.entries.length,
    previous: nearest(-1),
    next: nearest(1),
    note: context.entry.description.trim(),
  );
}
