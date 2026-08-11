/// What this app knows about a score.
///
/// A score is a document somebody uploaded and a handful of facts read out of
/// it. The facts are what a list is drawn from and what a search looks through;
/// the document is fetched separately, because it is a thousand times the size
/// and is only wanted when the score is actually opened.

library;

class Score {
  const Score({
    required this.id,
    this.work,
    this.movement,
    this.creators = const Creators(),
    this.languages = const [],
    this.instruments = const [],
    this.lastChangedAt,
    this.tags = const [],
    this.lastSyncedAt,
    this.lastFetchedFileAt,
    this.lastViewedAt,
  });

  final String id;
  final Work? work;
  final Movement? movement;
  final Creators creators;
  final List<String> languages;
  final List<String> instruments;

  /// When it last changed on the server.
  final DateTime? lastChangedAt;

  final List<String> tags;

  /// When the server last said anything about it, which is where the next sync
  /// window starts.
  final DateTime? lastSyncedAt;

  /// When the document itself was last fetched, which is how the app knows a
  /// score it is holding has been uploaded again since.
  final DateTime? lastFetchedFileAt;

  /// When it was last opened on this device, which is what the list is sorted
  /// by: what was played last is what is likely to be played next.
  final DateTime? lastViewedAt;

  /// What to call it.
  ///
  /// A score is titled by the work it is part of, and by the movement when the
  /// work has no title of its own — a document that only ever names one of the
  /// two is common enough to be worth being ready for.
  String get title {
    final named = (work?.title ?? '').trim().isNotEmpty
        ? work!.title!
        : (movement?.title ?? '');
    return named.trim().isEmpty ? 'Untitled score' : named.trim();
  }

  List<String> get creatorNames => [...creators.composers, ...creators.lyricists];

  /// Everything about it worth typing into a filter.
  String get searchText =>
      [title, ...creatorNames, ...tags, ...instruments].join(' ').toLowerCase();

  Score copyWith({
    DateTime? lastSyncedAt,
    DateTime? lastFetchedFileAt,
    DateTime? lastViewedAt,
  }) =>
      Score(
        id: id,
        work: work,
        movement: movement,
        creators: creators,
        languages: languages,
        instruments: instruments,
        lastChangedAt: lastChangedAt,
        tags: tags,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastFetchedFileAt: lastFetchedFileAt ?? this.lastFetchedFileAt,
        lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      );

  /// A score the way the API hands it over, as one this app keeps: the moments
  /// as dates rather than as the strings they arrive as, and whatever is only
  /// known locally carried over from the score being replaced.
  factory Score.fromApi(Map<String, dynamic> json, {Score? existing}) => Score(
        id: '${json['id']}',
        work: Work.fromJson(json['work']),
        movement: Movement.fromJson(json['movement']),
        creators: Creators.fromJson(json['creators']),
        languages: _strings(json['languages']),
        instruments: _strings(json['instruments']),
        lastChangedAt: _date(json['last_changed_at']),
        tags: _strings(json['tags']),
        lastSyncedAt: DateTime.now(),
        lastFetchedFileAt: existing?.lastFetchedFileAt,
        lastViewedAt: existing?.lastViewedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'work': work?.toJson(),
        'movement': movement?.toJson(),
        'creators': creators.toJson(),
        'languages': languages,
        'instruments': instruments,
        'last_changed_at': lastChangedAt?.toIso8601String(),
        'tags': tags,
        'last_synced_at': lastSyncedAt?.toIso8601String(),
        'last_fetched_file_at': lastFetchedFileAt?.toIso8601String(),
        'last_viewed_at': lastViewedAt?.toIso8601String(),
      };

  factory Score.fromJson(Map<String, Object?> json) => Score(
        id: '${json['id']}',
        work: Work.fromJson(json['work']),
        movement: Movement.fromJson(json['movement']),
        creators: Creators.fromJson(json['creators']),
        languages: _strings(json['languages']),
        instruments: _strings(json['instruments']),
        lastChangedAt: _date(json['last_changed_at']),
        tags: _strings(json['tags']),
        lastSyncedAt: _date(json['last_synced_at']),
        lastFetchedFileAt: _date(json['last_fetched_file_at']),
        lastViewedAt: _date(json['last_viewed_at']),
      );
}

class Work {
  const Work({this.title, this.number});

  final String? title;
  final String? number;

  static Work? fromJson(Object? json) {
    if (json is! Map) return null;
    return Work(
      title: json['title'] as String?,
      number: json['number']?.toString(),
    );
  }

  Map<String, Object?> toJson() => {'title': title, 'number': number};
}

class Movement {
  const Movement({this.title, this.number});

  final String? title;
  final String? number;

  static Movement? fromJson(Object? json) {
    if (json is! Map) return null;
    return Movement(
      title: json['title'] as String?,
      number: json['number']?.toString(),
    );
  }

  Map<String, Object?> toJson() => {'title': title, 'number': number};
}

class Creators {
  const Creators({this.composers = const [], this.lyricists = const []});

  final List<String> composers;
  final List<String> lyricists;

  static Creators fromJson(Object? json) {
    if (json is! Map) return const Creators();
    return Creators(
      composers: _strings(json['composers']),
      lyricists: _strings(json['lyricists']),
    );
  }

  Map<String, Object?> toJson() =>
      {'composers': composers, 'lyricists': lyricists};
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
