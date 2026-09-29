/// Where the app's addresses lead.
///
/// They are the ones the app this replaces used, so a link a player has in
/// their browser or written on a setlist still opens what it always opened —
/// including a link into a set, which carries which set it is and which of its
/// entries, and is what makes a score open in the key the band plays it in.
library;

sealed class AppRoute {
  const AppRoute();

  /// The address this page is at, which is what the browser is left showing.
  String get path;

  /// The pages an address is opened onto, deepest last.
  ///
  /// A link is handed over whole — a score inside a set, say — and what belongs
  /// *behind* that page is a question only this app can answer. Left to itself
  /// a navigator builds a page for every prefix of the path, which here means
  /// `/`, then `/scores`, then the score: the list of scores twice, so leaving
  /// the score arrives at the same list a second time.
  ///
  /// So it is said plainly. Every address has something to go back to, and a
  /// set's score goes back through the set it is being played from.
  static List<AppRoute> stackFor(String? name) {
    final target = parse(name);
    return switch (target) {
      ScoresRoute() => [target],
      SetDetailRoute() => [const ScoresRoute(), const SetsRoute(), target],
      // A score opened out of a set: the set goes behind it, so leaving the
      // score arrives back at the running order it was being played from
      // rather than skipping past it to the list of every score there is.
      CollectionDetailRoute() => [
          const ScoresRoute(),
          const CollectionsRoute(),
          target,
        ],
      ScoreDetailRoute(setId: final setId?) => [
          const ScoresRoute(),
          const SetsRoute(),
          SetDetailRoute(setId: setId),
          target,
        ],
      // And one opened out of a collection goes back through the collection.
      ScoreDetailRoute(collectionId: final collectionId?) => [
          const ScoresRoute(),
          const CollectionsRoute(),
          CollectionDetailRoute(collectionId: collectionId),
          target,
        ],
      _ => [const ScoresRoute(), target],
    };
  }

  /// Reads an address. Anything unrecognised is the list of scores, which is
  /// where the app starts.
  ///
  /// The app this replaces was a set of pages — `/scores/detail.html?id=…`,
  /// `/scores/perform.html?id=…&set=…&entry=…`, `/profile.html` — and those are
  /// what is in players' bookmarks and written on setlists. They are read here
  /// as the pages they always were, rather than `detail.html` being taken for
  /// the id of a score.
  static AppRoute parse(String? name) {
    final uri = Uri.parse(name ?? '/');
    final query = uri.queryParameters;
    final segments = [
      for (final segment in uri.pathSegments)
        if (segment.isNotEmpty && segment != 'index.html') segment,
    ];

    if (segments.isEmpty) {
      return const ScoresRoute();
    }

    switch (segments) {
      case ['scores', 'detail.html']:
        final scoreId = query['id'];
        return scoreId == null
            // The upload button led here without an id.
            ? const ScoreDetailRoute(scoreId: 'new')
            : ScoreDetailRoute(scoreId: scoreId);

      case ['scores', 'perform.html']:
        final scoreId = query['id'];
        final setId = query['set'];
        final collectionId = query['collection'];
        if (scoreId != null) {
          return ScoreDetailRoute(
            scoreId: scoreId,
            setId: setId,
            collectionId: setId == null ? collectionId : null,
            entryId: query['entry'],
          );
        }
        // An entry that has no score yet — a piece still on paper — was
        // opened all the same, to say which piece it is and what it is in.
        // Here that is the running order it is in.
        if (setId != null) return SetDetailRoute(setId: setId);
        if (collectionId != null) {
          return CollectionDetailRoute(collectionId: collectionId);
        }
        return const ScoresRoute();

      case ['scores', final scoreId, ...]:
        final setId = query['set'];
        return ScoreDetailRoute(
          scoreId: scoreId,
          setId: setId,
          collectionId: setId == null ? query['collection'] : null,
          entryId: query['entry'],
        );

      case ['sets', 'detail.html']:
        // The new-set button led here without an id.
        return SetDetailRoute(setId: query['id'] ?? 'new');

      case ['sets', final setId, ...]:
        return SetDetailRoute(setId: setId);

      case ['sets']:
        return const SetsRoute();

      case ['collections', 'detail.html']:
        return CollectionDetailRoute(collectionId: query['id'] ?? 'new');

      case ['collections', final collectionId, ...]:
        return CollectionDetailRoute(collectionId: collectionId);

      case ['collections']:
        return const CollectionsRoute();

      case ['scores']:
      case ['index.html']:
        return const ScoresRoute();

      case ['profile' || 'profile.html']:
        return const ProfileRoute();

      case ['settings' || 'settings.html']:
        return const SettingsRoute();
    }

    return const ScoresRoute();
  }

