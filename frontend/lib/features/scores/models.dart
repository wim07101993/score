/// What this app knows about a score.
///
/// A score is a document somebody uploaded and a handful of facts read out of
/// it. The facts are what a list is drawn from and what a search looks through;
/// the document is fetched separately, because it is a thousand times the size
/// and is only wanted when the score is actually opened.
library;

import 'package:score/features/scores/instruments.dart';

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

  /// A score the way the API hands it over, as one this app keeps: the moments
  /// as dates rather than as the strings they arrive as, and whatever is only
  /// known locally carried over from the score being replaced.
  ///
  /// [syncedAt] is the watermark of the change window the score was listed in:
  /// the newest moment the server gave in it, on the server's clock. A
  /// score that was read by itself was not part of any window, so it moves
  /// no watermark and keeps whatever it had.
  factory Score.fromApi(
    Map<String, dynamic> json, {
    Score? existing,
    DateTime? syncedAt,
  }) => Score(
        id: '${json['id']}',
        work: Work.fromJson(json['work']),
        movement: Movement.fromJson(json['movement']),
        creators: Creators.fromJson(json['creators']),
        languages: _strings(json['languages']),
        instruments: _strings(json['instruments']),
        lastChangedAt: _date(json['last_changed_at']),
        tags: _strings(json['tags']),
        lastSyncedAt: syncedAt ?? existing?.lastSyncedAt,
        lastFetchedFileAt: existing?.lastFetchedFileAt,
        lastViewedAt: existing?.lastViewedAt,
      );

  factory Score.fromJson(
    Map<String, Object?> json,
  ) => Score(
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

  /// Which version of the document this device holds, as the moment the server
  /// said the score last changed when it was fetched — the server's clock, so
  /// that it can be compared with that moment later on. It is how the app
  /// knows a score it is holding has been uploaded again since.
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
  ///
  /// Instruments go in twice over: as the MusicXML code the document carries,
  /// and as the name the list shows for it. Somebody looking for a piano part
  /// types `piano`, not `keyboard.piano`, and the code is kept as well because
  /// it is what an instrument with no name of its own is shown as.
  String get searchText => [
        title,
        ...creatorNames,
        ...tags,
        ...instruments,
        ...instruments.map(instrumentName),
      ].map(forSearch).join(' ');

  /// Whether this is one of the scores being looked for.
  ///
  /// Every word has to be found, and each of them anywhere: `beethoven ferne`
  /// finds the piece whose composer is one and whose title is the other, which
  /// looking for the whole phrase in one field would not. Somebody searching a
  /// library types what they remember about a piece, and what they remember is
  /// rarely one field of it in the order it is written.
  bool matches(String query) {
    final text = searchText;
    return forSearch(query)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(text.contains);
  }

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
}

class Work {
  const Work({
    this.title,
    this.number,
  });

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
  const Movement({
    this.title,
    this.number,
  });

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
  const Creators({
    this.composers = const [],
    this.lyricists = const [],
  });

  factory Creators.fromJson(
    Object? json,
  ) {
    if (json is! Map) return const Creators();
    return Creators(
      composers: _strings(json['composers']),
      lyricists: _strings(json['lyricists']),
    );
  }

  final List<String> composers;
  final List<String> lyricists;

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

/// Text as a search compares it: in lower case and without its accents.
///
/// Somebody looking for Fauré's Après un rêve types what their keyboard makes
/// easy, and a search that only matches what the engraver typed is a search that
/// cannot find half the repertoire. It goes both ways — the query and the score
/// are put through this — so `apres` finds `Après` and `Après` finds a score
/// somebody uploaded as `Apres`.
///
/// Dart has no Unicode normalisation of its own, so the accented letters are
/// looked up instead: every Latin letter that decomposes into a plain one and
/// its marks, plus any mark that already arrives on its own. Letters that are
/// not an accented anything, such as ø, are left as they are: they are letters,
/// not decorated ones.
String forSearch(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    out.write(_unaccented[char] ?? char);
  }
  return out.toString();
}

