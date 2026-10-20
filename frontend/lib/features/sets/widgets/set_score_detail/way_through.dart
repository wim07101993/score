import 'package:auto_route/auto_route.dart';

/// The way through the set a score is played from: where
/// this one comes in it, and what comes either side.
class const WayThrough({
  /// What the set is called, and where it is.
  required final String title,
  required final PageRouteInfo route,

  /// Where this one comes in it, counted from one, and how many there are.
  required final int position,
  required final int count,

  /// Where the ones either side are, or null at either end.
  required final PageRouteInfo? previous,
  required final PageRouteInfo? next,

  /// What the set says next to this one.
  required final String note,
});
