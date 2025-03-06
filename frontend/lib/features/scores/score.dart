class Score {
  const Score({
    required this.id,
    required this.work,
    required this.movement,
    required this.creators,
    required this.instruments,
    required this.languages,
    required this.tags,
    required this.lastChangeTimestamp,
    required this.isFavourite,
  });

  final String id;
  final Work? work;
  final Movement? movement;
  final Creators creators;
  final List<String> instruments;
  final List<String> languages;
  final List<String> tags;
  final DateTime lastChangeTimestamp;
  final bool isFavourite;
}

class Work {
  const Work({
    required this.title,
    required this.number,
  });

  final String title;
  final String number;
}

class Movement {
  const Movement({
    required this.title,
    required this.number,
  });

  final String title;
  final String number;
}

class Creators {
  const Creators({
    required this.composers,
    required this.lyricists,
  });

  final List<String> composers;
  final List<String> lyricists;
}
