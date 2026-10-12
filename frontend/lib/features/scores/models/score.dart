import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models/creators.dart';
import 'package:score/features/scores/models/movement.dart';
import 'package:score/features/scores/models/work.dart';
import 'package:score/features/scores/search.dart';
import 'package:score/features/sync/models.dart';
import 'package:score/json_map_extensions.dart';
import 'package:score/storage/clients.dart';

class const Score({
  @override required final String id,
  @override required final DateTime lastChangedAt,
  final Work? work,
  final Movement? movement,
  final Creators creators = const Creators(),
  final List<String> languages = const [],
  final List<String> instruments = const [],
  final List<String> tags = const [],
  final DateTime? lastFetchedFileAt,
  final DateTime? lastViewedAt,
}) implements SyncableModel {
  factory Score.fromJson(Map json) {
    return Score(
      id: json.get(idFieldKey) ?? (throw Exception('no id provided for score')),
      work: json.getObject('work', Work.fromJson),
      movement: json.getObject('movement', Movement.fromJson),
      creators:
          json.getObject('creators', Creators.fromJson) ?? const Creators(),
      languages: json.getList('languages'),
      instruments: json.getList('instruments'),
      lastChangedAt:
          json.get(Score.lastChangedAtFieldKey, parser: DateTime.tryParse) ??
          Score.defaultLastChangedAt,
      tags: json.getList('tags'),
      lastFetchedFileAt: json.get(
        'last_fetched_file_at',
        parser: DateTime.tryParse,
      ),
      lastViewedAt: json.get('last_viewed_at', parser: DateTime.tryParse),
    );
  }

  static const String lastChangedAtFieldKey = 'last_changed_at';
  static const String idFieldKey = 'id';

  static final DateTime defaultLastChangedAt = beginningOfTime;

  String get title {
    final named = (work?.title ?? '').trim().isNotEmpty
        ? work!.title!
        : (movement?.title ?? '');
    return named.trim().isEmpty ? 'Untitled score' : named.trim();
  }

  List<String> get creatorNames => [
    ...creators.composers,
    ...creators.lyricists,
  ];

  String get searchText => _searchTexts[this] ??= [
    title,
    ...creatorNames,
    ...tags,
    ...instruments,
    ...instruments.map(instrumentName),
  ].map(forSearch).join(' ');

  static final _searchTexts = Expando<String>('Score.searchText');

  bool matches(String query) => matchesWords(searchWords(query));

  bool matchesWords(List<String> words) {
    final text = searchText;
    return words.every(text.contains);
  }

  Score copyLocalOnlyFields(Score existing) => copyWith(
    lastFetchedFileAt: existing.lastFetchedFileAt,
    lastViewedAt: existing.lastViewedAt,
  );

  Score copyWith({
    DateTime? lastFetchedFileAt,
    DateTime? lastViewedAt,
  }) => Score(
    id: id,
    work: work,
    movement: movement,
    creators: creators,
    languages: languages,
    instruments: instruments,
    lastChangedAt: lastChangedAt,
    tags: tags,
    lastFetchedFileAt: lastFetchedFileAt ?? this.lastFetchedFileAt,
    lastViewedAt: lastViewedAt ?? this.lastViewedAt,
  );

  Map<String, Object?> toJson() => {
    Score.idFieldKey: id,
    'work': work?.toJson(),
    'movement': movement?.toJson(),
    'creators': creators.toJson(),
    'languages': languages,
    'instruments': instruments,
    // In UTC: a local moment written without an offset is read back in
    // whatever zone the device is in by then.
    Score.lastChangedAtFieldKey: lastChangedAt.toUtc().toIso8601String(),
    'tags': tags,
    'last_fetched_file_at': lastFetchedFileAt?.toUtc().toIso8601String(),
    'last_viewed_at': lastViewedAt?.toUtc().toIso8601String(),
  };
}
