import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/helpers/json_map_extensions.dart';

class const CollectionEntry({
  required final String id,
  required final String scoreId,
  final String description = '',
  final int transposition = 0,
  final ScoreViewSettings view = const ScoreViewSettings.defaultView(),
}) {
  factory CollectionEntry.fromJson(Map json) {
    return CollectionEntry(
      id:
          json.get('id') ??
          (throw Exception('no id provided for collection entry')),
      scoreId:
          scoreIdOf(json['score_id']) ??
          (throw Exception('no score provided for collection entry')),
      description: json.get<String>('description') ?? '',
      transposition: json.get('transposition', parser: int.tryParse) ?? 0,
      view:
          json.getObject('view', ScoreViewSettings.fromJson) ??
          const ScoreViewSettings.defaultView(),
    );
  }

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
  /// of its score.
  ///
  /// The title is in the score rather than in the entry, so it is asked for
  /// rather than kept: [titleOf] is handed the score's id and says what that
  /// score is called on this device, or null when it is not on it yet.
  String nameWith(String? Function(String scoreId) titleOf) =>
      titleOf(scoreId) ?? 'Not on this device yet';

  CollectionEntry copyWith({
    String? scoreId,
    String? description,
    int? transposition,
    ScoreViewSettings? view,
  }) => CollectionEntry(
    id: id,
    scoreId: scoreId ?? this.scoreId,
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
