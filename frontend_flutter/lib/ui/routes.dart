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
      _ => [const ScoresRoute(), target],
    };
  }

  /// Reads an address. Anything unrecognised is the list of scores, which is
  /// where the app starts.
  static AppRoute parse(String? name) {
    final uri = Uri.parse(name ?? '/');
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return const ScoresRoute();
    }

    switch (segments.first) {
      case 'scores':
        if (segments.length >= 2) {
          return ScoreDetailRoute(
            scoreId: segments[1],
            setId: uri.queryParameters['set'],
            entryId: uri.queryParameters['entry'],
          );
        }
        return const ScoresRoute();

      case 'sets':
        if (segments.length >= 2) {
          return SetDetailRoute(setId: segments[1]);
        }
        return const SetsRoute();

      case 'profile':
        return const ProfileRoute();

      case 'settings':
        return const SettingsRoute();
    }

    return const ScoresRoute();
  }

  /// A new score, which has no id until it is uploaded.
  static String newScore() => '/scores/new';

  static String score(String scoreId, {String? setId, String? entryId}) {
    final query = <String, String>{
      if (setId != null) 'set': setId,
      if (entryId != null) 'entry': entryId,
    };
    final path = '/scores/$scoreId';
    return query.isEmpty
        ? path
        : Uri(path: path, queryParameters: query).toString();
  }

  static String set(String setId) => '/sets/$setId';

  static String newSet() => '/sets/new';
}

class ScoresRoute extends AppRoute {
  const ScoresRoute();

  @override
  String get path => '/';
}

class ScoreDetailRoute extends AppRoute {
  const ScoreDetailRoute({required this.scoreId, this.setId, this.entryId});

  /// `new` for a score that is about to be uploaded and has no id yet.
  final String scoreId;

  /// The set this score is being played from, when it is being played from one.
  final String? setId;

  /// Which of that set's entries this is.
  ///
  /// An entry is pointed at by its id rather than by where it comes in the set.
  /// An id is the client's to name and stays that entry's for as long as the
  /// entry is in the set, while the place it is played at moves under it every
  /// time somebody reorders the gig — and a link that has been sitting in a
  /// browser since before that would then open the right score and read it out
  /// of the wrong entry.
  final String? entryId;

  @override
  String get path => AppRoute.score(scoreId, setId: setId, entryId: entryId);
}

class SetsRoute extends AppRoute {
  const SetsRoute();

  @override
  String get path => '/sets';
}

class SetDetailRoute extends AppRoute {
  const SetDetailRoute({required this.setId});

  /// `new` for a set that has not been saved yet.
  final String setId;

  @override
  String get path => AppRoute.set(setId);
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