// Lower case only: the text is lowered before it is looked up.
const _unaccented = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
  'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ā': 'a',
  'ă': 'a', 'ą': 'a', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c', 'ď': 'd',
  'ē': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e', 'ĝ': 'g', 'ğ': 'g',
  'ġ': 'g', 'ģ': 'g', 'ĥ': 'h', 'ĩ': 'i', 'ī': 'i', 'ĭ': 'i', 'į': 'i',
  'ĵ': 'j', 'ķ': 'k', 'ĺ': 'l', 'ļ': 'l', 'ľ': 'l', 'ń': 'n', 'ņ': 'n',
  'ň': 'n', 'ō': 'o', 'ŏ': 'o', 'ő': 'o', 'ŕ': 'r', 'ŗ': 'r', 'ř': 'r',
  'ś': 's', 'ŝ': 's', 'ş': 's', 'š': 's', 'ţ': 't', 'ť': 't', 'ũ': 'u',
  'ū': 'u', 'ŭ': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u', 'ŵ': 'w', 'ŷ': 'y',
  'ź': 'z', 'ż': 'z', 'ž': 'z', 'ơ': 'o', 'ư': 'u', 'ǎ': 'a', 'ǐ': 'i',
  'ǒ': 'o', 'ǔ': 'u', 'ǖ': 'u', 'ǘ': 'u', 'ǚ': 'u', 'ǜ': 'u', 'ǟ': 'a',
  'ǡ': 'a', 'ǧ': 'g', 'ǩ': 'k', 'ǫ': 'o', 'ǭ': 'o', 'ǰ': 'j', 'ǵ': 'g',
  'ǹ': 'n', 'ǻ': 'a', 'ȁ': 'a', 'ȃ': 'a', 'ȅ': 'e', 'ȇ': 'e', 'ȉ': 'i',
  'ȋ': 'i', 'ȍ': 'o', 'ȏ': 'o', 'ȑ': 'r', 'ȓ': 'r', 'ȕ': 'u', 'ȗ': 'u',
  'ș': 's', 'ț': 't', 'ȟ': 'h', 'ȧ': 'a', 'ȩ': 'e', 'ȫ': 'o', 'ȭ': 'o',
  'ȯ': 'o', 'ȱ': 'o', 'ȳ': 'y', 'ḁ': 'a', 'ḃ': 'b', 'ḅ': 'b', 'ḇ': 'b',
  'ḉ': 'c', 'ḋ': 'd', 'ḍ': 'd', 'ḏ': 'd', 'ḑ': 'd', 'ḓ': 'd', 'ḕ': 'e',
  'ḗ': 'e', 'ḙ': 'e', 'ḛ': 'e', 'ḝ': 'e', 'ḟ': 'f', 'ḡ': 'g', 'ḣ': 'h',
  'ḥ': 'h', 'ḧ': 'h', 'ḩ': 'h', 'ḫ': 'h', 'ḭ': 'i', 'ḯ': 'i', 'ḱ': 'k',
  'ḳ': 'k', 'ḵ': 'k', 'ḷ': 'l', 'ḹ': 'l', 'ḻ': 'l', 'ḽ': 'l', 'ḿ': 'm',
  'ṁ': 'm', 'ṃ': 'm', 'ṅ': 'n', 'ṇ': 'n', 'ṉ': 'n', 'ṋ': 'n', 'ṍ': 'o',
  'ṏ': 'o', 'ṑ': 'o', 'ṓ': 'o', 'ṕ': 'p', 'ṗ': 'p', 'ṙ': 'r', 'ṛ': 'r',
  'ṝ': 'r', 'ṟ': 'r', 'ṡ': 's', 'ṣ': 's', 'ṥ': 's', 'ṧ': 's', 'ṩ': 's',
  'ṫ': 't', 'ṭ': 't', 'ṯ': 't', 'ṱ': 't', 'ṳ': 'u', 'ṵ': 'u', 'ṷ': 'u',
  'ṹ': 'u', 'ṻ': 'u', 'ṽ': 'v', 'ṿ': 'v', 'ẁ': 'w', 'ẃ': 'w', 'ẅ': 'w',
  'ẇ': 'w', 'ẉ': 'w', 'ẋ': 'x', 'ẍ': 'x', 'ẏ': 'y', 'ẑ': 'z', 'ẓ': 'z',
  'ẕ': 'z', 'ẖ': 'h', 'ẗ': 't', 'ẘ': 'w', 'ẙ': 'y', 'ạ': 'a', 'ả': 'a',
  'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a', 'ắ': 'a', 'ằ': 'a',
  'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ế': 'e',
  'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e', 'ỉ': 'i', 'ị': 'i', 'ọ': 'o',
  'ỏ': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o', 'ớ': 'o',
  'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o', 'ụ': 'u', 'ủ': 'u', 'ứ': 'u',
  'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u', 'ỳ': 'y', 'ỵ': 'y', 'ỷ': 'y',
  'ỹ': 'y',
};
