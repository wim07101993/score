import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/json_map_extensions.dart';

class const CollectionEntry({
  required final String id,
  final String? scoreId,
  final String description = '',
  final int transposition = 0,
  final ScoreViewSettings view = const ScoreViewSettings.defaultView(),
}) {
  factory CollectionEntry.fromJson(Map json) {
    return CollectionEntry(
      id:
          json.get('id') ??
          (throw Exception('no id provided for collection entry')),
      scoreId: scoreIdOf(json['score_id']),
      description: json.get<String>('description') ?? '',
      transposition: json.get('transposition', parser: int.tryParse) ?? 0,
      view:
          json.getObject('view', ScoreViewSettings.fromJson) ??
          const ScoreViewSettings.defaultView(),
    );
  }

  bool get isOnPaper => scoreId == null;

  int get combinedTransposition => (transposition + view.transposition).clamp(
    ScoreViewSettings.minTransposition,
    ScoreViewSettings.maxTransposition,
  );

  static List<CollectionEntry> sortByTitle(
    Iterable<CollectionEntry> entries,
    String? Function(String scoreId) titleOf,
  ) {
    String keyOf(CollectionEntry entry) =>
        entry.nameWith(titleOf).toLowerCase();

    return [...entries]..sort((a, b) {
      final byName = keyOf(a).compareTo(keyOf(b));
      // Two pieces that are called the same are still two pieces, and which of
      // them comes first must not change every time the list is drawn.
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
  }

  /// Which piece it is, as somebody looking down the list reads it: the title
  /// of its score, and what is written next to it when there is no score to
  /// take a title from.
  ///
  /// The title is in the score rather than in the entry, so it is asked for
  /// rather than kept: [titleOf] is handed the score's id and says what that
  /// score is called on this device, or null when it is not on it yet.
  String nameWith(String? Function(String scoreId) titleOf) {
    final scoreId = this.scoreId;
    if (scoreId == null) {
      final written = description.trim();
      return written.isEmpty ? 'A piece, not scanned yet' : written;
    }
    return titleOf(scoreId) ?? 'Not on this device yet';
  }

  /// A copy with some of it said differently.
  ///
  /// Which piece it is is asked for by name rather than by whether it is filled
  /// in: `null` is a piece that is in the collection but not in here, and
  /// reading that as nothing said would put the score back on an entry somebody
  /// has just said has none. So taking the score away is [clearScoreId].
  CollectionEntry copyWith({
    String? scoreId,
    String? description,
    int? transposition,
    ScoreViewSettings? view,
    bool clearScoreId = false,
  }) => CollectionEntry(
    id: id,
    scoreId: clearScoreId ? null : (scoreId ?? this.scoreId),
    description: description ?? this.description,
    transposition: transposition ?? this.transposition,
    view: view ?? this.view,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'score_id': scoreId,
    'description': description,
    'transposition': transposition,
    'view': view.toJson(),
  };
}