  /// Handed along with an address a page is swapped for when it has only been
  /// given its name — a new score once it is uploaded, a new set once it is
  /// saved. Nothing moved, so nothing is drawn arriving; what changes is what
  /// the browser shows, so that a reload opens what was just made.
  static const Object renamed = #renamed;

  /// A new score, which has no id until it is uploaded.
  static String newScore() => '/scores/new';

  static String score(
    String scoreId, {
    String? setId,
    String? collectionId,
    String? entryId,
  }) {
    final query = <String, String>{
      'set': ?setId,
      'collection': ?collectionId,
      'entry': ?entryId,
    };
    final path = '/scores/$scoreId';
    return query.isEmpty
        ? path
        : Uri(path: path, queryParameters: query).toString();
  }

  static String set(String setId) => '/sets/$setId';

  static String newSet() => '/sets/new';

  static String collections() => '/collections';

  static String collection(String collectionId) =>
      '/collections/$collectionId';

  static String newCollection() => '/collections/new';
}

class ScoresRoute extends AppRoute {
  const ScoresRoute();

  @override
  String get path => '/';
}

class ScoreDetailRoute extends AppRoute {
  const ScoreDetailRoute({
    required this.scoreId,
    this.setId,
    this.collectionId,
    this.entryId,
  });

  /// `new` for a score that is about to be uploaded and has no id yet.
  final String scoreId;

  /// The set this score is being played from, when it is being played from one.
  final String? setId;

  /// The collection this score is being played from, when it is being played
  /// from one rather than from a set.
  final String? collectionId;

  /// Which of that set's or collection's entries this is.
  ///
  /// An entry is pointed at by its id rather than by where it comes in the set.
  /// An id is the client's to name and stays that entry's for as long as the
  /// entry is in the set, while the place it is played at moves under it every
  /// time somebody reorders the gig — and a link that has been sitting in a
  /// browser since before that would then open the right score and read it out
  /// of the wrong entry.
  final String? entryId;

  @override
  String get path => AppRoute.score(
        scoreId,
        setId: setId,
        collectionId: collectionId,
        entryId: entryId,
      );
}

class SetsRoute extends AppRoute {
  const SetsRoute();

  @override
  String get path => '/sets';
}

class SetDetailRoute extends AppRoute {
  const SetDetailRoute({
    required this.setId,
  });

  /// `new` for a set that has not been saved yet.
  final String setId;

  @override
  String get path => AppRoute.set(setId);
}

class CollectionsRoute extends AppRoute {
  const CollectionsRoute();

  @override
  String get path => AppRoute.collections();
}

class CollectionDetailRoute extends AppRoute {
  const CollectionDetailRoute({
    required this.collectionId,
  });

  /// `new` for a collection that has not been saved yet.
  final String collectionId;

  @override
  String get path => AppRoute.collection(collectionId);
}

class ProfileRoute extends AppRoute {
  const ProfileRoute();

  @override
  String get path => '/profile';
}

/// What this device prefers, as opposed to what the account is. Nothing here
/// leaves the machine, so there is nothing in the address to carry either.
class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  String get path => '/settings';
}
