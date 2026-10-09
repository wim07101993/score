/// Where the app's addresses lead.
///
/// A link a player has in their browser or written on a setlist opens what it
/// was made for — including a link into a set, which carries which set it is
/// and which of its entries, and is what makes a score open in the key the
/// band plays it in.
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:score/features/auth/widgets/profile_page.dart';
import 'package:score/features/collections/widgets/collection_detail_page.dart';
import 'package:score/features/collections/widgets/collections_page.dart';
import 'package:score/features/observability/widgets/logs_page.dart';
import 'package:score/features/scores/widgets/score_detail_page.dart';
import 'package:score/features/scores/widgets/score_pages.dart';
import 'package:score/features/scores/widgets/scores_page.dart';
import 'package:score/features/sets/widgets/set_detail_page.dart';
import 'package:score/features/sets/widgets/sets_page.dart';
import 'package:score/features/settings/widgets/settings_page.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ScoresRoute.page, path: '/', initial: true),
    RedirectRoute(path: '/scores', redirectTo: '/'),
    // Before the score's own address, which would otherwise be taken for
    // the start of this one.
    _detail(PerformScoreRoute.page, '/scores/:scoreId/perform'),
    _detail(ScoreRoute.page, '/scores/:scoreId'),
    AutoRoute(page: SetsRoute.page, path: '/sets'),
    _detail(SetDetailRoute.page, '/sets/:setId'),
    AutoRoute(page: CollectionsRoute.page, path: '/collections'),
    _detail(CollectionDetailRoute.page, '/collections/:collectionId'),
    AutoRoute(page: ProfileRoute.page, path: '/profile'),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: LogsRoute.page, path: '/settings/logs'),
    // Anything unrecognised is the list of scores, which is where the app
    // starts.
    RedirectRoute(path: '*', redirectTo: '/'),
  ];

  /// A page that is one of many at the same kind of address — a score, a set
  /// or a collection. Each address is a page of its own: the next song of a
  /// set is a new page, not the last one told it is about another song.
  static AutoRoute _detail(PageInfo page, String path) =>
      AutoRoute(page: page, path: path, usesPathAsKey: true);

  /// What the app opens onto when it is handed [address]: see [stackAt].
  DeepLink deepLinkTo(String address) => DeepLink(stackAt(address));

  /// The pages [address] is opened onto, deepest last: see [stackFor].
  List<PageRouteInfo> stackAt(String address) {
    final uri = Uri.tryParse(address) ?? _scores;
    final match = matcher.matchUri(readable(uri))?.lastOrNull;
    return match == null
        ? const [ScoresRoute()]
        : stackFor(match.toPageRouteInfo());
  }

  /// The address [route] is at, which is what the browser is left showing.
  String pathOf(PageRouteInfo route) =>
      UrlState.fromSegments([matcher.buildPathTo(route)!]).url;

  /// [uri], or the address of the list of scores when [uri] cannot be read.
  ///
  /// An address that is not one — a link mangled on its way here, escapes that
  /// are not UTF-8 — is still an address the app was opened at, and throwing
  /// on it would leave nothing on screen at all.
  static Uri readable(Uri uri) {
    try {
      uri
        ..pathSegments
        ..queryParameters;
      return uri;
    } on FormatException {
      return _scores;
    }
  }

  static final _scores = Uri(path: '/');

  /// The pages [target] is opened onto, deepest last.
  ///
  /// A link is handed over whole — a score inside a set, say — and what belongs
  /// *behind* that page is a question only this app can answer. Left to itself
  /// a router builds a page for every prefix of the path, which here means
  /// `/`, then the score: leaving a score that was played from a set would
  /// skip past the set to the list of every score there is.
  ///
  /// So it is said plainly. Every address has something to go back to, and a
  /// set's score goes back through the set it is being played from.
  @visibleForTesting
  static List<PageRouteInfo> stackFor(PageRouteInfo target) {
    final query = target.rawQueryParams;
    final setId = query['set'] as String?;
    final collectionId = query['collection'] as String?;
    return switch (target.routeName) {
      ScoresRoute.name => [target],
      SetsRoute.name || CollectionsRoute.name => [const ScoresRoute(), target],
      SetDetailRoute.name => [const ScoresRoute(), const SetsRoute(), target],
      CollectionDetailRoute.name => [
        const ScoresRoute(),
        const CollectionsRoute(),
        target,
      ],
      // A score opened out of a set: the set goes behind it, so leaving the
      // score arrives back at the running order it was being played from
      // rather than skipping past it to the list of every score there is.
      ScoreRoute.name || PerformScoreRoute.name when setId != null => [
        const ScoresRoute(),
        const SetsRoute(),
        SetDetailRoute(setId: setId),
        target,
      ],
      // And one opened out of a collection goes back through the collection.
      ScoreRoute.name || PerformScoreRoute.name when collectionId != null => [
        const ScoresRoute(),
        const CollectionsRoute(),
        CollectionDetailRoute(collectionId: collectionId),
        target,
      ],
      // A score played on its own is left for its details, which is where it
      // was played from.
      PerformScoreRoute.name => [
        const ScoresRoute(),
        ScoreRoute(scoreId: target.rawPathParams['scoreId'] as String),
        target,
      ],
      _ => [const ScoresRoute(), target],
    };
  }
}

/// The address of an entry of a set or a collection that is played from
/// paper, and has no score to open. It is opened all the same, in its place in
/// the running order: skipping it would have the player looking at the next
/// song while the band plays this one.
PerformScoreRoute paperRoute({
  String? setId,
  String? collectionId,
  required String entryId,
}) => PerformScoreRoute(
  scoreId: ScoreDetailPage.paper,
  setId: setId,
  collectionId: collectionId,
  entryId: entryId,
);

/// A score's details, or the score on the stand when [performing].
PageRouteInfo scoreRoute(
  String scoreId, {
  String? setId,
  String? collectionId,
  String? entryId,
  bool performing = false,
}) => performing
    ? PerformScoreRoute(
        scoreId: scoreId,
        setId: setId,
        collectionId: collectionId,
        entryId: entryId,
      )
    : ScoreRoute(
        scoreId: scoreId,
        setId: setId,
        collectionId: collectionId,
        entryId: entryId,
      );
